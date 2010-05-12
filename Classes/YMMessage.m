//
//  YMMessage.m
//  Yammer
//
//  Created by Samuel Sutch on 5/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "YMMessage.h"
#import "YMWebService.h"
#import "NSString-SQLiteColumnName.h"


@implementation YMMessage

DECLARE_PROPERTIES(
 DECLARE_PROPERTY(@"messageID", @"@\"NSNumber\""),
 DECLARE_PROPERTY(@"directToID", @"@\"NSNumber\""),
 DECLARE_PROPERTY(@"repliedToID", @"@\"NSNumber\""),
 DECLARE_PROPERTY(@"threadID", @"@\"NSNumber\""),
 DECLARE_PROPERTY(@"senderID", @"@\"NSNumber\""),
 DECLARE_PROPERTY(@"targetID", @"@\"NSNumber\""),
 DECLARE_PROPERTY(@"networkPK", @"@\"NSNumber\""),
 DECLARE_PROPERTY(@"read", @"@\"NSNumber\""),
 DECLARE_PROPERTY(@"url", @"@\"NSString\""),
 DECLARE_PROPERTY(@"target", @"@\"NSString\""),
 DECLARE_PROPERTY(@"bodyPlain", @"@\"NSString\""),
 DECLARE_PROPERTY(@"bodyParsed", @"@\"NSString\""),
 DECLARE_PROPERTY(@"messageType", @"@\"NSString\""),
 DECLARE_PROPERTY(@"clientType", @"@\"NSString\""),
 DECLARE_PROPERTY(@"senderType", @"@\"NSString\""),
 DECLARE_PROPERTY(@"createdAt", @"@\"NSDate\""),
 DECLARE_PROPERTY(@"attachmentPKs", @"@\"NSArray\"")
)

@synthesize messageID, groupID, directToID, url, webURL, repliedToID, target, 
            threadID, bodyPlain, bodyParsed, attachmentPKs, messageType, targetID, 
            clientType, senderID, senderType, createdAt, networkPK, read;

@end
