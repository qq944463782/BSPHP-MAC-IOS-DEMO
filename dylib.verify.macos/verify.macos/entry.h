//
//  macOS 注入入口：与 dylib.verify.oc/entry.mm 流程一致，使用 AppKit 弹窗。
//

#import <Foundation/Foundation.h>

@interface VerifyEntry : NSObject

+ (instancetype)MySharedInstance;

/// 与 iOS 侧 `getIDFA` 同名；macOS 上为硬件 UUID 或持久化机器码（对齐 BSPHPClient.machineCode）。
- (NSString *)getIDFA;

- (void)startProcessActivateProcess:(NSString *)code finish:(void (^)(NSDictionary *done))finish;
- (void)showAlertMsg:(NSString *)show error:(BOOL)error;
- (void)processActivate;

@end
