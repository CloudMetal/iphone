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

DECLARE_PROPERTIES(
                   DECLARE_PROPERTY(@"type", @"@\"NSString\""),
                   DECLARE_PROPERTY(@"userID", @"@\"NSNumber\""),
                   DECLARE_PROPERTY(@"state", @"@\"NSString\""),
                   DECLARE_PROPERTY(@"username", @"@\"NSString\""),
                   DECLARE_PROPERTY(@"fullName", @"@\"NSString\""),
                   DECLARE_PROPERTY(@"mugshotURL", @"@\"NSString\""),
                   DECLARE_PROPERTY(@"url", @"@\"NSString\""),
                   DECLARE_PROPERTY(@"webURL", @"@\"NSString\""),
                   DECLARE_PROPERTY(@"jobTitle", @"@\"NSString\""),
                   DECLARE_PROPERTY(@"location", @"@\"NSString\""),
                   DECLARE_PROPERTY(@"emailAddresses", @"@\"NSArray\""),
                   DECLARE_PROPERTY(@"phoneNumbers", @"@\"NSArray\""),
                   DECLARE_PROPERTY(@"im", @"@\"NSArray\""),
                   DECLARE_PROPERTY(@"externalURLs", @"@\"NSArray\""),
                   DECLARE_PROPERTY(@"birthDate", @"@\"NSString\""),
                   DECLARE_PROPERTY(@"hireDate", @"@\"NSString\""),
                   DECLARE_PROPERTY(@"summary", @"@\"NSString\""),
                   DECLARE_PROPERTY(@"timeZone", @"@\"NSString\""),
                   DECLARE_PROPERTY(@"networkID", @"@\"NSNumber\""),
                   DECLARE_PROPERTY(@"networkDomains", @"@\"NSArray\""),
                   DECLARE_PROPERTY(@"networkName", @"@\"NSString\""),
                   DECLARE_PROPERTY(@"stats", @"@\"NSDictionary\""),
                   DECLARE_PROPERTY(@"gotFullRep", @"@\"NSNumber\"")
                   )

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
