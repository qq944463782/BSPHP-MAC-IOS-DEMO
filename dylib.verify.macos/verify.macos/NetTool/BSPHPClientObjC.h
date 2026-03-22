//
//  BSPHPClientObjC.h
//  verify
//
//  与 bsphp.app.demo.card 中 BSPHPClient.swift 通信流程一致（bootstrap、AES+RSA、POST parameter=）。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const BSPHPClientObjCErrorDomain;

@interface BSPHPClientObjC : NSObject

+ (instancetype)sharedClient;

/// 当前会话 BSphpSeSsL（bootstrap / login.ic 成功后更新）
@property (atomic, copy, nullable) NSString *bsPhpSeSsL;

/// 已完成 internet.in + BSphpSeSsL.in
@property (atomic, assign) BOOL didBootstrap;

/// internet.in + BSphpSeSsL.in；失败时 didBootstrap 仍为 NO
- (void)bootstrapWithCompletion:(void (^)(NSError * _Nullable error))completion;

/// 加密 POST，解密后得到根 JSON（含 response）；行为对齐 Swift `send(api:params:)`
- (void)sendWithUserParameters:(NSDictionary<NSString *, NSString *> *)parameters
                    completion:(void (^)(NSDictionary * _Nullable jsonRoot, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
