//
//  YMContact.m
//  Yammer
//
//  Created by Samuel Sutch on 5/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "YMContact.h"
#import "SQLiteInstanceManager.h"

@implementation YMContact

@synthesize type, userID, state, username, fullName, mugshotURL, 
            url, webURL, jobTitle, location, emailAddresses, 
            phoneNumbers, im, externalURLs, birthDate, hireDate, 
            summary ,timeZone, networkID, networkDomains, networkName, stats, gotFullRep;

+ (NSArray *) indices
{
  return array_(
                array_(@"pk"),
                array_(@"userID"), 
                array_(@"userID", @"username"),
                array_(@"userID", @"username", @"mugshotURL"));
}

- (void)dealloc
{
  self.type = nil;
  self.userID = nil;
  self.state = nil;
  self.username = nil;
  self.fullName = nil;
  self.mugshotURL = nil;
  self.url = nil;
  self.webURL = nil;
  self.jobTitle = nil;
  self.location = nil;
  self.emailAddresses = nil;
  self.phoneNumbers = nil;
  self.im  = nil;
  self.externalURLs = nil;
  self.birthDate = nil;
  self.hireDate = nil;
  self.summary = nil;
  self.timeZone = nil;
  self.networkID = nil;
  self.networkDomains = nil;
  self.networkName = nil;
  self.stats = nil;
  self.gotFullRep = nil;
  [super dealloc];
}

@end
