//
//  BSPHPCryptoObjC.h
//  verify
//
//  与 bsphp.app.demo.card 中 BSPHPCrypto.swift 协议一致：MD5 小写十六进制、AES-128-CBC、RSA PKCS#1。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const BSPHPCryptoObjCErrorDomain;

typedef NS_ENUM(NSInteger, BSPHPCryptoObjCErrorCode) {
    BSPHPCryptoObjCErrorInvalidBase64 = 1,
    BSPHPCryptoObjCErrorRSAKeyCreateFailed,
    BSPHPCryptoObjCErrorRSAOperationFailed,
    BSPHPCryptoObjCErrorAESOperationFailed,
    BSPHPCryptoObjCErrorInvalidResponseFormat,
    BSPHPCryptoObjCErrorUTF8DecodeFailed,
};

@interface BSPHPCryptoObjC : NSObject

+ (NSString *)md5HexLower:(NSString *)string;

+ (nullable NSString *)aes128CBCEncryptBase64WithPlaintext:(NSString *)plaintext
                                                    key16:(NSString *)key16
                                                    error:(NSError * _Nullable * _Nullable)error;

+ (nullable NSString *)aes128CBCDecryptBase64ToString:(NSString *)ciphertextB64
                                                key16:(NSString *)key16
                                                error:(NSError * _Nullable * _Nullable)error;

+ (nullable NSString *)rsaEncryptPKCS1Base64WithMessage:(NSString *)message
                                   publicKeyBase64DER:(NSString *)publicKeyBase64DER
                                                error:(NSError * _Nullable * _Nullable)error;

+ (nullable NSString *)rsaDecryptPKCS1Base64WithCiphertextB64:(NSString *)ciphertextB64
                                       privateKeyBase64DER:(NSString *)privateKeyBase64DER
                                                     error:(NSError * _Nullable * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
