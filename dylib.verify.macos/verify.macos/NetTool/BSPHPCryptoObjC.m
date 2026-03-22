//
//  BSPHPCryptoObjC.m
//  verify
//

#import "BSPHPCryptoObjC.h"
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonDigest.h>
#import <Security/Security.h>

NSString * const BSPHPCryptoObjCErrorDomain = @"BSPHPCryptoObjC";

static NSData * _Nullable BSPHPCrypto_ExtractPKCS1FromPKCS8(NSData *der);

static SecKeyRef _Nullable BSPHPCrypto_CopySecKeyFromBase64DER(NSString *keyBase64, BOOL isPublic, NSError **outError) {
    static NSString *lastPubB64 = nil;
    static SecKeyRef lastPubKey = NULL;
    static NSString *lastPrivB64 = nil;
    static SecKeyRef lastPrivKey = NULL;
    static NSObject *lock = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        lock = [[NSObject alloc] init];
    });

    NSString *b64 = [[[[[[[keyBase64
        stringByReplacingOccurrencesOfString:@"-----BEGIN RSA PRIVATE KEY-----" withString:@""]
        stringByReplacingOccurrencesOfString:@"-----BEGIN PRIVATE KEY-----" withString:@""]
        stringByReplacingOccurrencesOfString:@"-----BEGIN PUBLIC KEY-----" withString:@""]
        stringByReplacingOccurrencesOfString:@"-----END RSA PRIVATE KEY-----" withString:@""]
        stringByReplacingOccurrencesOfString:@"-----END PRIVATE KEY-----" withString:@""]
        stringByReplacingOccurrencesOfString:@"-----END PUBLIC KEY-----" withString:@""]
        stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    b64 = [[b64 stringByReplacingOccurrencesOfString:@"\n" withString:@""] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    @synchronized (lock) {
        if (isPublic && lastPubB64 && lastPubKey && [lastPubB64 isEqualToString:b64]) {
            CFRetain(lastPubKey);
            return lastPubKey;
        }
        if (!isPublic && lastPrivB64 && lastPrivKey && [lastPrivB64 isEqualToString:b64]) {
            CFRetain(lastPrivKey);
            return lastPrivKey;
        }
    }

    NSData *keyData = [[NSData alloc] initWithBase64EncodedString:b64 options:0];
    if (!keyData) {
        if (outError) *outError = [NSError errorWithDomain:BSPHPCryptoObjCErrorDomain code:BSPHPCryptoObjCErrorInvalidBase64 userInfo:@{NSLocalizedDescriptionKey: @"Invalid Base64 key"}];
        return NULL;
    }

    if (!isPublic) {
        NSData *pkcs1 = BSPHPCrypto_ExtractPKCS1FromPKCS8(keyData);
        if (pkcs1) keyData = pkcs1;
    }

    NSDictionary *attrs = @{
        (__bridge NSString *)kSecAttrKeyType: (__bridge NSString *)kSecAttrKeyTypeRSA,
        (__bridge NSString *)kSecAttrKeyClass: isPublic ? (__bridge NSString *)kSecAttrKeyClassPublic : (__bridge NSString *)kSecAttrKeyClassPrivate
    };
    CFErrorRef cfErr = NULL;
    SecKeyRef key = SecKeyCreateWithData((__bridge CFDataRef)keyData, (__bridge CFDictionaryRef)attrs, &cfErr);
    if (!key) {
        if (outError) *outError = (__bridge_transfer NSError *)cfErr ?: [NSError errorWithDomain:BSPHPCryptoObjCErrorDomain code:BSPHPCryptoObjCErrorRSAKeyCreateFailed userInfo:nil];
        return NULL;
    }
    if (cfErr) CFRelease(cfErr);

    @synchronized (lock) {
        if (isPublic) {
            if (lastPubKey) CFRelease(lastPubKey);
            lastPubB64 = [b64 copy];
            lastPubKey = key;
            CFRetain(key);
        } else {
            if (lastPrivKey) CFRelease(lastPrivKey);
            lastPrivB64 = [b64 copy];
            lastPrivKey = key;
            CFRetain(key);
        }
    }
    return key;
}

static NSInteger BSPHPCrypto_ReadASN1Length(const uint8_t *buf, NSUInteger len, NSUInteger *ioPos) {
    NSUInteger pos = *ioPos;
    if (pos >= len) return -1;
    uint8_t first = buf[pos++];
    if (!(first & 0x80)) {
        *ioPos = pos;
        return first;
    }
    int n = first & 0x7F;
    if (n <= 0 || n > 4 || pos + (NSUInteger)n > len) return -1;
    NSInteger L = 0;
    for (int i = 0; i < n; i++) {
        L = (L << 8) | buf[pos++];
    }
    *ioPos = pos;
    return L;
}

static NSData * _Nullable BSPHPCrypto_ReadTLV(const uint8_t *buf, NSUInteger len, NSUInteger *ioPos, uint8_t expectTag) {
    NSUInteger pos = *ioPos;
    if (pos >= len) return nil;
    uint8_t tag = buf[pos++];
    if (tag != expectTag) return nil;
    NSInteger L = BSPHPCrypto_ReadASN1Length(buf, len, &pos);
    if (L < 0 || pos + (NSUInteger)L > len) return nil;
    NSData *v = [NSData dataWithBytes:buf + pos length:(NSUInteger)L];
    *ioPos = pos + (NSUInteger)L;
    return v;
}

static NSData * _Nullable BSPHPCrypto_ExtractPKCS1FromPKCS8(NSData *der) {
    NSUInteger pos = 0;
    const uint8_t *b = der.bytes;
    NSUInteger n = der.length;
    NSData *outer = BSPHPCrypto_ReadTLV(b, n, &pos, 0x30);
    if (!outer) return nil;
    pos = 0;
    b = outer.bytes;
    n = outer.length;
    if (!BSPHPCrypto_ReadTLV(b, n, &pos, 0x02)) return nil;
    if (!BSPHPCrypto_ReadTLV(b, n, &pos, 0x30)) return nil;
    NSData *oct = BSPHPCrypto_ReadTLV(b, n, &pos, 0x04);
    return oct;
}

@implementation BSPHPCryptoObjC

+ (NSString *)md5HexLower:(NSString *)string {
    const char *c = [string UTF8String];
    unsigned char d[CC_MD5_DIGEST_LENGTH];
    CC_MD5(c, (CC_LONG)strlen(c), d);
    NSMutableString *o = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [o appendFormat:@"%02x", d[i]];
    }
    return o;
}

