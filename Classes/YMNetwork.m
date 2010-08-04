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
