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
#import "YMContact.h"
#import "YMWebService+Private.h"
#import "YMGroup.h"
#import "YMAttachment.h"

#define WS_MOUNTPOINT(__THE_URL) [NSURL URLWithString:[NSString \
            stringWithFormat:@"%@%@", __THE_URL, @"/api/v1"]]

#define IS_TARGET(__a, __b) ([__a isEqualToString:__b])

#define YMWebServiceDidUpdateMessages @"webservicedidendmessageupdates"
#define YMWebServiceDidUpdateSubscriptions @"webservicedidupdatesubscriptions"

#define YMLastSeenMessageID @"lastSeenMessageID"

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
#define YMReplyToIDKey @"replied_to_id"
#define YMDirectToIDKey @"direct_to_id"

@class DataCache;

@interface YMWebService : NSObject
{
//  NSURL *mountPoint;
  NSString *appKey;
  NSString *appSecret;
  BOOL shouldUpdateBadgeIcon;
  DataCache *_contactImageCache;
  DKDeferredPool *loadingPool;
  YMUserAccount *userAccountForCachedContactImages;
  NSString *pushID;
  DKDeferred *syncUsersDeferred;
}

+ (id)sharedWebService;

//@property (copy) NSURL *mountPoint;
@property (copy) NSString *appKey;
@property (copy) NSString *appSecret;
@property (assign) BOOL shouldUpdateBadgeIcon;
@property (copy) NSString *pushID;
@property (retain) DKDeferred *syncUsersDeferred;


- (NSArray *)loggedInUsers;
- (int)totalUnseen;
- (void)updateUIApplicationBadge;
- (void)subtractUnseenCount:(int)ct fromNetwork:(YMNetwork *)network;

// high performance contact image caching
- (DKDeferred *)loadCachedContactImagesForUserAccount:(YMUserAccount *)acct;
- (void)purgeCachedContactImages;
- (void)writeCachedContactImages;
- (id)imageForURLInMemoryCache:(NSString *)url;
- (DKDeferred *)contactImageForURL:(NSString *)url;
- (BOOL)didLoadContactImagesForUserAccount:(YMUserAccount *)acct;
- (void)authorizeRequest:(NSMutableURLRequest *)req withAccount:(YMUserAccount *)acct;

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
 Returns a NSDictionary structure of tag objects
 */
- (DKDeferred *)allTags:(YMUserAccount *)acct;

/**
 Syncs users groups to YMGroup
 */
- (DKDeferred *)syncGroups:(YMUserAccount *)acct;


///**
// Takes a YMUserAccount and calls back with all messages from the company-wide feed
// from the `activeNetworkPK` of the user account provided. Calls back with a list
// of YMMessage objects.
// 
// This method requires that `activeNetworkPK` be set on the user's account and that
// the YMNetwork with that PK has been fetched and has updated OAuth token/secret info.
// */
////- (DKDeferred *)getMessages:(YMUserAccount *)acct params:(NSDictionary *)params;
//
///**
// Takes a YMUserAccount and calls back with all messages from the provided target.
// IE: YMMessageTargetSent will return a list of messages the user received in their
// `activeNetworkPK`.
// 
// This method requires that `activeNetworkPK` be set on the user's account and that
// the YMNetwork with that PK has been fetched and has updated OAuth token/secret info.
// 
// Example:
// 
// You can query the most recent 20 messages delivered to you like this:
// 
// [[YMWebService sharedService]
//  getMessages:myAccount withTarget:
//  YMMessageTargetReceived params:nil]
// 
// */
////- (DKDeferred *)getMessages:(YMUserAccount *)acct 
////                 withTarget:(id)target 
////                     params:(NSDictionary *)params;
//
///**
// Similar to `getMessage:withTarget:params` except you can provide a target ID. Some 
// message targets require an ID like YMMessageTargetInGroup will require the group ID.
// */

- (DKDeferred *)getMessages:(YMUserAccount *)acct withTarget:(NSString *)target 
withID:(NSNumber *)targetID params:(NSDictionary *)params fetchToID:(NSNumber *)toID 
                 unseenLeft:(NSNumber *)unseenLeftCount;

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

/**
 */
- (DKDeferred *)syncUsers:(YMUserAccount *)acct;

/**
 */
- (DKDeferred *)updateUser:(YMUserAccount *)acct contact:(YMContact *)contact;

/**
 */
- (DKDeferred *)syncSubscriptions:(YMUserAccount *)acct;

/**
 */
- (DKDeferred *)like:(YMUserAccount *)acct message:(YMMessage *)message;

/**
 */
- (DKDeferred *)unlike:(YMUserAccount *)acct message:(YMMessage *)message;

/**
 */
- (DKDeferred *)subscribe:(YMUserAccount *)acct to:(NSString *)type withID:(int)theID;

/**
 */
- (DKDeferred *)unsubscribe:(YMUserAccount *)acct to:(NSString *)type withID:(int)theID;

/**
 */
- (DKDeferred *)suggestions:(YMUserAccount *)acct fromContacts:(NSArray *)contactDicts;

/**
 */
- (DKDeferred *)joinGroup:(YMUserAccount *)acct withId:(int)theId;

/*
 */
- (DKDeferred *)leaveGroup:(YMUserAccount *)acct withId:(int)theId;

/**
 */
- (DKDeferred *)autocomplete:(YMUserAccount *)acct string:(NSString *)str;

/**
 */
//- (DKDeferred *)send:(YMUserAccount *)acct message:(YMMessage *)message;

@end

