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
  NSNumber *community;
  NSNumber *userID;
  
  NSArray *groupSubscriptionIds;
  NSArray *tagSubscriptionIds;
  NSArray *userSubscriptionIds;
}

@property (nonatomic, readwrite, retain) NSNumber *userAccountPK, *userID, *community;
@property (nonatomic, readwrite, retain) NSDate *lastScrapedLocalContacts;
@property (nonatomic, readwrite, retain) NSNumber *networkID, *unseenMessageCount;
@property (nonatomic, readwrite, retain) NSString *permalink, *url, *name;
@property (nonatomic, readwrite, retain) NSString *token, *secret;
@property (nonatomic, readwrite, retain) NSArray 
  *groupSubscriptionIds, *tagSubscriptionIds, *userSubscriptionIds;

@end
