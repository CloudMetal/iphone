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
            clientType, senderID, senderType, createdAt, networkPK, read, repliedToSenderID;

+ (NSArray *) indices
{
  return array_(
                array_(@"pk"),
                array_(@"messageID", @"repliedToID"),
                array_(@"messageID"), // TODO: add networkPK
                array_(@"messageID", @"senderID"),
                array_(@"messageID", @"repliedToID", @"repliedToSenderID"),
                array_(@"messageID", @"repliedToID", @"senderID", @"repliedToSenderID"),
                array_(@"messageID", @"targetID", @"repliedToID", @"repliedToSenderID"),
                array_(@"messageID", @"targetID", @"repliedToID", @"repliedToSenderID", @"senderID"));
}

@end
