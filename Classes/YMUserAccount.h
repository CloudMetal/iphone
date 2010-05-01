//
//  YMUserAccount.h
//  Yammer
//
//  Created by Samuel Sutch on 4/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SQLitePersistentObject.h"

@class YMNetwork;

@interface YMUserAccount : SQLitePersistentObject
{
  NSNumber *activeNetworkPK;
  NSString *username, *password;
  NSString *wrapToken, *wrapSecret;
  NSNumber *loggedIn;
}

@property (copy) NSNumber *activeNetworkPK;
// for login
@property (copy) NSString *username, *password;
@property (copy) NSNumber *loggedIn;
// to get network/user lists from server
@property (copy) NSString *wrapSecret, *wrapToken;


@end
