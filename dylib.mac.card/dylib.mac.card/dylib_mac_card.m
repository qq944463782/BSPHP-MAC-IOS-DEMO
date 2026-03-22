//
//  dylib_mac_card.m
//  dylib.mac.card
//
//  constructor：排队等待 AppKit 就绪后走 Swift `MacCardVerifyEntry`（与 verify.macos 一致）。
//

#import "dylib_mac_card.h"
#import "dylib_mac_card-Swift.h"

@implementation dylib_mac_card

@end

__attribute__((constructor)) __attribute__((optnone)) static void dylib_mac_card_initialize(void) {
    NSLog(@"[dylib.mac.card] dylib 已加载，将排队等待 AppKit 启动后再弹窗");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[MacCardVerifyEntry shared] scheduleBootstrapWhenAppReady];
    });
}
