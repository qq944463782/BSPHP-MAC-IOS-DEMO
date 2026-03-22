//
//  dylib_ios_card_initializer.m
//  dylib.ios.card
//
//  动态库加载时执行，调用 Swift 入口（与 verify/entry.mm 中 constructor 一致）。
//

#import <Foundation/Foundation.h>
#import "dylib_ios_card-Swift.h"

__attribute__((constructor)) static void dylib_ios_card_constructor(void) {
    [IOSCardVerifyEntry runConstructor];
}
