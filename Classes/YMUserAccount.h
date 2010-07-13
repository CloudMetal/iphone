//
//  YMUserAccount.h
//  Yammer
//
//  Created by Samuel Sutch on 4/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SQLitePersistentObject.h"

#define WS_URL @"https://www.yammer.com"

@class YMNetwork;

@interface YMUserAccount : SQLitePersistentObject
{
  NSNumber *activeNetworkPK;
  NSString *username, *password;
  NSString *wrapToken, *wrapSecret;
  NSNumber *loggedIn;
  NSString *serviceUrl;
}

@property (copy) NSNumber *activeNetworkPK;
// for login
@property (copy) NSString *username, *password, *serviceUrl;
@property (copy) NSNumber *loggedIn;
// to get network/user lists from server
@property (copy) NSString *wrapSecret, *wrapToken;

- (void)clearNetworks;

@end
