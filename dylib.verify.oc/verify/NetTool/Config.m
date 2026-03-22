
#import "Config.h"
#import "BSPHPClientObjC.h"

@implementation NetTool

+ (NSURLSessionDataTask *)__attribute__((optnone))Post_AppendURL:(NSString *)appendURL
                                                    myparameters:(NSDictionary *)param
                                                       mysuccess:(void (^)(id responseObject))success
                                                       myfailure:(void (^)(NSError *error))failure
{
    (void)appendURL;
    NSMutableDictionary<NSString *, NSString *> *ps = [NSMutableDictionary dictionary];
    [param enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        (void)stop;
        if (![key isKindOfClass:[NSString class]]) return;
        ps[key] = [NSString stringWithFormat:@"%@", obj];
    }];

    [[BSPHPClientObjC sharedClient] sendWithUserParameters:ps completion:^(NSDictionary *jsonRoot, NSError *error) {
        if (error) {
            if (failure) failure(error);
            return;
        }
        NSError *je = nil;
        NSData *data = [NSJSONSerialization dataWithJSONObject:jsonRoot options:0 error:&je];
        if (!data) {
            if (failure) failure(je ?: [NSError errorWithDomain:@"NetTool" code:-1 userInfo:nil]);
            return;
        }
        if (success) success(data);
    }];
    return nil;
}

@end
