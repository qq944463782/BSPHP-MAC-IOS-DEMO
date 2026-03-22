//
//  BSPHPCrypto.swift
//  bsphp_api_http
//
//  BSPHP 加密工具：MD5、AES-128-CBC、RSA PKCS#1
//  与 Python bsphp/http.py 协议兼容
//

import CryptoKit
import Foundation
import Security
import CommonCrypto

// MARK: - 错误类型

/// 加密/解密过程可能抛出的错误
enum BSPHPCryptoError: Error {
    case invalidBase64Key
    case rsaKeyCreateFailed
    case rsaOperationFailed
    case aesOperationFailed
    case invalidResponseFormat
    case utf8DecodeFailed
}

// MARK: - 加密工具

/// BSPHP 加解密工具类
/// - MD5：用于 appsafecode、AES 密钥派生
/// - AES-128-CBC：请求体加密，key 与 iv 相同（取前 16 字符）
/// - RSA PKCS#1：签名加密、响应解密
enum BSPHPCrypto {

    /// MD5 十六进制字符串（BSPHP 协议要求；使用 CryptoKit `Insecure.MD5` 避免 CommonCrypto 弃用告警）
    static func md5Hex(_ string: String) -> String {
        let digest = Insecure.MD5.hash(data: Data(string.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    /// AES-128-CBC 加密，返回 Base64
    static func aes128CBCEncryptBase64(plaintext: String, key16: String) throws -> String {
        let keyData = Data(key16.utf8)
        let ivData = keyData
        let input = Data(plaintext.utf8)
        let out = try aesCBC(input: input, key: keyData, iv: ivData, operation: CCOperation(kCCEncrypt))
        return out.base64EncodedString()
    }

    /// AES-128-CBC 解密 Base64 密文
    static func aes128CBCDecryptBase64ToString(ciphertextB64: String, key16: String) throws -> String {
        guard let ct = Data(base64Encoded: ciphertextB64) else { throw BSPHPCryptoError.invalidResponseFormat }
        let keyData = Data(key16.utf8)
        let ivData = keyData
        let out = try aesCBC(input: ct, key: keyData, iv: ivData, operation: CCOperation(kCCDecrypt))
        guard let s = String(data: out, encoding: .utf8) else { throw BSPHPCryptoError.utf8DecodeFailed }
        return s
    }

    private static func aesCBC(input: Data, key: Data, iv: Data, operation: CCOperation) throws -> Data {
        var outLength: size_t = 0
        let outCapacity = input.count + kCCBlockSizeAES128
        var out = Data(count: outCapacity)

        let status = out.withUnsafeMutableBytes { outPtr in
            input.withUnsafeBytes { inPtr in
                key.withUnsafeBytes { keyPtr in
                    iv.withUnsafeBytes { ivPtr in
                        CCCrypt(
                            operation,
                            CCAlgorithm(kCCAlgorithmAES),
                            CCOptions(kCCOptionPKCS7Padding),
                            keyPtr.baseAddress, kCCKeySizeAES128,
                            ivPtr.baseAddress,
                            inPtr.baseAddress, input.count,
                            outPtr.baseAddress, outCapacity,
                            &outLength
                        )
                    }
                }
            }
        }

        guard status == kCCSuccess else { throw BSPHPCryptoError.aesOperationFailed }
        return Data(out.prefix(Int(outLength)))
    }

    /// RSA 公钥加密（PKCS#1），返回 Base64
    static func rsaEncryptPKCS1Base64(message: String, publicKeyBase64DER: String) throws -> String {
        let key = try secKey(fromBase64DER: publicKeyBase64DER, isPublic: true)
        guard let data = message.data(using: .utf8) else { throw BSPHPCryptoError.utf8DecodeFailed }
        guard SecKeyIsAlgorithmSupported(key, .encrypt, .rsaEncryptionPKCS1) else { throw BSPHPCryptoError.rsaOperationFailed }
        var error: Unmanaged<CFError>?
        guard let encrypted = SecKeyCreateEncryptedData(key, .rsaEncryptionPKCS1, data as CFData, &error) as Data? else {
            throw error?.takeRetainedValue() ?? BSPHPCryptoError.rsaOperationFailed
        }
        return encrypted.base64EncodedString()
    }

    /// 缓存已解析的 SecKey，避免每次请求重复解析 PKCS#8/创建 SecKey
    private static let secKeyCache = NSLock()
    private static var cachedPrivateKey: (b64: String, key: SecKey)?
    private static var cachedPublicKey: (b64: String, key: SecKey)?

    /// RSA 私钥解密（PKCS#1）
    static func rsaDecryptPKCS1Base64(ciphertextB64: String, privateKeyBase64DER: String) throws -> String {
        let key = try secKey(fromBase64DER: privateKeyBase64DER, isPublic: false)
        guard let ct = Data(base64Encoded: ciphertextB64) else { throw BSPHPCryptoError.invalidResponseFormat }
        guard SecKeyIsAlgorithmSupported(key, .decrypt, .rsaEncryptionPKCS1) else { throw BSPHPCryptoError.rsaOperationFailed }
        var error: Unmanaged<CFError>?
        guard let decrypted = SecKeyCreateDecryptedData(key, .rsaEncryptionPKCS1, ct as CFData, &error) as Data? else {
            throw error?.takeRetainedValue() ?? BSPHPCryptoError.rsaOperationFailed
        }
        guard let s = String(data: decrypted, encoding: .utf8) else { throw BSPHPCryptoError.utf8DecodeFailed }
        return s
    }

    private static func secKey(fromBase64DER keyBase64: String, isPublic: Bool) throws -> SecKey {
        let b64 = keyBase64
            .replacingOccurrences(of: "-----BEGIN RSA PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----BEGIN PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "-----END RSA PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .trimmingCharacters(in: .whitespaces)

        secKeyCache.lock()
        defer { secKeyCache.unlock() }
        if isPublic, let cached = cachedPublicKey, cached.b64 == b64 { return cached.key }
        if !isPublic, let cached = cachedPrivateKey, cached.b64 == b64 { return cached.key }

        guard var keyData = Data(base64Encoded: b64) else { throw BSPHPCryptoError.invalidBase64Key }

        // 私钥：PKCS#8 格式需提取内部 PKCS#1，SecKeyCreateWithData 只接受 PKCS#1
        if !isPublic, let pkcs1 = extractPKCS1FromPKCS8(keyData) {
            keyData = pkcs1
        }

        let attrs: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: isPublic ? kSecAttrKeyClassPublic : kSecAttrKeyClassPrivate
        ]
        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateWithData(keyData as CFData, attrs as CFDictionary, &error) else {
            throw error?.takeRetainedValue() ?? BSPHPCryptoError.rsaKeyCreateFailed
        }
        if isPublic { cachedPublicKey = (b64, key) } else { cachedPrivateKey = (b64, key) }
        return key
    }

    /// 从 PKCS#8 提取 PKCS#1 RSAPrivateKey（OCTET STRING 内容）
    /// SecKeyCreateWithData 只接受 PKCS#1，PKCS#8 需先解包
    private static func extractPKCS1FromPKCS8(_ der: Data) -> Data? {
        var pos = der.startIndex
        func readByte() -> UInt8? {
            guard pos < der.endIndex else { return nil }
            defer { pos = der.index(after: pos) }
            return der[pos]
        }
        func readLength() -> Int? {
            guard let first = readByte() else { return nil }
            if first & 0x80 == 0 { return Int(first) }
            let n = Int(first & 0x7F)
            guard n > 0, n <= 4 else { return nil }
            var len = 0
            for _ in 0..<n {
                guard let b = readByte() else { return nil }
                len = (len << 8) | Int(b)
            }
            return len
        }
        func readTLV() -> (tag: UInt8, value: Data)? {
            guard let tag = readByte(), let len = readLength() else { return nil }
            guard der.distance(from: pos, to: der.endIndex) >= len else { return nil }
            let start = pos
            pos = der.index(pos, offsetBy: len)
            return (tag, der[start..<pos])
        }

        // PKCS#8: SEQUENCE { version INTEGER, algorithm SEQUENCE, privateKey OCTET STRING }
        guard let (seqTag, seqBytes) = readTLV(), seqTag == 0x30 else { return nil }
        pos = seqBytes.startIndex
        _ = readTLV() // version
        _ = readTLV() // algorithm
        guard let (octTag, octData) = readTLV(), octTag == 0x04 else { return nil }
        return octData
    }
}
