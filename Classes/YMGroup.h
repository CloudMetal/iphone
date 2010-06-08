//
//  YMGroup.h
//  Yammer
//
//  Created by Samuel Sutch on 5/24/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SQLitePersistentObject.h"


@interface YMGroup : SQLitePersistentObject {
  NSNumber *groupID;
  NSString *fullName;
  NSString *name;
  NSString *privacy;
  NSString *url;
  NSString *webURL, *mugshotURL;
  NSNumber *members;
  NSNumber *updates;
  NSNumber *networkID;
}

@property(nonatomic, readwrite, retain) NSNumber *groupID, *members, *updates, *networkID;
@property(nonatomic, readwrite, retain) NSString *fullName, *name, *privacy, *url, *webURL, *mugshotURL;

@end
