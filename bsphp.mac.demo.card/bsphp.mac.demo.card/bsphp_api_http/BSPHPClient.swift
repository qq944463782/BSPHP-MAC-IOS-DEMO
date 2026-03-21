import Foundation
#if canImport(IOKit)
import IOKit
#endif

struct BSPHPClientConfig {
    let url: String
    let mutualKey: String
    let serverPrivateKey: String
    let clientPublicKey: String
}

typealias BSPHPResponse = [String: Any]

struct BSPHPAPIResult {
    let data: Any?
    let code: Int?

    var message: String {
        if let s = data as? String { return s }
        if let arr = data as? [Any] { return arr.map { "\($0)" }.joined(separator: "\n") }
        return ""
    }
}

final class BSPHPClient {
    private let config: BSPHPClientConfig
    private(set) var bsPhpSeSsL: String = ""
    private let session = URLSession.shared
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
    private let dateFormatterHash: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd#HH:mm:ss"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    static var machineCode: String {
        #if canImport(IOKit)
        if let uuid = hardwareUUID() { return uuid }
        #endif
        return fallbackMachineCode
    }

    #if canImport(IOKit)
    private static func hardwareUUID() -> String? {
        let service = IOServiceMatching("IOPlatformExpertDevice")
        let platformExpert = IOServiceGetMatchingService(kIOMainPortDefault, service)
        guard platformExpert != 0 else { return nil }
        defer { IOObjectRelease(platformExpert) }
        let uuid = IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformUUIDKey as CFString, kCFAllocatorDefault, 0)
        return uuid?.takeRetainedValue() as? String
    }
    #endif

    private static var fallbackMachineCode: String {
        let key = "com.bsphp.card.machineCode"
        if let cached = UserDefaults.standard.string(forKey: key), !cached.isEmpty { return cached }
        let uuid = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        UserDefaults.standard.set(uuid, forKey: key)
        return uuid
    }

    init(config: BSPHPClientConfig) {
        self.config = config
    }

    // MARK: - core

    func send(api: String, params: [String: String] = [:]) async throws -> BSPHPResponse? {
        let appsafecode = BSPHPCrypto.md5Hex(dateFormatter.string(from: Date()))
        var param: [String: String] = [
            "api": api,
            "BSphpSeSsL": bsPhpSeSsL,
            "date": dateFormatterHash.string(from: Date()),
            "md5": "",
            "mutualkey": config.mutualKey,
            "appsafecode": appsafecode
        ]
        param.merge(params) { _, new in new }

        let dataStr = param.map {
            "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)"
        }.joined(separator: "&")

        let aesKeyFull = BSPHPCrypto.md5Hex(config.serverPrivateKey + appsafecode)
        let aesKey = String(aesKeyFull.prefix(16))
        let encryptedB64 = try BSPHPCrypto.aes128CBCEncryptBase64(plaintext: dataStr, key16: aesKey)
        let sigMd5 = BSPHPCrypto.md5Hex(encryptedB64)
        let signatureContent = "0|AES-128-CBC|\(aesKey)|\(sigMd5)|json"
        let rsaB64 = try BSPHPCrypto.rsaEncryptPKCS1Base64(message: signatureContent, publicKeyBase64DER: config.clientPublicKey)
        let payload = "\(encryptedB64)|\(rsaB64)"

        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        let encoded = payload.addingPercentEncoding(withAllowedCharacters: allowed) ?? payload

        var request = URLRequest(url: URL(string: config.url)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "parameter=\(encoded)".data(using: .utf8)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200, !data.isEmpty else { return nil }
        guard let text = String(data: data, encoding: .utf8), !text.isEmpty else { return nil }

        let raw = text.removingPercentEncoding ?? text
        let parts = raw.split(separator: "|", omittingEmptySubsequences: false)
        guard parts.count >= 3 else { return nil }

        let respEncB64 = String(parts[1]).trimmingCharacters(in: .whitespaces)
        let respRsaB64 = String(parts[2]).trimmingCharacters(in: .whitespaces)
        let sigDecrypted = try BSPHPCrypto.rsaDecryptPKCS1Base64(ciphertextB64: respRsaB64, privateKeyBase64DER: config.serverPrivateKey)
        let sigParts = sigDecrypted.split(separator: "|")
        guard sigParts.count >= 4 else { return nil }
        let respAesKey = String(String(sigParts[2]).prefix(16))
        let decrypted = try BSPHPCrypto.aes128CBCDecryptBase64ToString(ciphertextB64: respEncB64, key16: respAesKey)

        guard let json = try? JSONSerialization.jsonObject(with: Data(decrypted.utf8)) as? [String: Any],
              let resp = json["response"] as? [String: Any] else { return nil }
        return resp
    }

    private func apiResult(api: String, params: [String: String] = [:]) async -> BSPHPAPIResult {
        guard let r = try? await send(api: api, params: params) else {
            return BSPHPAPIResult(data: nil, code: nil)
        }
        return BSPHPAPIResult(data: r["data"], code: r["code"] as? Int)
    }

    // MARK: - common .in

    func connect() async -> Bool {
        (await apiResult(api: "internet.in")).message == "1"
    }

    func getSeSsL() async -> Bool {
        let r = await apiResult(api: "BSphpSeSsL.in")
        guard let s = r.data as? String, !s.isEmpty else { return false }
        bsPhpSeSsL = s
        return true
    }

    func bootstrap() async -> Bool {
        guard await connect() else { return false }
        return await getSeSsL()
    }

    func getNotice() async -> BSPHPAPIResult { await apiResult(api: "gg.in") }
    func getVersion() async -> BSPHPAPIResult { await apiResult(api: "v.in") }
    func getServerDate() async -> BSPHPAPIResult { await apiResult(api: "date.in") }
    func getPresetURL() async -> BSPHPAPIResult { await apiResult(api: "url.in") }

    // MARK: - card .ic

    func loginIC(icid: String, key: String = "", maxoror: String = "") async -> BSPHPAPIResult {
        let machine = key.isEmpty ? Self.machineCode : key
        let maxv = maxoror.isEmpty ? machine : maxoror
        return await apiResult(api: "login.ic", params: [
            "icid": icid,
            "key": machine,
            "maxoror": maxv
        ])
    }

    func getDateIC() async -> BSPHPAPIResult {
        await apiResult(api: "getdate.ic")
    }
}
