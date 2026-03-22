//
//  macOS 注入：constructor 拉起授权弹窗（NSAlert），协议与 dylib.verify.oc/entry.mm 一致。
//  注入宿主若启动极早，会等到 NSApplication 完成 launching 后再弹窗；无合适窗口时用 runModal。
//

#import "entry.h"
#import <AppKit/AppKit.h>
#import <IOKit/IOKitLib.h>

#import "Config.h"
#import "UserInfoManager.h"

/// 与 Swift `BSPHPClient.fallbackMachineCode` 使用同一 UserDefaults 键。
static NSString *const kBSPHPMachineCodeUserDefaultsKey = @"com.bsphp.machineCode";

/// 弹窗标题里固定带上，方便辨认来自本注入 dylib（可自行改成你的产品名）。
static NSString *VerifyEntryAlertTag(void) {
    return @"【我的验证dylib · verify.macos】";
}

/// 请求 `gg.in` 取后台公告（与 Swift `getNotice()` / README 一致），在主线程以外的回调返回。
static void VerifyEntryFetchGgNoticeWithCompletion(void (^completion)(NSString *notice)) {
    NSMutableDictionary *param = [NSMutableDictionary dictionary];
    param[@"api"] = @"gg.in";
    [NetTool Post_AppendURL:BSPHP_HOST myparameters:param mysuccess:^(id responseObject) {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
        NSString *notice = @"";
        if (dict) {
            id respObj = dict[@"response"];
            NSDictionary *resp = [respObj isKindOfClass:[NSDictionary class]] ? respObj : nil;
            id data = resp[@"data"];
            if ([data isKindOfClass:[NSString class]]) {
                notice = (NSString *)data;
            } else if (data != nil && data != [NSNull null]) {
                notice = [NSString stringWithFormat:@"%@", data];
            }
        }
        NSString *trimmed = [notice stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (trimmed.length == 0) {
            notice = @"（后台暂无公告内容）";
        } else {
            notice = trimmed;
        }
        if (completion) {
            completion(notice);
        }
    } myfailure:^(NSError *error) {
        NSString *fallback = [NSString stringWithFormat:@"（公告 gg.in 获取失败：%@）", error.localizedDescription ?: @"未知错误"];
        if (completion) {
            completion(fallback);
        }
    }];
}

static void VerifyEntryLog(NSString *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    NSString *msg = [[NSString alloc] initWithFormat:fmt arguments:ap];
    va_end(ap);
    NSLog(@"[verify.macos] %@", msg);
}

static void VerifyEntryRunOnMain(dispatch_block_t block) {
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

/// 确保存在 NSApplication（必须在主线程调用）。
static void VerifyEntryActivateApp(void) {
    NSApplication *app = [NSApplication sharedApplication];
    (void)app;
    if ([NSApp respondsToSelector:@selector(activateIgnoringOtherApps:)]) {
        [NSApp activateIgnoringOtherApps:YES];
    }
}

/// 优先选一块可见的前台窗口，便于 sheet；没有则返回 nil（改用 runModal）。
static NSWindow *VerifyEntryBestParentWindow(void) {
    NSWindow *parent = [NSApp mainWindow] ?: [NSApp keyWindow];
    if (parent.isVisible) {
        return parent;
    }
    for (NSWindow *win in [NSApp windows]) {
        if (win.isVisible && !win.miniaturized) {
            return win;
        }
    }
    return nil;
}

static NSString *VerifyEntryHardwareUUID(void) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    io_service_t platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"));
#pragma clang diagnostic pop
    if (!platformExpert) {
        return nil;
    }
    CFTypeRef uuid = IORegistryEntryCreateCFProperty(platformExpert, CFSTR("IOPlatformUUID"), kCFAllocatorDefault, 0);
    IOObjectRelease(platformExpert);
    if (!uuid || CFGetTypeID(uuid) != CFStringGetTypeID()) {
        if (uuid) {
            CFRelease(uuid);
        }
        return nil;
    }
    return (__bridge_transfer NSString *)uuid;
}

static NSString *VerifyEntryFallbackMachineCode(void) {
    NSString *cached = [[NSUserDefaults standardUserDefaults] stringForKey:kBSPHPMachineCodeUserDefaultsKey];
    if (cached.length > 0) {
        return cached;
    }
    NSString *uuid = [[NSUUID UUID].UUIDString stringByReplacingOccurrencesOfString:@"-" withString:@""].lowercaseString;
    [[NSUserDefaults standardUserDefaults] setObject:uuid forKey:kBSPHPMachineCodeUserDefaultsKey];
    return uuid;
}

@implementation VerifyEntry

+ (instancetype)MySharedInstance {
    static VerifyEntry *sharedSingleton;
    static dispatch_once_t oncePPM;
    dispatch_once(&oncePPM, ^{
        sharedSingleton = [[VerifyEntry alloc] init];
    });
    return sharedSingleton;
}

- (NSString *)getIDFA {
    NSString *hw = VerifyEntryHardwareUUID();
    if (hw.length > 0) {
        return hw;
    }
    return VerifyEntryFallbackMachineCode();
}

- (void)showAlertMsg:(NSString *)show error:(BOOL)error {
    VerifyEntryRunOnMain(^{
        VerifyEntryActivateApp();
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = error ? [NSString stringWithFormat:@"%@ 信息", VerifyEntryAlertTag()] : VerifyEntryAlertTag();
        alert.informativeText = show ?: @"";
        [alert addButtonWithTitle:@"好"];
        NSWindow *parent = VerifyEntryBestParentWindow();
        if (parent) {
            [alert beginSheetModalForWindow:parent completionHandler:^(NSModalResponse returnCode) {
                (void)returnCode;
            }];
        } else {
            [alert runModal];
        }
    });
}

- (void)startProcessActivateProcess:(NSString *)code finish:(void (^)(NSDictionary *done))finish {
    (void)finish;
    NSMutableDictionary *param = [NSMutableDictionary dictionary];
    param[@"api"] = @"login.ic";
    param[@"icid"] = code;
    param[@"icpwd"] = @"";
    NSString *machine = [self getIDFA];
    param[@"key"] = machine;
    param[@"maxoror"] = machine;
    [NetTool Post_AppendURL:BSPHP_HOST myparameters:param mysuccess:^(id responseObject) {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
        if (dict) {
            id respObj = dict[@"response"];
            NSDictionary *resp = [respObj isKindOfClass:[NSDictionary class]] ? respObj : nil;
            NSNumber *codeNum = resp[@"code"];
            NSInteger apiCode = codeNum ? codeNum.integerValue : 0;
            NSString *dataString = resp[@"data"];
            if (![dataString isKindOfClass:[NSString class]]) {
                dataString = @"";
            }
            NSRange range = [dataString rangeOfString:@"|1081|"];
            BOOL okByCode = (apiCode == 1011 || apiCode == 9908 || apiCode == 1081);
            BOOL okByPipe = (range.location != NSNotFound);

            if (okByCode || okByPipe) {
                NSString *activationDID = [[NSUserDefaults standardUserDefaults] objectForKey:@"activationDeviceID"];
                if (![activationDID isEqualToString:code]) {
                    [[NSUserDefaults standardUserDefaults] setObject:code forKey:@"activationDeviceID"];
                }

                UserInfoManager *manager = [UserInfoManager shareUserInfoManager];
                NSArray *arr = [dataString componentsSeparatedByString:@"|"];
                if (arr.count >= 6) {
                    manager.state01 = arr[0];
                    manager.state1081 = arr[1];
                    manager.deviceID = arr[2];
                    manager.returnData = arr[3];
                    manager.expirationTime = arr[4];
                    manager.activationTime = arr[5];

                    VerifyEntryRunOnMain(^{
                        VerifyEntryActivateApp();
                        NSString *showMsg = [NSString stringWithFormat:@"过期时间: %@", arr[4]];
                        NSAlert *alert = [[NSAlert alloc] init];
                        alert.messageText = [NSString stringWithFormat:@"%@ 验证成功", VerifyEntryAlertTag()];
                        alert.informativeText = showMsg;
                        [alert addButtonWithTitle:@"确定"];
                        NSWindow *parent = VerifyEntryBestParentWindow();
                        if (parent) {
                            [alert beginSheetModalForWindow:parent completionHandler:^(NSModalResponse rc) { (void)rc; }];
                        } else {
                            [alert runModal];
                        }
                    });
                } else if (okByCode && dataString.length > 0) {
                    VerifyEntryRunOnMain(^{
                        VerifyEntryActivateApp();
                        NSAlert *alert = [[NSAlert alloc] init];
                        alert.messageText = [NSString stringWithFormat:@"%@ 验证成功", VerifyEntryAlertTag()];
                        alert.informativeText = dataString;
                        [alert addButtonWithTitle:@"确定"];
                        NSWindow *parent = VerifyEntryBestParentWindow();
                        if (parent) {
                            [alert beginSheetModalForWindow:parent completionHandler:^(NSModalResponse rc) { (void)rc; }];
                        } else {
                            [alert runModal];
                        }
                    });
                }
            } else {
                NSString *messageStr = resp[@"data"];
                if (![messageStr isKindOfClass:[NSString class]]) {
                    messageStr = @"验证失败";
                }
                UserInfoManager *manager = [UserInfoManager shareUserInfoManager];
                manager.state01 = nil;
                manager.state1081 = nil;
                manager.deviceID = nil;
                manager.returnData = nil;
                manager.expirationTime = nil;
                manager.activationTime = nil;
                [self showAlertMsg:messageStr error:YES];
                [self processActivate];
            }
        }
    } myfailure:^(NSError *error) {
        (void)error;
        [self processActivate];
    }];
}

- (void)processActivate {
    VerifyEntryLog(@"拉取 gg.in 公告后显示授权码输入框");
    VerifyEntryFetchGgNoticeWithCompletion(^(NSString *notice) {
        VerifyEntryRunOnMain(^{
            VerifyEntryActivateApp();
            VerifyEntryLog(@"显示授权码输入框（NSAlert），公告长度 %lu", (unsigned long)notice.length);

            NSAlert *alert = [[NSAlert alloc] init];
            alert.messageText = [NSString stringWithFormat:@"%@\n输入授权码", VerifyEntryAlertTag()];
            alert.informativeText = [NSString stringWithFormat:@"【软件公告 · gg.in】\n\n%@\n\n——————————————\n请在下方输入 BSPHP 卡密；本窗口由 verify.macos.dylib 弹出。", notice];
            NSTextField *tf = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 300, 24)];
            tf.placeholderString = @"请输入授权码";
            tf.stringValue = @"";
            [tf setBezeled:YES];
            [tf setBezelStyle:NSTextFieldSquareBezel];
            alert.accessoryView = tf;
            [alert addButtonWithTitle:@"取消"];
            [alert addButtonWithTitle:@"激活"];

            void (^handle)(NSModalResponse) = ^(NSModalResponse r) {
                if (r == NSAlertSecondButtonReturn) {
                    NSString *t = tf.stringValue;
                    if (t.length == 0) {
                        [self processActivate];
                        return;
                    }
                    [self startProcessActivateProcess:t finish:nil];
                } else {
                    [self processActivate];
                }
            };

            NSWindow *parent = VerifyEntryBestParentWindow();
            if (parent) {
                [alert beginSheetModalForWindow:parent completionHandler:handle];
            } else {
                NSModalResponse r = [alert runModal];
                handle(r);
            }
        });
    });
}

