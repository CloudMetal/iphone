//
//  YMGroup.h
//  Yammer
//
//  Created by Samuel Sutch on 5/24/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SQLitePersistentObject.h"

/**
 <group>
 <type>group</type>
 <id>1</id>
 <full-name>Sales Team</full-name>
 <name>salesteam</name>
 <privacy>public</privacy>
 <url>https://www.yammer.com/api/v1/groups/1</url>
 <web-url>https://www.yammer.com/groups/salesteam</web-url>
 <stats>
 <members>5</members>
 <updates>102</updates>
 </stats>
 </group>
 */

@interface YMGroup : SQLitePersistentObject {
  NSNumber *groupID;
  NSString *fullName;
  NSString *name;
  NSString *privacy;
  NSString *url;
  NSString *webURL;
  NSNumber *members;
  NSNumber *updates;
  NSNumber *networkID;
}

@property(nonatomic, readwrite, retain) NSNumber *groupID, *members, *updates, *networkID;
@property(nonatomic, readwrite, retain) NSString *fullName, *name, *privacy, *url, *webURL;

@end
