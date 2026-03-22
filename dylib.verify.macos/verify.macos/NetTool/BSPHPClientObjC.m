//
//  BSPHPClientObjC.m
//  verify
//

#import "BSPHPClientObjC.h"
#import "BSPHPCryptoObjC.h"
#import "Config.h"

NSString * const BSPHPClientObjCErrorDomain = @"BSPHPClientObjC";

@interface BSPHPClientObjC ()
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSDateFormatter *dateFmtSpace;
@property (nonatomic, strong) NSDateFormatter *dateFmtHash;
@property (nonatomic, strong) dispatch_queue_t serialQueue;
@end

@implementation BSPHPClientObjC

+ (instancetype)sharedClient {
    static BSPHPClientObjC *s;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        s = [[BSPHPClientObjC alloc] init];
    });
    return s;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _session = [NSURLSession sharedSession];
        _serialQueue = dispatch_queue_create("com.bsphp.verify.client", DISPATCH_QUEUE_SERIAL);
        _dateFmtSpace = [[NSDateFormatter alloc] init];
        _dateFmtSpace.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        _dateFmtSpace.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        _dateFmtHash = [[NSDateFormatter alloc] init];
        _dateFmtHash.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        _dateFmtHash.dateFormat = @"yyyy-MM-dd#HH:mm:ss";
    }
    return self;
}

- (NSString *)joinRequestDataStringWithUserParams:(NSDictionary<NSString *, NSString *> *)user
                                    appsafecode:(NSString *)appsafecode
{
    NSMutableDictionary *p = [NSMutableDictionary dictionary];
    p[@"api"] = user[@"api"] ?: @"";
    p[@"BSphpSeSsL"] = self.bsPhpSeSsL ?: @"";
    p[@"date"] = [self.dateFmtHash stringFromDate:[NSDate date]];
    p[@"md5"] = @"";
    p[@"mutualkey"] = BSPHP_MUTUALKEY;
    p[@"appsafecode"] = appsafecode;
    [p addEntriesFromDictionary:user];

    NSArray *baseOrder = @[@"api", @"BSphpSeSsL", @"date", @"md5", @"mutualkey", @"appsafecode"];
    NSMutableOrderedSet *ordered = [NSMutableOrderedSet orderedSetWithArray:baseOrder];
    for (NSString *k in p.allKeys) {
        if (![ordered containsObject:k]) [ordered addObject:k];
    }

    NSCharacterSet *q = [NSCharacterSet URLQueryAllowedCharacterSet];
    NSMutableString *dataStr = [NSMutableString string];
    BOOL first = YES;
    for (NSString *k in ordered) {
        NSString *v = p[k] ?: @"";
        NSString *ev = [v stringByAddingPercentEncodingWithAllowedCharacters:q] ?: v;
        if (!first) [dataStr appendString:@"&"];
        first = NO;
        [dataStr appendFormat:@"%@=%@", k, ev];
    }
    return dataStr;
}