@end

/// 在 NSApplication 已 finishLaunching 后执行一次（含静默校验网络分支）。
static void VerifyEntryRunBootstrapFlowOnce(void) {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        VerifyEntryLog(@"开始校验流程（主线程 App 已就绪）");
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"activationDeviceID"] != nil) {
            NSMutableDictionary *param = [NSMutableDictionary dictionary];
            param[@"api"] = @"login.ic";
            param[@"icid"] = [[NSUserDefaults standardUserDefaults] objectForKey:@"activationDeviceID"];
            param[@"icpwd"] = @"";
            NSString *idfa2 = [[VerifyEntry MySharedInstance] getIDFA];
            param[@"key"] = idfa2;
            param[@"maxoror"] = idfa2;
            [NetTool Post_AppendURL:BSPHP_HOST myparameters:param mysuccess:^(id responseObject) {
                NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
                if (dict) {
                    id respObj2 = dict[@"response"];
                    NSDictionary *resp2 = [respObj2 isKindOfClass:[NSDictionary class]] ? respObj2 : nil;
                    NSNumber *codeNum2 = resp2[@"code"];
                    NSInteger apiCode2 = codeNum2 ? codeNum2.integerValue : 0;
                    NSString *dataString = resp2[@"data"];
                    if (![dataString isKindOfClass:[NSString class]]) {
                        dataString = @"";
                    }
                    NSRange range = [dataString rangeOfString:@"|1081|"];
                    BOOL okByCode2 = (apiCode2 == 1011 || apiCode2 == 9908 || apiCode2 == 1081);
                    BOOL okByPipe2 = (range.location != NSNotFound);

                    if (okByCode2 || okByPipe2) {
                        UserInfoManager *manager = [UserInfoManager shareUserInfoManager];
                        NSArray *arr = [dataString componentsSeparatedByString:@"|"];
                        if (arr.count >= 6) {
                            manager.state01 = arr[0];
                            manager.state1081 = arr[1];
                            manager.deviceID = arr[2];
                            manager.returnData = arr[3];
                            manager.expirationTime = arr[4];
                            manager.activationTime = arr[5];
                        }
                        VerifyEntryLog(@"已保存卡密仍有效，静默通过（不弹窗）");
                    } else {
                        UserInfoManager *manager = [UserInfoManager shareUserInfoManager];
                        manager.state01 = nil;
                        manager.state1081 = nil;
                        manager.deviceID = nil;
                        manager.returnData = nil;
                        manager.expirationTime = nil;
                        manager.activationTime = nil;

                        dispatch_async(dispatch_get_main_queue(), ^{
                            [[VerifyEntry MySharedInstance] processActivate];
                        });
                    }
                }
            } myfailure:^(NSError *error) {
                (void)error;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[VerifyEntry MySharedInstance] processActivate];
                });
            }];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[VerifyEntry MySharedInstance] processActivate];
            });
        }
    });
}

