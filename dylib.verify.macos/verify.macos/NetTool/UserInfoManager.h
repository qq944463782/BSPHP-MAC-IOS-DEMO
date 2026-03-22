//
//  UserInfoManager.h
//

#import <Foundation/Foundation.h>

@interface UserInfoManager : NSObject
+ (UserInfoManager *)shareUserInfoManager;
@property (nonatomic, strong) NSString *state01;
@property (nonatomic, strong) NSString *state1081;
@property (nonatomic, copy) NSString *deviceID;
@property (nonatomic, copy) NSString *returnData;
@property (nonatomic, copy) NSString *activationTime;
@property (nonatomic, copy) NSString *expirationTime;
@end
