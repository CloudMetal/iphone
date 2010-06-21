//
//  YMNetwork.h
//  Yammer
//
//  Created by Samuel Sutch on 4/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SQLitePersistentObject.h"


@interface YMNetwork : SQLitePersistentObject
{
  NSString *token, *secret;
  NSNumber *networkID;
  NSNumber *userAccountPK;
  NSString *permalink, *url;
  NSNumber *unseenMessageCount;
  NSDate *lastScrapedLocalContacts;
  NSString *name;
  NSNumber *userID;
  
  NSArray *groupSubscriptionIds;
  NSArray *tagSubscriptionIds;
  NSArray *userSubscriptionIds;
}

@property (copy) NSNumber *userAccountPK, *userID;
@property (copy) NSDate *lastScrapedLocalContacts;
@property (copy) NSNumber *networkID, *unseenMessageCount;
@property (copy) NSString *permalink, *url, *name;
@property (copy) NSString *token, *secret;
@property (copy) NSArray 
  *groupSubscriptionIds, *tagSubscriptionIds, *userSubscriptionIds;

@end
