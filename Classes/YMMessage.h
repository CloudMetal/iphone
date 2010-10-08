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
  
  NSString *repliedToSenderName, *directToSenderName, *senderName, *senderMugshot, *groupName;
  NSNumber *totalThreadCount, *unseenThreadCount, *numberOfParticipants;
  NSDate *threadLastUpdated;
}

@property(nonatomic, readwrite, retain) NSDate *threadLastUpdated;
@property(nonatomic, readwrite, retain) NSNumber *messageID;
@property(nonatomic, readwrite, retain) NSNumber *totalThreadCount, *unseenThreadCount, *numberOfParticipants;
@property(nonatomic, readwrite, retain) NSNumber *groupID;
@property(nonatomic, readwrite, retain) NSNumber *directToID;
@property(nonatomic, readwrite, retain) NSNumber *repliedToID;
@property(nonatomic, readwrite, retain) NSNumber *threadID;

@property(nonatomic, readwrite, retain) NSString *url;
@property(nonatomic, readwrite, retain) NSString *webURL;
@property(nonatomic, readwrite, retain) NSString *bodyParsed;
@property(nonatomic, readwrite, retain) NSString *bodyPlain;

@property(nonatomic, readwrite, retain) NSString *messageType;
@property(nonatomic, readwrite, retain) NSString *clientType;

@property(nonatomic, readwrite, retain) NSNumber *senderID;
@property(nonatomic, readwrite, retain) NSString *senderType;

@property(nonatomic, readwrite, retain) NSDate *createdAt;

@property(nonatomic, readwrite, retain) NSNumber *networkPK;
@property(nonatomic, readwrite, retain) NSNumber *read;
@property(nonatomic, readwrite, retain) NSString *target;
@property(nonatomic, readwrite, retain) NSNumber *targetID;

@property(nonatomic, readwrite, retain) NSNumber *repliedToSenderID;

@property(nonatomic, readwrite, retain) NSNumber *hasAttachments, *liked;

@property(nonatomic, readwrite, retain) NSString *repliedToSenderName, *directToSenderName, *senderName, *senderMugshot, *groupName;

@end
