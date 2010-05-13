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
            threadID, bodyPlain, bodyParsed, attachmentPKs, messageType, targetID, 
            clientType, senderID, senderType, createdAt, networkPK, read, repliedToSenderID;

@end