+ (NSData *)aesCBCWithInput:(NSData *)input key:(NSData *)keyData iv:(NSData *)ivData encrypt:(BOOL)encrypt error:(NSError **)error {
    size_t outCapacity = input.length + kCCBlockSizeAES128;
    NSMutableData *outData = [NSMutableData dataWithLength:outCapacity];
    size_t outLength = 0;
    CCCryptorStatus st = CCCrypt(encrypt ? kCCEncrypt : kCCDecrypt,
                                 kCCAlgorithmAES,
                                 kCCOptionPKCS7Padding,
                                 keyData.bytes, kCCKeySizeAES128,
                                 ivData.bytes,
                                 input.bytes, input.length,
                                 outData.mutableBytes, outCapacity,
                                 &outLength);
    if (st != kCCSuccess) {
        if (error) *error = [NSError errorWithDomain:BSPHPCryptoObjCErrorDomain code:BSPHPCryptoObjCErrorAESOperationFailed userInfo:nil];
        return nil;
    }
    outData.length = outLength;
    return outData;
}

+ (NSString *)aes128CBCEncryptBase64WithPlaintext:(NSString *)plaintext key16:(NSString *)key16 error:(NSError **)error {
    NSData *keyData = [key16 dataUsingEncoding:NSUTF8StringEncoding];
    NSData *ivData = keyData;
    NSData *plain = [plaintext dataUsingEncoding:NSUTF8StringEncoding];
    if (keyData.length != kCCKeySizeAES128) {
        if (error) *error = [NSError errorWithDomain:BSPHPCryptoObjCErrorDomain code:BSPHPCryptoObjCErrorAESOperationFailed userInfo:@{NSLocalizedDescriptionKey: @"key16 must be 16 UTF-8 bytes"}];
        return nil;
    }
    NSData *enc = [self aesCBCWithInput:plain key:keyData iv:ivData encrypt:YES error:error];
    if (!enc) return nil;
    return [enc base64EncodedStringWithOptions:0];
}

