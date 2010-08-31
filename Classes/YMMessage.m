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

@synthesize messageID, groupID, directToID, url, webURL, repliedToID, target, 
            threadID, bodyPlain, bodyParsed, messageType, targetID, liked, hasAttachments, 
            clientType, senderID, senderType, createdAt, networkPK, read, repliedToSenderID,
            /// these are cache attributes
            repliedToSenderName, directToSenderName, senderName, senderMugshot, groupName;

DECLARE_PROPERTIES(
                   DECLARE_PROPERTY(@"messageID", @"@\"NSNumber\""),
                   DECLARE_PROPERTY(@"groupID", @"@\"NSNumber\""),
                   DECLARE_PROPERTY(@"directToID", @"@\"NSNumber\""),
                   DECLARE_PROPERTY(@"url", @"@\"NSString\""),
                   DECLARE_PROPERTY(@"webURL", @"@\"NSString\""),
                   DECLARE_PROPERTY(@"repliedToID", @"@\"NSNumber\""),
                   DECLARE_PROPERTY(@"target", @"@\"NSString\""),
                   DECLARE_PROPERTY(@"threadID", @"@\"NSNumber\""),
                   DECLARE_PROPERTY(@"bodyPlain", @"@\"NSString\""),
                   DECLARE_PROPERTY(@"bodyParsed", @"@\"NSString\""),
                   DECLARE_PROPERTY(@"messageType", @"@\"NSString\""),
                   DECLARE_PROPERTY(@"targetID", @"@\"NSNumber\""),
                   DECLARE_PROPERTY(@"liked", @"@\"NSNumber\""),
                   DECLARE_PROPERTY(@"hasAttachments", @"@\"NSNumber\""),
                   DECLARE_PROPERTY(@"clientType", @"@\"NSString\""),
                   DECLARE_PROPERTY(@"senderID", @"@\"NSNumber\""),
                   DECLARE_PROPERTY(@"senderType", @"@\"NSString\""),
                   DECLARE_PROPERTY(@"createdAt", @"@\"NSDate\""),
                   DECLARE_PROPERTY(@"networkPK", @"@\"NSNumber\""),
                   DECLARE_PROPERTY(@"read", @"@\"NSNumber\""),
                   DECLARE_PROPERTY(@"repliedToSenderID", @"@\"NSNumber\""),
                   DECLARE_PROPERTY(@"repliedToSenderName", @"@\"NSString\""),
                   DECLARE_PROPERTY(@"directToSenderName", @"@\"NSString\""),
                   DECLARE_PROPERTY(@"senderName", @"@\"NSString\""),
                   DECLARE_PROPERTY(@"senderMugshot", @"@\"NSString\""),
                   DECLARE_PROPERTY(@"groupName", @"@\"NSString\"")
                   )

+ (NSArray *) indices
{
  return array_(
                array_(@"pk"),
                array_(@"messageID"), // TODO: add networkPK
                array_(@"messageID", @"senderID"),
                array_(@"messageID", @"targetID", @"target")
                );
//                array_(@"messageID", @"repliedToID", @"repliedToSenderID"),
//                array_(@"messageID", @"repliedToID", @"senderID", @"repliedToSenderID"),
//                array_(@"messageID", @"targetID", @"repliedToID", @"repliedToSenderID"),
//                array_(@"messageID", @"targetID", @"repliedToID", @"repliedToSenderID", @"senderID"));
}

- (void)dealloc
{
  self.messageID = nil;
  self.groupID = nil;
  self.directToID = nil;
  self.url = nil;
  self.webURL = nil;
  self.repliedToID = nil;
  self.target = nil;
  self.threadID = nil;
  self.bodyPlain = nil;
  self.url = nil;
  self.webURL = nil;
  self.repliedToID = nil;
  self.liked = nil;
  self.hasAttachments = nil;
  self.clientType = nil;
  self.senderID = nil;
  self.createdAt = nil;
  self.networkPK = nil;
  self.read = nil;
  self.repliedToSenderID = nil;
  self.repliedToSenderName = nil;
  self.directToSenderName = nil;
  self.senderName = nil;
  self.senderMugshot = nil;
  self.groupName = nil;
  [super dealloc];
}

@end
