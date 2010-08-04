//
//  YMUserAccount.m
//  Yammer
//
//  Created by Samuel Sutch on 4/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "YMUserAccount.h"
#import "YMNetwork.h"
#import "SQLiteInstanceManager.h"
#import "NSString-SQLiteColumnName.h"



@implementation YMUserAccount

@synthesize activeNetworkPK, username, password, 
            wrapToken, wrapSecret, loggedIn, serviceUrl, cookie;

- (id) init
{
  if ((self = [super init])) {
    self.serviceUrl = WS_URL; // default to WS_URL
  }
  return self;
}

- (void) clearNetworks
{
  if (![[SQLiteInstanceManager sharedManager] 
        tableExists:@"y_m_network"]) return;
  
  NSString *q = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@=%i",
                 [YMNetwork tableName], [@"userAccountPK" stringAsSQLColumnName], self.pk];
  [[SQLiteInstanceManager sharedManager] executeUpdateSQL:q];
}

- (NSString *)serviceUrl
{
  if (serviceUrl == nil || [serviceUrl isEqual:[NSNull null]]) {
    self.serviceUrl = WS_URL;
    [self save];
  }
  return serviceUrl;
}

- (void) deleteObjectCascade:(BOOL)cascade
{
  [self clearNetworks];
  [super deleteObjectCascade:cascade];
}

- (void)dealloc
{
  self.cookie = nil;
  self.activeNetworkPK = nil;
  self.username = nil;
  self.password = nil;
  self.wrapToken = nil;
  self.wrapSecret = nil;
  self.loggedIn = nil;
  self.serviceUrl = nil;
  [super dealloc];
}

@end
