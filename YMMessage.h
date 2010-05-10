//
//  YMMessage.h
//  Yammer
//
//  Created by Samuel Sutch on 5/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SQLitePersistentObject.h"


@interface YMMessage : SQLitePersistentObject 
{
  NSNumber *messageID;
  NSNumber *groupID;
  NSNumber *directToID;
  NSString *URL;
  NSString *webURL;
  NSNumber *repliedToID;
  NSNumber *threadID;
  
  NSString *bodyParsed;
  NSString *bodyPlain;
  
  NSArray *attachmentPKs;
  
  NSString *messageType;
  NSString *clientType;
  
  NSNumber *senderID;
  NSString *senderType;
  
  NSDate *createdAt;
  
  NSNumber *networkPK;
  NSNumber *read;
}

@property(nonatomic, retain, readwrite) NSNumber *messageID;
@property(nonatomic, retain, readwrite) NSNumber *groupID;
@property(nonatomic, retain, readwrite) NSNumber *directToID;
@property(nonatomic, retain, readwrite) NSString *URL;
@property(nonatomic, retain, readwrite) NSString *webURL;
@property(nonatomic, retain, readwrite) NSNumber *repliedToID;
@property(nonatomic, retain, readwrite) NSNumber *threadID;

@property(nonatomic, retain, readwrite) NSString *bodyParsed;
@property(nonatomic, retain, readwrite) NSString *bodyPlain;

@property(nonatomic, retain, readwrite) NSArray *attachmentPKs;

@property(nonatomic, retain, readwrite) NSString *messageType;
@property(nonatomic, retain, readwrite) NSString *clientType;

@property(nonatomic, retain, readwrite) NSNumber *senderID;
@property(nonatomic, retain, readwrite) NSString *senderType;

@property(nonatomic, retain, readwrite) NSDate *createdAt;

@property(nonatomic, retain, readwrite) NSNumber *networkPK;
@property(nonatomic, retain, readwrite) NSNumber *read;

@end
