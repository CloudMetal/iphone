//
//  YMMessage.m
//  Yammer
//
//  Created by Samuel Sutch on 5/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "YMMessage.h"


@implementation YMMessage

@synthesize messageID, groupID, directToID, URL, webURL, repliedToID, 
            threadID, bodyPlain, bodyParsed, attachmentPKs, messageType, 
            clientType, senderID, senderType, createdAt, networkPK, read;

@end
