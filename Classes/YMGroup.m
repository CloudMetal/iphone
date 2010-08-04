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
