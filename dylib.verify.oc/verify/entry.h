//
//  hook1.h
//  hook1
//
//  Created by WXDebugger on 16/8/13.
//
//

#import <UIKit/UIKit.h>
#import "AFNetworking.h"


#ifndef _Entry_h
#define _Entry_h

@interface VerifyEntry : NSObject

+ (instancetype)MySharedInstance;

- (NSString*)getIDFA;
- (void)startProcessActivateProcess:(NSString *)code finish:(void (^)(NSDictionary *done))finish;
- (void)showAlertMsg:(NSString *)show error:(BOOL)error;
- (void)processActivate;

@end

#endif /* WXDebugger_h */
