
#import "entry.h"

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>
#import <AVFoundation/AVFoundation.h>
#import <AdSupport/ASIdentifierManager.h>

#import "CaptainHook.h"
#import "defines.h"

#import "NetTool/UserInfoManager.h"
#import "NetTool/Config.h"
#import "Category/UIAlertView+Blocks.h"

/// 从 `gg.in` 响应 NSData 解析 `response.data` 为公告字符串（与 verify.macos `VerifyEntryFetchGgNoticeWithCompletion` 一致）
static NSString *VerifyEntryParseGgNoticeFromResponseData(NSData *responseObject) {
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
        return @"（后台暂无公告内容）";
    }
    return trimmed;
}

@interface VerifyEntry ()<UIAlertViewDelegate>
- (void)presentActivationInputAlertWithMessage:(NSString *)message;
@end

@implementation VerifyEntry

+ (instancetype)MySharedInstance
{
    static VerifyEntry *sharedSingleton;
    
    if (!sharedSingleton)
    {
        static dispatch_once_t oncePPM;
        dispatch_once(&oncePPM, ^
      {
          sharedSingleton = [[VerifyEntry alloc] init];
      });
    }
    
    return sharedSingleton;
}


- (NSString*)getIDFA
{
    ASIdentifierManager *as = [ASIdentifierManager sharedManager];
    return as.advertisingIdentifier.UUIDString;
}

- (void)showAlertMsg:(NSString *)show error:(BOOL)error
{
    DisPatchGetMainQueueBegin();
    
    NSString *title = @"";
    if (YES == error)
    {
        title = @"信息";
    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:show delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil];
    [alert show];
    
    DisPatchGetMainQueueEnd();
}

