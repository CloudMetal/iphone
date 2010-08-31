//
//  YMGroup.m
//  Yammer
//
//  Created by Samuel Sutch on 5/24/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "YMGroup.h"


@implementation YMGroup

@synthesize groupID, fullName, name, privacy, url, webURL, 
            members, updates, networkID, mugshotURL;

DECLARE_PROPERTIES(
                   DECLARE_PROPERTY(@"groupID", @"@\"NSNumber\""),
                   DECLARE_PROPERTY(@"fullName", @"@\"NSString\""),
                   DECLARE_PROPERTY(@"name", @"@\"NSString\""),
                   DECLARE_PROPERTY(@"privacy", @"@\"NSString\""),
                   DECLARE_PROPERTY(@"url", @"@\"NSString\""),
                   DECLARE_PROPERTY(@"webURL", @"@\"NSString\""),
                   DECLARE_PROPERTY(@"members", @"@\"NSNumber\""),
                   DECLARE_PROPERTY(@"networkID", @"@\"NSNumber\""),
                   DECLARE_PROPERTY(@"mugshotURL", @"@\"NSString\"")
                   )

- (void)dealloc
{
  self.groupID = nil;
  self.fullName = nil;
  self.name = nil;
  self.privacy = nil;
  self.url = nil;
  self.webURL = nil;
  self.members = nil;
  self.updates = nil;
  self.networkID = nil;
  self.mugshotURL = nil;
  [super dealloc];
}

@end
