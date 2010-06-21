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

@end
