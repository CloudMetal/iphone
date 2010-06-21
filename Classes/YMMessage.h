#import <Foundation/Foundation.h>
#import "SQLitePersistentObject.h"


@interface YMMessage : SQLitePersistentObject 
{
  NSNumber *messageID;
  NSNumber *groupID;
  NSNumber *directToID;
  NSString *url;
  NSString *webURL;
  NSNumber *repliedToID;
  NSNumber *threadID;
  
  NSString *bodyParsed;
  NSString *bodyPlain;
  
  NSString *messageType;
  NSString *clientType;
  
  NSNumber *senderID;
  NSString *senderType;
  
  NSDate *createdAt;
  
  NSNumber *networkPK;
  NSNumber *read;
  NSString *target;
  NSNumber *targetID;
  
  NSNumber *repliedToSenderID;
  
  NSNumber *hasAttachments;
  NSNumber *liked;
}

@property(copy) NSNumber *messageID;

@property(copy) NSNumber *groupID;
@property(copy) NSNumber *directToID;
@property(copy) NSNumber *repliedToID;
@property(copy) NSNumber *threadID;

@property(copy) NSString *url;
@property(copy) NSString *webURL;
@property(copy) NSString *bodyParsed;
@property(copy) NSString *bodyPlain;

@property(copy) NSString *messageType;
@property(copy) NSString *clientType;

@property(copy) NSNumber *senderID;
@property(copy) NSString *senderType;

@property(copy) NSDate *createdAt;

@property(copy) NSNumber *networkPK;
@property(copy) NSNumber *read;
@property(copy) NSString *target;
@property(copy) NSNumber *targetID;

@property(copy) NSNumber *repliedToSenderID;

@property(copy) NSNumber *hasAttachments, *liked;

@end