- (void)startProcessActivateProcess:(NSString *)code finish:(void (^)(NSDictionary *done))finish
{
    (void)finish;
    // 授权码验证：参数与 Swift BSPHPClient.loginIC 一致；BSphpSeSsL / date / mutualkey / appsafecode 由 NetTool（BSPHPClientObjC）注入
    NSMutableDictionary *param = [NSMutableDictionary dictionary];
    param[@"api"] = @"login.ic";
    param[@"icid"] = code;
    param[@"icpwd"] = @"";
    NSString *idfa = [self getIDFA];
    param[@"key"] = idfa;
    param[@"maxoror"] = idfa;
    [NetTool Post_AppendURL:BSPHP_HOST myparameters:param mysuccess:^(id responseObject)
    {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
        if (dict)
        {
            id respObj = dict[@"response"];
            NSDictionary *resp = [respObj isKindOfClass:[NSDictionary class]] ? respObj : nil;
            NSNumber *codeNum = resp[@"code"];
            NSInteger apiCode = codeNum ? [codeNum integerValue] : 0;
            NSString *dataString = resp[@"data"];
            if (![dataString isKindOfClass:[NSString class]]) dataString = @"";
            NSRange range = [dataString rangeOfString:@"|1081|"];
            BOOL okByCode = (apiCode == 1011 || apiCode == 9908 || apiCode == 1081);
            BOOL okByPipe = (range.location != NSNotFound);

            if (okByCode || okByPipe)
            {
                [[NSUserDefaults standardUserDefaults] setObject:code forKey:@"activationDeviceID"];
                [[NSUserDefaults standardUserDefaults] synchronize];

                UserInfoManager *manager =   [UserInfoManager shareUserInfoManager];
                NSArray *arr = [dataString componentsSeparatedByString:@"|"];
                if (arr.count >= 6)
                {
                    manager.state01 = arr[0];
                    manager.state1081 = arr[1];
                    manager.deviceID = arr[2];
                    manager.returnData = arr[3];
                    manager.expirationTime = arr[4];
                    manager.activationTime = arr[5];

                    DisPatchGetMainQueueBegin();
                    NSString *showMsg = [NSString stringWithFormat:@"过期时间: %@", arr[4]];
                    [UIAlertView showWithTitle:@"验证成功" message:showMsg cancelButtonTitle:@"确定" otherButtonTitles:nil tapBlock:nil];
                    DisPatchGetMainQueueEnd();
                }
                else if (okByCode && dataString.length > 0)
                {
                    DisPatchGetMainQueueBegin();
                    [UIAlertView showWithTitle:@"验证成功" message:dataString cancelButtonTitle:@"确定" otherButtonTitles:nil tapBlock:nil];
                    DisPatchGetMainQueueEnd();
                }
            }
            else
            {
                NSString *messageStr = resp[@"data"];
                if (![messageStr isKindOfClass:[NSString class]]) messageStr = @"验证失败";
                UserInfoManager *manager =   [UserInfoManager shareUserInfoManager];
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
    } myfailure:^(NSError *error)
    {
        [self processActivate];
    }];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *CONFIRM = @"激活";
    
    NSString *btnTitle = [alertView buttonTitleAtIndex:buttonIndex];
    if (YES == [btnTitle isEqualToString:CONFIRM])
    {
        UITextField *tf = [alertView textFieldAtIndex:0];
        if (nil == tf.text || 0 == tf.text.length)
        {
            [self processActivate];
            return ;
        }
        
        [self startProcessActivateProcess:tf.text finish:nil];
    }
    else
    {
        [self processActivate];
    }
}

- (void)presentActivationInputAlertWithMessage:(NSString *)message
{
    NSString *CONFIRM = @"激活";
    NSString *CANCEL = @"取消";
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"卡密激活" message:message delegate:self cancelButtonTitle:CANCEL otherButtonTitles:CONFIRM, nil];
    [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    UITextField *txtName = [alert textFieldAtIndex:0];
    txtName.placeholder = @"请输入授权码";
    [alert show];
}

- (void)processActivate
{
    NSMutableDictionary *param = [NSMutableDictionary dictionary];
    param[@"api"] = @"gg.in";
    __weak typeof(self) weakSelf = self;
    [NetTool Post_AppendURL:BSPHP_HOST myparameters:param mysuccess:^(id responseObject) {
        NSString *notice = VerifyEntryParseGgNoticeFromResponseData((NSData *)responseObject);
        NSString *full = [NSString stringWithFormat:@"【软件公告 · gg.in 接口获取】\n\n%@\n\n————————————————\n%@", notice, BSPHP_ACTIVATION_ALERT_FOOTER];
        DisPatchGetMainQueueBegin();
        [weakSelf presentActivationInputAlertWithMessage:full];
        DisPatchGetMainQueueEnd();
    } myfailure:^(NSError *error) {
        NSString *fallback = [NSString stringWithFormat:@"（公告 gg.in 获取失败：%@）", error.localizedDescription ?: @"未知错误"];
        NSString *full = [NSString stringWithFormat:@"%@\n\n————————————————\n%@", fallback, BSPHP_ACTIVATION_ALERT_FOOTER];
        DisPatchGetMainQueueBegin();
        [weakSelf presentActivationInputAlertWithMessage:full];
        DisPatchGetMainQueueEnd();
    }];
}
@end

__attribute__((constructor))__attribute__((optnone)) static void initialize()
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1f * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
   {
       if([[NSUserDefaults standardUserDefaults] objectForKey:@"activationDeviceID"] != nil)
       {
           NSMutableDictionary *param = [NSMutableDictionary dictionary];
           param[@"api"] = @"login.ic";
           param[@"icid"] = [[NSUserDefaults standardUserDefaults] objectForKey:@"activationDeviceID"];
           param[@"icpwd"] = @"";
           NSString *idfa2 = [[VerifyEntry MySharedInstance] getIDFA];
           param[@"key"] = idfa2;
           param[@"maxoror"] = idfa2;
           [NetTool Post_AppendURL:BSPHP_HOST myparameters:param mysuccess:^(id responseObject)
            {
                NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:responseObject
                                                                     options:NSJSONReadingMutableContainers
                                                                       error:nil];
                if (dict)
                {
                    id respObj2 = dict[@"response"];
                    NSDictionary *resp2 = [respObj2 isKindOfClass:[NSDictionary class]] ? respObj2 : nil;
                    NSNumber *codeNum2 = resp2[@"code"];
                    NSInteger apiCode2 = codeNum2 ? [codeNum2 integerValue] : 0;
                    NSString *dataString = resp2[@"data"];
                    if (![dataString isKindOfClass:[NSString class]]) dataString = @"";
                    NSRange range = [dataString rangeOfString:@"|1081|"];
                    BOOL okByCode2 = (apiCode2 == 1011 || apiCode2 == 9908 || apiCode2 == 1081);
                    BOOL okByPipe2 = (range.location != NSNotFound);

                    if (okByCode2 || okByPipe2)
                    {
                        UserInfoManager *manager =   [UserInfoManager shareUserInfoManager];
                        NSArray *arr = [dataString componentsSeparatedByString:@"|"];
                        if (arr.count >= 6)
                        {
                            manager.state01 = arr[0];
                            manager.state1081 = arr[1];
                            manager.deviceID = arr[2];
                            manager.returnData = arr[3];
                            manager.expirationTime = arr[4];
                            manager.activationTime = arr[5];

                        }
                    }
                    else
                    {
                        UserInfoManager *manager =   [UserInfoManager shareUserInfoManager];
                        manager.state01 = nil;
                        manager.state1081 = nil;
                        manager.deviceID = nil;
                        manager.returnData = nil;
                        manager.expirationTime = nil;
                        manager.activationTime = nil;

                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
                       {
                           [[VerifyEntry MySharedInstance] processActivate];
                       });
                    }
                }
                else
                {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
                   {
                       [[VerifyEntry MySharedInstance] processActivate];
                   });
                }
            } myfailure:^(NSError *error)
            {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
               {
                   [[VerifyEntry MySharedInstance] processActivate];
               });
            }];
       }
       else
       {
           dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
          {
              [[VerifyEntry MySharedInstance] processActivate];
          });
       }
   });
}
