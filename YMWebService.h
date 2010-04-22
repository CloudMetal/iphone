//
//  YMWebService.h
//  Yammer
//
//  Created by Samuel Sutch on 4/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define WS_URL @"https://staging.yammer.com"
#define WS_MOUNTPOINT [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", WS_URL, @"/api/v1"]]
#define WS_APPKEY @"NGvHVrd3y3tIXDMTej7MsA"
#define WS_APPSECRET @"Lm3il4pIKiCe5Xe8RsQLYZOHK8QfsKJ8YSTDFEGUQ"

@class YMUserAccount;

@interface YMWebService : NSObject {
  NSURL *mountPoint;
  NSString *appKey;
  NSString *appSecret;
}

+ (id)sharedWebService;


@property (copy) NSURL *mountPoint;
@property (copy) NSString *appKey;
@property (copy) NSString *appSecret;

//- (id)saveSettingsFromUserAccount:(YMUserAccount *)acct;
- (DKDeferred *)loginUserAccount:(YMUserAccount *)acct;

@end
