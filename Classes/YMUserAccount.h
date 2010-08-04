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
  NSString *cookie;
}

@property (nonatomic, readwrite, retain) NSNumber *activeNetworkPK;
// for login
@property (nonatomic, readwrite, retain) NSString *username, *password, *serviceUrl;
@property (nonatomic, readwrite, retain) NSNumber *loggedIn;
// to get network/user lists from server
@property (nonatomic, readwrite, retain) NSString *wrapSecret, *wrapToken, *cookie;

- (void)clearNetworks;

@end
