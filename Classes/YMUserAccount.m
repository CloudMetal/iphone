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
            wrapToken, wrapSecret, loggedIn;

- (void) clearNetworks
{
  if (![[SQLiteInstanceManager sharedManager] 
        tableExists:@"y_m_network"]) return;
  
  NSString *q = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@=%i",
                 [YMNetwork tableName], [@"userAccountPK" stringAsSQLColumnName], self.pk];
  [[SQLiteInstanceManager sharedManager] executeUpdateSQL:q];
}

- (void) deleteObjectCascade:(BOOL)cascade
{
  [self clearNetworks];
  [super deleteObjectCascade:cascade];
}

@end
