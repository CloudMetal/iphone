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

@property(nonatomic, readwrite, retain) 
  NSString *type, *state, *username, *fullName, *mugshotURL, 
           *url, *webURL, *jobTitle, *location, *summary, 
           *timeZone, *networkName;
@property(nonatomic, readwrite, retain) NSDictionary *stats;
@property(nonatomic, readwrite, retain) NSArray *im, *networkDomains, *externalURLs,
                                                *emailAddresses, *phoneNumbers;
@property(nonatomic, readwrite, retain) NSString *birthDate, *hireDate;
@property(nonatomic, readwrite, retain) NSNumber *userID, *networkID;
@property(nonatomic, readwrite, retain) NSNumber *gotFullRep;

@end
