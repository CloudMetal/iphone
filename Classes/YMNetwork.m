//
//  YMNetwork.m
//  Yammer
//
//  Created by Samuel Sutch on 4/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "YMNetwork.h"


@implementation YMNetwork

@synthesize token, secret, userAccountPK, networkID, lastScrapedLocalContacts, 
            permalink, url, unseenMessageCount, name, userID,
            groupSubscriptionIds, tagSubscriptionIds, userSubscriptionIds, community;

DECLARE_PROPERTIES(
                   DECLARE_PROPERTY(@"token", @"@\"NSString\""),
                   DECLARE_PROPERTY(@"secret", @"@\"NSString\""),
                   DECLARE_PROPERTY(@"userAccountPK", @"@\"NSNumber\""),
                   DECLARE_PROPERTY(@"networkID", @"@\"NSNumber\""),
                   DECLARE_PROPERTY(@"lastScrapedLocalContacts", @"@\"NSDate\""),
                   DECLARE_PROPERTY(@"permalink", @"@\"NSString\""),
                   DECLARE_PROPERTY(@"url", @"@\"NSString\""),
                   DECLARE_PROPERTY(@"unseenMessageCount", @"@\"NSNumber\""),
                   DECLARE_PROPERTY(@"name", @"@\"NSString\""),
                   DECLARE_PROPERTY(@"userID", @"@\"NSNumber\""),
                   DECLARE_PROPERTY(@"groupSubscriptionIds", @"@\"NSArray\""),
                   DECLARE_PROPERTY(@"tagSubscriptionIds", @"@\"NSArray\""),
                   DECLARE_PROPERTY(@"userSubscriptionIds", @"@\"NSArray\""),
                   DECLARE_PROPERTY(@"community", @"@\"NSNumber\"")
                   )

- (void)dealloc
{
  self.token = nil;
  self.secret = nil;
  self.userID = nil;
  self.userAccountPK = nil;
  self.networkID = nil;
  self.lastScrapedLocalContacts = nil;
  self.permalink = nil;
  self.url = nil;
  self.name = nil;
  self.groupSubscriptionIds = nil;
  self.tagSubscriptionIds = nil;
  self.userSubscriptionIds = nil;
  self.community = nil;
  [super dealloc];
}

@end