+ (NSString *)aes128CBCDecryptBase64ToString:(NSString *)ciphertextB64 key16:(NSString *)key16 error:(NSError **)error {
    NSData *ct = [[NSData alloc] initWithBase64EncodedString:ciphertextB64 options:0];
    if (!ct) {
        if (error) *error = [NSError errorWithDomain:BSPHPCryptoObjCErrorDomain code:BSPHPCryptoObjCErrorInvalidResponseFormat userInfo:nil];
        return nil;
    }
    NSData *keyData = [key16 dataUsingEncoding:NSUTF8StringEncoding];
    NSData *ivData = keyData;
    if (keyData.length != kCCKeySizeAES128) {
        if (error) *error = [NSError errorWithDomain:BSPHPCryptoObjCErrorDomain code:BSPHPCryptoObjCErrorAESOperationFailed userInfo:nil];
        return nil;
    }
    NSData *dec = [self aesCBCWithInput:ct key:keyData iv:ivData encrypt:NO error:error];
    if (!dec) return nil;
    NSString *s = [[NSString alloc] initWithData:dec encoding:NSUTF8StringEncoding];
    if (!s) {
        if (error) *error = [NSError errorWithDomain:BSPHPCryptoObjCErrorDomain code:BSPHPCryptoObjCErrorUTF8DecodeFailed userInfo:nil];
        return nil;
    }
    return s;
}

+ (NSString *)rsaEncryptPKCS1Base64WithMessage:(NSString *)message publicKeyBase64DER:(NSString *)publicKeyBase64DER error:(NSError **)error {
    NSError *e = nil;
    SecKeyRef key = BSPHPCrypto_CopySecKeyFromBase64DER(publicKeyBase64DER, YES, &e);
    if (!key) {
        if (error) *error = e;
        return nil;
    }
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) {
        CFRelease(key);
        if (error) *error = [NSError errorWithDomain:BSPHPCryptoObjCErrorDomain code:BSPHPCryptoObjCErrorUTF8DecodeFailed userInfo:nil];
        return nil;
    }
    size_t block = SecKeyGetBlockSize(key);
    if (data.length + 11 > block) {
        CFRelease(key);
        if (error) *error = [NSError errorWithDomain:BSPHPCryptoObjCErrorDomain code:BSPHPCryptoObjCErrorRSAOperationFailed userInfo:@{NSLocalizedDescriptionKey: @"RSA 明文过长"}];
        return nil;
    }
    CFErrorRef cfErr = NULL;
    NSData *enc = CFBridgingRelease(SecKeyCreateEncryptedData(key, kSecKeyAlgorithmRSAEncryptionPKCS1, (__bridge CFDataRef)data, &cfErr));
    CFRelease(key);
    if (!enc) {
        if (error) *error = cfErr ? (__bridge_transfer NSError *)cfErr : [NSError errorWithDomain:BSPHPCryptoObjCErrorDomain code:BSPHPCryptoObjCErrorRSAOperationFailed userInfo:@{NSLocalizedDescriptionKey: @"RSA 加密失败"}];
        else if (cfErr) CFRelease(cfErr);
        return nil;
    }
    return [enc base64EncodedStringWithOptions:0];
}

+ (NSString *)rsaDecryptPKCS1Base64WithCiphertextB64:(NSString *)ciphertextB64 privateKeyBase64DER:(NSString *)privateKeyBase64DER error:(NSError **)error {
    NSError *e = nil;
    SecKeyRef key = BSPHPCrypto_CopySecKeyFromBase64DER(privateKeyBase64DER, NO, &e);
    if (!key) {
        if (error) *error = e;
        return nil;
    }
    NSData *ct = [[NSData alloc] initWithBase64EncodedString:ciphertextB64 options:0];
    if (!ct) {
        CFRelease(key);
        if (error) *error = [NSError errorWithDomain:BSPHPCryptoObjCErrorDomain code:BSPHPCryptoObjCErrorInvalidResponseFormat userInfo:nil];
        return nil;
    }
    CFErrorRef cfErr = NULL;
    NSData *dec = CFBridgingRelease(SecKeyCreateDecryptedData(key, kSecKeyAlgorithmRSAEncryptionPKCS1, (__bridge CFDataRef)ct, &cfErr));
    CFRelease(key);
    if (!dec) {
        if (error) *error = cfErr ? (__bridge_transfer NSError *)cfErr : [NSError errorWithDomain:BSPHPCryptoObjCErrorDomain code:BSPHPCryptoObjCErrorRSAOperationFailed userInfo:@{NSLocalizedDescriptionKey: @"RSA 解密失败"}];
        else if (cfErr) CFRelease(cfErr);
        return nil;
    }
    NSString *s = [[NSString alloc] initWithData:dec encoding:NSUTF8StringEncoding];
    if (!s) {
        if (error) *error = [NSError errorWithDomain:BSPHPCryptoObjCErrorDomain code:BSPHPCryptoObjCErrorUTF8DecodeFailed userInfo:nil];
        return nil;
    }
    return s;
}

@end