- (nullable NSDictionary *)decryptResponseBody:(NSString *)raw
                                 appsafecode:(NSString *)appsafecode
                                       error:(NSError **)outError
{
    NSString *body = [raw stringByRemovingPercentEncoding];
    if (!body) body = raw;
    NSArray *parts = [body componentsSeparatedByString:@"|"];
    if (parts.count < 3) {
        if (outError) *outError = [NSError errorWithDomain:BSPHPClientObjCErrorDomain code:2 userInfo:@{NSLocalizedDescriptionKey: @"响应分段不足"}];
        return nil;
    }
    NSString *respEncB64 = [parts[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *respRsaB64 = [parts[2] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    NSError *e = nil;
    NSString *sigDecrypted = [BSPHPCryptoObjC rsaDecryptPKCS1Base64WithCiphertextB64:respRsaB64 privateKeyBase64DER:BSPHP_SERVER_PRIVATE_KEY error:&e];
    if (!sigDecrypted) {
        if (outError) *outError = e;
        return nil;
    }
    NSArray *sigParts = [sigDecrypted componentsSeparatedByString:@"|"];
    if (sigParts.count < 4) {
        if (outError) *outError = [NSError errorWithDomain:BSPHPClientObjCErrorDomain code:3 userInfo:nil];
        return nil;
    }
    NSString *respAesKeyFull = sigParts[2];
    NSString *respAesKey = respAesKeyFull.length >= 16 ? [respAesKeyFull substringToIndex:16] : respAesKeyFull;

    NSString *decrypted = [BSPHPCryptoObjC aes128CBCDecryptBase64ToString:respEncB64 key16:respAesKey error:&e];
    if (!decrypted) {
        if (outError) *outError = e;
        return nil;
    }

    NSData *jdata = [decrypted dataUsingEncoding:NSUTF8StringEncoding];
    id obj = [NSJSONSerialization JSONObjectWithData:jdata options:0 error:&e];
    if (![obj isKindOfClass:[NSDictionary class]]) {
        if (outError) *outError = e ?: [NSError errorWithDomain:BSPHPClientObjCErrorDomain code:4 userInfo:nil];
        return nil;
    }
    NSDictionary *root = (NSDictionary *)obj;
    NSDictionary *resp = root[@"response"];
    if (![resp isKindOfClass:[NSDictionary class]]) {
        if (outError) *outError = [NSError errorWithDomain:BSPHPClientObjCErrorDomain code:5 userInfo:nil];
        return nil;
    }
    NSString *srvSafe = [resp[@"appsafecode"] isKindOfClass:[NSString class]] ? resp[@"appsafecode"] : nil;
    if (!srvSafe || ![srvSafe isEqualToString:appsafecode]) {
        NSMutableDictionary *mutResp = [resp mutableCopy];
        mutResp[@"data"] = @"appsafecode 安全参数验证不通过";
        NSMutableDictionary *mutRoot = [NSMutableDictionary dictionary];
        mutRoot[@"response"] = mutResp;
        return mutRoot;
    }
    return root;
}

- (void)applyLoginSessionIfNeeded:(NSDictionary *)userParams jsonRoot:(NSDictionary *)jsonRoot {
    NSString *api = userParams[@"api"];
    if (![api isEqualToString:@"login.ic"]) return;
    NSDictionary *resp = jsonRoot[@"response"];
    if (![resp isKindOfClass:[NSDictionary class]]) return;
    NSInteger c = [resp[@"code"] integerValue];
    if (c != 1011 && c != 9908 && c != 1081) return;
    NSString *ssl = resp[@"SeSsL"];
    if ([ssl isKindOfClass:[NSString class]] && ssl.length > 0) {
        self.bsPhpSeSsL = ssl;
    }
}

- (nullable NSDictionary *)performSynchronousSendWithUserParams:(NSDictionary<NSString *, NSString *> *)user error:(NSError **)outError {
    NSString *appsafecode = [BSPHPCryptoObjC md5HexLower:[self.dateFmtSpace stringFromDate:[NSDate date]]];
    NSString *dataStr = [self joinRequestDataStringWithUserParams:user appsafecode:appsafecode];

    NSString *timeMd5 = appsafecode;
    NSString *aesKeyFull = [BSPHPCryptoObjC md5HexLower:[BSPHP_SERVER_PRIVATE_KEY stringByAppendingString:timeMd5]];
    NSString *aesKey = aesKeyFull.length >= 16 ? [aesKeyFull substringToIndex:16] : aesKeyFull;

    NSError *e = nil;
    NSString *encryptedB64 = [BSPHPCryptoObjC aes128CBCEncryptBase64WithPlaintext:dataStr key16:aesKey error:&e];
    if (!encryptedB64) {
        if (outError) *outError = e;
        return nil;
    }
    NSString *sigMd5 = [BSPHPCryptoObjC md5HexLower:encryptedB64];
    NSString *signatureContent = [NSString stringWithFormat:@"0|AES-128-CBC|%@|%@|json", aesKey, sigMd5];
    NSString *rsaB64 = [BSPHPCryptoObjC rsaEncryptPKCS1Base64WithMessage:signatureContent publicKeyBase64DER:BSPHP_CLIENT_PUBLIC_KEY error:&e];
    if (!rsaB64) {
        if (outError) *outError = e;
        return nil;
    }

    NSString *payload = [NSString stringWithFormat:@"%@|%@", encryptedB64, rsaB64];
    NSMutableCharacterSet *allowed = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
    [allowed addCharactersInString:@"-._~"];
    NSString *encoded = [payload stringByAddingPercentEncodingWithAllowedCharacters:allowed] ?: payload;
    NSString *bodyStr = [NSString stringWithFormat:@"parameter=%@", encoded];
    NSData *body = [bodyStr dataUsingEncoding:NSUTF8StringEncoding];

    NSURL *u = [NSURL URLWithString:BSPHP_HOST];
    if (!u) {
        if (outError) *outError = [NSError errorWithDomain:BSPHPClientObjCErrorDomain code:6 userInfo:@{NSLocalizedDescriptionKey: @"BSPHP_HOST 无效"}];
        return nil;
    }
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:u];
    req.HTTPMethod = @"POST";
    [req setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    req.HTTPBody = body;

    __block NSData *respData = nil;
    __block NSURLResponse *respMeta = nil;
    __block NSError *taskErr = nil;
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        respData = data;
        respMeta = response;
        taskErr = error;
        dispatch_semaphore_signal(sem);
    }];
    [task resume];
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);

    if (taskErr) {
        if (outError) *outError = taskErr;
        return nil;
    }
    NSHTTPURLResponse *http = (NSHTTPURLResponse *)respMeta;
    if (![http isKindOfClass:[NSHTTPURLResponse class]] || http.statusCode != 200) {
        if (outError) *outError = [NSError errorWithDomain:BSPHPClientObjCErrorDomain code:7 userInfo:@{NSLocalizedDescriptionKey: @"HTTP 非 200"}];
        return nil;
    }
    if (respData.length == 0) {
        if (outError) *outError = [NSError errorWithDomain:BSPHPClientObjCErrorDomain code:8 userInfo:nil];
        return nil;
    }
    NSString *text = [[NSString alloc] initWithData:respData encoding:NSUTF8StringEncoding];
    if (text.length == 0) {
        if (outError) *outError = [NSError errorWithDomain:BSPHPClientObjCErrorDomain code:9 userInfo:nil];
        return nil;
    }

    NSDictionary *jsonRoot = [self decryptResponseBody:text appsafecode:appsafecode error:&e];
    if (!jsonRoot) {
        if (outError) *outError = e;
        return nil;
    }
    [self applyLoginSessionIfNeeded:user jsonRoot:jsonRoot];
    return jsonRoot;
}

