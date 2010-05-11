//
//  YMWebService.h
//  Yammer
//
//  Created by Samuel Sutch on 4/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YMNetwork.h"
#import "YMUserAccount.h"
#import "YMMessage.h"
#import "YMWebService+Private.h"

#define WS_URL @"https://staging.yammer.com"
#define WS_MOUNTPOINT [NSURL URLWithString:[NSString \
            stringWithFormat:@"%@%@", WS_URL, @"/api/v1"]]

#define YMMessageTargetAll @""
#define YMMessageTargetSent @"sent"
#define YMMessageTargetReceived @"received"
#define YMMessageTargetFollowing @"following"
#define YMMessageTargetFromUser @"from_user"
#define YMMessageTargetFromBot @"from_bot"
#define YMMessageTargetTaggedWith @"tagged_with"
#define YMMessageTargetInGroup @"in_group"
#define YMMessageTargetFavoritesOf @"favorites_of"
#define YMMessageTargetInThread @"in_thread"

#define YMSenderTypeUser @"user"
#define YMSenderTypeBot @"bot"
#define YMSenderTypeGuide @"guide"

#define YMBodyKey @"body"
#define YMGroupIDKey @"group_id"
#define YMReplyToIDKey @"reply_to_id"
#define YMDirectToIDKey @"direct_to_id"


@interface YMWebService : NSObject
{
  NSURL *mountPoint;
  NSString *appKey;
  NSString *appSecret;
  BOOL shouldUpdateBadgeIcon;
}

+ (id)sharedWebService;

@property (copy) NSURL *mountPoint;
@property (copy) NSString *appKey;
@property (copy) NSString *appSecret;
@property (assign) BOOL shouldUpdateBadgeIcon;


- (NSArray *)loggedInUsers;
- (void)updateUIApplicationBadge;

/** 
 Takes a YMUserAccount and authenticates it against the yammer
 API. It uses the `username` and `password` instance variables of
 the account to authenticate. Upon successful authentication this will
 save the OAuth+Wrap information to the user account so it can be used
 to fetch available networks.
 
 Calls back with the updated, saved YMUserAccount. If you have not yet saved
 this YMUserAccount it will be saved. `wrapToken` and `wrapSecret` will
 be automatically populated.
 */
- (DKDeferred *)loginUserAccount:(YMUserAccount *)acct;

/**
 Takes the YMUserAccount and calls back with a list of YMNetwork objects
 with all OAuth+Wrap information included (it uses two API requests to 
 obtain this information.)
 */
- (DKDeferred *)networksForUserAccount:(YMUserAccount *)acct;


/**
 Takes a YMUserAccount and calls back with all messages from the company-wide feed
 from the `activeNetworkPK` of the user account provided. Calls back with a list
 of YMMessage objects.
 
 This method requires that `activeNetworkPK` be set on the user's account and that
 the YMNetwork with that PK has been fetched and has updated OAuth token/secret info.
 */
- (DKDeferred *)getMessages:(YMUserAccount *)acct params:(NSDictionary *)params;

/**
 Takes a YMUserAccount and calls back with all messages from the provided target.
 IE: YMMessageTargetSent will return a list of messages the user received in their
 `activeNetworkPK`.
 
 This method requires that `activeNetworkPK` be set on the user's account and that
 the YMNetwork with that PK has been fetched and has updated OAuth token/secret info.
 
 Example:
 
 You can query the most recent 20 messages delivered to you like this:
 
 [[YMWebService sharedService]
  getMessages:myAccount withTarget:
  YMMessageTargetReceived params:nil]
 
 */
- (DKDeferred *)getMessages:(YMUserAccount *)acct 
                 withTarget:(id)target 
                     params:(NSDictionary *)params;

/**
 Similar to `getMessage:withTarget:params` except you can provide a target ID. Some 
 message targets require an ID like YMMessageTargetInGroup will require the group ID.
 */
- (DKDeferred *)getMessages:(YMUserAccount *)acct 
                 withTarget:(id)target 
                     withID:(NSString *)targetID
                     params:(NSDictionary *)params;

/**
 Posts a new message to the supplied YMUserAccount's `activeNetworkPK`. `replyOpts`
 is a dictionary containing any of the following keys that will tell the Yammer service
 how to address the new message:
 
  YMGroupIDKey    => a message directed at a group, the ID of the group
  YMReplyToIDKey  => a reply to another message, the ID of the message
  YMDirectToIDKey => a private message to another user, the ID of the user
 
 Attachments are also a dictionary. You can specify up to 21 attachments, the keys
 will be used as the file name. The values MUST be the NSData value of the filename.
 
 Calls back with the YMMessage that was just posted, already saved.
 */
- (DKDeferred *)postMessage:(YMUserAccount *)acct body:(NSString *)body 
replyOpts:(NSDictionary *)replyOpts attachments:(NSDictionary *)attaches;

/**
 Removes the message from the Yammer service and from the local YMMessage data store.
 
 Calls back on success with the supplied messageID of the removed message.
 */
- (DKDeferred *)deleteMessage:(YMUserAccount *)acct messageID:(NSString *)messageID;

@end

