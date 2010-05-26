//
//  YMGroup.m
//  Yammer
//
//  Created by Samuel Sutch on 5/24/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "YMGroup.h"


@implementation YMGroup
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
@synthesize groupID, fullName, name, privacy, url, webURL, members, updates, networkID;

@end