- (void)bootstrapWithCompletion:(void (^)(NSError * _Nullable))completion {
    dispatch_async(self.serialQueue, ^{
        NSError *err = nil;
        NSDictionary *r1 = [self performSynchronousSendWithUserParams:@{@"api": @"internet.in"} error:&err];
        if (err) {
            dispatch_async(dispatch_get_main_queue(), ^{ completion(err); });
            return;
        }
        NSString *d1 = r1[@"response"][@"data"];
        if (![d1 isKindOfClass:[NSString class]] || ![d1 isEqualToString:@"1"]) {
            err = [NSError errorWithDomain:BSPHPClientObjCErrorDomain code:10 userInfo:@{NSLocalizedDescriptionKey: @"internet.in 未返回 1"}];
            dispatch_async(dispatch_get_main_queue(), ^{ completion(err); });
            return;
        }
        NSDictionary *r2 = [self performSynchronousSendWithUserParams:@{@"api": @"BSphpSeSsL.in"} error:&err];
        if (err) {
            dispatch_async(dispatch_get_main_queue(), ^{ completion(err); });
            return;
        }
        NSString *ssl = r2[@"response"][@"data"];
        if (![ssl isKindOfClass:[NSString class]] || ssl.length == 0) {
            err = [NSError errorWithDomain:BSPHPClientObjCErrorDomain code:11 userInfo:@{NSLocalizedDescriptionKey: @"BSphpSeSsL.in 无 data"}];
            dispatch_async(dispatch_get_main_queue(), ^{ completion(err); });
            return;
        }
        self.bsPhpSeSsL = ssl;
        self.didBootstrap = YES;
        dispatch_async(dispatch_get_main_queue(), ^{ completion(nil); });
    });
}

- (void)sendWithUserParameters:(NSDictionary<NSString *,NSString *> *)parameters
                    completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion
{
    dispatch_async(self.serialQueue, ^{
        NSError *err = nil;
        if (!self.didBootstrap) {
            NSDictionary *r1 = [self performSynchronousSendWithUserParams:@{@"api": @"internet.in"} error:&err];
            if (err) {
                dispatch_async(dispatch_get_main_queue(), ^{ completion(nil, err); });
                return;
            }
            NSString *d1 = r1[@"response"][@"data"];
            if (![d1 isKindOfClass:[NSString class]] || ![d1 isEqualToString:@"1"]) {
                err = [NSError errorWithDomain:BSPHPClientObjCErrorDomain code:10 userInfo:@{NSLocalizedDescriptionKey: @"internet.in 未返回 1"}];
                dispatch_async(dispatch_get_main_queue(), ^{ completion(nil, err); });
                return;
            }
            NSDictionary *r2 = [self performSynchronousSendWithUserParams:@{@"api": @"BSphpSeSsL.in"} error:&err];
            if (err) {
                dispatch_async(dispatch_get_main_queue(), ^{ completion(nil, err); });
                return;
            }
            NSString *ssl = r2[@"response"][@"data"];
            if (![ssl isKindOfClass:[NSString class]] || ssl.length == 0) {
                err = [NSError errorWithDomain:BSPHPClientObjCErrorDomain code:11 userInfo:nil];
                dispatch_async(dispatch_get_main_queue(), ^{ completion(nil, err); });
                return;
            }
            self.bsPhpSeSsL = ssl;
            self.didBootstrap = YES;
        }

        NSDictionary *root = [self performSynchronousSendWithUserParams:parameters error:&err];
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(root, err);
        });
    });
}

@end
