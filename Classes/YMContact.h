//
//  YMContact.h
//  Yammer
//
//  Created by Samuel Sutch on 5/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SQLitePersistentObject.h"


@interface YMContact : SQLitePersistentObject
{
  NSString *type;
  NSNumber *userID;
  NSString *state;
  
  NSString *username;
  NSString *fullName;
  NSString *mugshotURL;
  NSString *url;
  NSString *webURL;
  NSString *jobTitle;
  NSString *location;
  
  NSArray *emailAddresses; // {type => address}
  NSArray *phoneNumbers;   // {type => address}
  NSArray *im;                  // [{provider => username}, ...]
  
  NSArray *externalURLs;
  
  NSString *birthDate;
  NSString *hireDate;
  
  NSString *summary;
  NSString *timeZone;
  
  NSNumber *networkID;
  NSString *networkName;
  NSArray *networkDomains;
  
  NSDictionary *stats;          // updates/followers/following => num
  
  NSNumber *gotFullRep;
}

@property(copy) 
  NSString *type, *state, *username, *fullName, *mugshotURL, 
           *url, *webURL, *jobTitle, *location, *summary, 
           *timeZone, *networkName;
@property(copy) NSDictionary *stats;
@property(copy) NSArray *im, *networkDomains, *externalURLs,
                                                *emailAddresses, *phoneNumbers;
@property(copy) NSString *birthDate, *hireDate;
@property(copy) NSNumber *userID, *networkID;
@property(copy) NSNumber *gotFullRep;

@end