/// 等 Cocoa 应用跑起来再执行 bootstrap，避免注入过早 NSAlert 无效。
static void VerifyEntryScheduleBootstrapWhenAppReady(void) {
    VerifyEntryRunOnMain(^{
        VerifyEntryActivateApp();
        VerifyEntryLog(@"NSApplication windows=%lu", (unsigned long)[NSApp windows].count);

        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            __block BOOL didScheduleFlow = NO;
            void (^scheduleFlowOnce)(void) = ^{
                if (didScheduleFlow) {
                    return;
                }
                didScheduleFlow = YES;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    VerifyEntryRunBootstrapFlowOnce();
                });
            };

            __block id obs = nil;
            obs = [[NSNotificationCenter defaultCenter] addObserverForName:NSApplicationDidFinishLaunchingNotification
                                                                    object:nil
                                                                     queue:[NSOperationQueue mainQueue]
                                                                usingBlock:^(NSNotification *note) {
                                                                    (void)note;
                                                                    if (obs) {
                                                                        [[NSNotificationCenter defaultCenter] removeObserver:obs];
                                                                        obs = nil;
                                                                    }
                                                                    VerifyEntryLog(@"收到 NSApplicationDidFinishLaunching");
                                                                    scheduleFlowOnce();
                                                                }];

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                VerifyEntryLog(@"1s 兜底：尝试启动校验/弹窗");
                scheduleFlowOnce();
            });

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(8.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (obs) {
                    [[NSNotificationCenter defaultCenter] removeObserver:obs];
                    obs = nil;
                    VerifyEntryLog(@"8s 兜底：仍未收到 DidFinishLaunching，仍尝试弹窗");
                }
                scheduleFlowOnce();
            });
        });
    });
}

__attribute__((constructor)) __attribute__((optnone)) static void verify_macos_initialize(void) {
    VerifyEntryLog(@"dylib 已加载，将排队等待 AppKit 启动后再弹窗");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        VerifyEntryScheduleBootstrapWhenAppReady();
    });
}
