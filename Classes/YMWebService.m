//
//  YMWebService.m
//  Yammer
//
//  Created by Samuel Sutch on 4/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "YMWebService.h"
#import "YMUserAccount.h"
#import "YMNetwork.h"
#import "NSString+URLEncoding.h"
#import "NSString+UUID.h"
#import "NSString-SQLiteColumnName.h"
#import "NSString+URLEncoding.h"
#import "SQLiteInstanceManager.h"
#import "DataCache.h"
#import "NSString+XMLEntities.h"
#import "UIImage+RoundedCorner.h"
#import "UIImage+DKDeferred.h"
#import "UIImage+ProportionalFill.h"

static YMWebService *__sharedWebService;

@interface YMWebService (PrivateParts)

- (id)mutableRequestWithMethod:(id)method account:(YMUserAccount *)acct defaults:(NSDictionary *)defaults;
- (id)mutableMultipartRequestWithMethod:(id)method account:(YMUserAccount *)acct defaults:(NSDictionary *)defs;
- (NSString *)parseMessageBody:(NSString *)parsedBody withReferences:(NSDictionary *)refs;
- (NSString *)truncateLinks:(NSString *)html plain:(BOOL)isPlain;
- (id)messageWith:(YMMessage *)message fromDictionary:(NSDictionary *)m withReferences:(NSDictionary *)refs;
- (id)messageFromDictionary:(NSDictionary *)m withReferences:(NSDictionary *)refs;
- (YMContact *)contactforId:(NSNumber *)userId type:(id)typ withReferences:(NSDictionary *)refs;
- (YMContact *)contactFromReference:(NSDictionary *)ref;
- (YMContact *)contactFromFullRepresentation:(NSDictionary *)u;

//- (id)contactImageCache;
- (id)deferredDiskCache;

@property(readonly) DKDeferredPool *loadingPool;

@end

/** 
 returns an NSDictionary from a urlencoded string of parameters
 every key will be a string and every value a string unless multiple values
 exist for that key, in which case it'll be an nsarray with all keys
 */
id __decodeURLEncodedParams(id strOrData) 
{
  id str = ([strOrData isKindOfClass:[NSData class]]
    ? [[[NSString alloc] initWithData:strOrData 
       encoding:NSUTF8StringEncoding] autorelease]
    : strOrData);
//  NSLog(@"__decodeURLEncodedParams str %@", str);
  NSArray *components = [str componentsSeparatedByString:@"&"];
  NSMutableDictionary *d = [NSMutableDictionary dictionary];
  for (NSString *cmp in components) {
    NSArray *els = [cmp componentsSeparatedByString:@"="];
    if ([els count] != 2) continue;
    NSString *k = [[els objectAtIndex:0]
                   stringByReplacingPercentEscapesUsingEncoding:
                   NSUTF8StringEncoding];
    NSString *v = [[els objectAtIndex:1] 
                   stringByReplacingPercentEscapesUsingEncoding:
                   NSUTF8StringEncoding];
    if ([[d allKeys] containsObject:k]) {
      id prevVal = [[[d objectForKey:k] retain] autorelease];
      [d setValue:([prevVal isKindOfClass:[NSArray class]]
                   ? [prevVal arrayByAddingObject:v]
                   : array_(prevVal, v))
           forKey:k];
    } else {
      [d setValue:v forKey:k];
    }
  }
  return d;
}

id __decodeJSON(id results) 
{
  if (results && ! (results == [NSNull null])) {
    NSString *objstr = [[NSString alloc] initWithData:results encoding:NSUTF8StringEncoding];
//    NSLog(@"__decodeJson results %@", objstr);
    NSError *error = nil;
    id ret = [[[[SBJSON alloc] init] autorelease]
              objectWithString:objstr error:&error];
    if (!ret && error) {
      return error;
    }
    [objstr release];
    return ret;
  }
  return nil;
}

id _nil(id r)
{
  if (!r) return nil;
  if ([r isEqual:[NSNull null]]) return nil;
  return r;
}

@implementation YMWebService

@synthesize appKey, appSecret;
@synthesize shouldUpdateBadgeIcon, pushID, syncUsersDeferred;

///
/// constructors
///

+ (id)sharedWebService 
{
  @synchronized(self) {
    if (!__sharedWebService || __sharedWebService == nil) {
      __sharedWebService = [[[self alloc] init] retain];
      __sharedWebService.appKey = WS_APPKEY;
      __sharedWebService.appSecret = WS_APPSECRET;
      __sharedWebService.shouldUpdateBadgeIcon = NO;
    }
  }
  return __sharedWebService;
}

- (NSArray *)loggedInUsers 
{
  return [YMUserAccount findByCriteria:@"WHERE logged_in=1"];
}

-(void) setPushID:(NSString *)i
{
  pushID = nil;
  pushID = [i copy];
  NSLog(@"this is push id %@", i);
  for (YMUserAccount *acct in [self loggedInUsers]) {
    NSNumber *pk = [acct.activeNetworkPK copy];
    for (YMNetwork *n in [YMNetwork findByCriteria:@"WHERE user_account_p_k=%i", acct.pk]) {
      acct.activeNetworkPK = nsni(n.pk);
      [[[[DKDeferredURLConnection alloc] initWithRequest:
        [self mutableMultipartRequestWithMethod:@"feed_clients/" 
        account:acct defaults:dict_(pushID, @"client_id", @"ApplePushDevice", @"type")]
                                               pauseFor:0 decodeFunction:nil] autorelease]
       addBoth:callbackTS(self, _registeredPush:)];
    }
    acct.activeNetworkPK = pk;
  }
}

- (id)_registeredPush:(id)r
{
//  NSLog(@"registered push %@", [NSString stringWithUTF8String:[r bytes]]);
  return r;
}

#pragma mark -
#pragma mark User Accounts

/**
 Saves the OAuth wrap information to the YMUserAccount provided. The web
 service will use these params when accessing the API for non-network
 specific features.
 
 Will callback with the YMUserAccount with updated `wrapToken` and `wrapSecret`
 methods, and automatically persist those values to the model. It'll also
 update all user information for this user account.
 */
- (DKDeferred *)loginUserAccount:(YMUserAccount *)acct 
{
  /// build login request
  NSMutableURLRequest *req = 
    [NSMutableURLRequest requestWithURL:
     [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", 
                           acct.serviceUrl, @"/oauth_wrap/access_token"]]];
  [acct retain];
  const char* theData = 
    [[array_(nsstrf(@"wrap_username=%@", [acct.username encodedURLParameterString]),
             nsstrf(@"wrap_password=%@", [acct.password encodedURLParameterString]),
             nsstrf(@"wrap_client_id=%@", [self.appKey encodedURLParameterString]))
                      componentsJoinedByString:@"&"] UTF8String];
  [req setHTTPBody:[NSData dataWithBytes:theData length:strlen(theData)]];
  [req setHTTPMethod:@"POST"];
  [req setValue:[NSString stringWithFormat:@"%d", strlen(theData)]
    forHTTPHeaderField:@"Content-Length"];
  [req setValue:@"application/x-www-form-urlencoded"
    forHTTPHeaderField:@"Content-Type"];
  req.HTTPShouldHandleCookies = NO;
  // make request
  DKDeferred *d = [[[DKDeferredURLConnection alloc]
                   initRequest:req decodeFunction:nil paused:NO] autorelease];
  return [d addCallbacks:curryTS(self, @selector(_gotAccessToken::), acct) 
                        :callbackTS(self, _failedGetAccessToken:)];
}

- (id)_gotAccessToken:(YMUserAccount *)acct :(id)result 
{
//  NSLog(@"_gotAccessToken: %@ %@", result, [[result URLResponse] allHeaderFields]);
  NSDictionary *r = __decodeURLEncodedParams(result);
  
  if (![[r allKeys] count])
    return [NSError errorWithDomain:@"YMWebService" code:403 
            userInfo:dict_(@"Invalid Login Credentials", @"message")];
  
  acct.wrapToken = [r objectForKey:@"wrap_access_token"];
  acct.wrapSecret = [r objectForKey:@"wrap_refresh_token"];
  acct.password = nil;
  acct.loggedIn = nsni(1);
  [acct save];
  return acct;
}

- (id)_saveCookieToUserAccount:(YMUserAccount *)acct andDecodeResponse:(DKRequestData *)result
{
  NSLog(@"saveCookieHeaders %@", [[result URLResponse] allHeaderFields]);
  if ([result isKindOfClass:[DKRequestData class]] && 
      [[result URLResponse] respondsToSelector:@selector(allHeaderFields)]) {
    acct.cookie = [[[result URLResponse] allHeaderFields] objectForKey:@"Set-Cookie"];
    [acct save];
  }
  return __decodeJSON(result);
}

- (id)_failedGetAccessToken:(NSError *)err 
{
  NSLog(@"_failedGetAccessToken: %@ %@", err, [err userInfo]);
  return err;
}


/**
 Fetches, returns and saves all the networks for this user account.
 
 Will callback with an array of YMNetwork objects.
 */
- (DKDeferred *)networksForUserAccount:(YMUserAccount *)acct 
{
  if (!(acct.wrapToken && acct.wrapSecret))
    return [DKDeferred fail:
            [NSError errorWithDomain:@"" code:403 userInfo:
             dict_(@"Not logged in.", @"message")]];
  NSMutableURLRequest *req = 
    [self mutableRequestWithMethod:@"networks/current.json" 
                           account:acct defaults:EMPTY_DICT];
  NSMutableURLRequest *req2 =
    [self mutableRequestWithMethod:@"oauth/tokens.json" 
                           account:acct defaults:EMPTY_DICT];
  DKDeferred *d = [[DKDeferred gatherResults:
     array_([[[DKDeferredURLConnection alloc]
             initRequest:req decodeFunction:callbackP(__decodeJSON) paused:NO] autorelease],
            [[DKDeferredURLConnection alloc]
             initRequest:req2 decodeFunction:callbackP(__decodeJSON) paused:NO])] autorelease];
  return [d addCallbacks:curryTS(self, @selector(_gotNetworksAndTokens::), acct) 
                        :callbackTS(self, _failedGetNetworksAndTokens:)];
}

- (id)_gotNetworksAndTokens:(YMUserAccount *)acct :(id)results
{
  return [DKDeferred deferInThread:
          curryTS(self, @selector(_processNetworksAndTokensThread::), 
                  acct) withObject:results];
}

- (id)_processNetworksAndTokensThread:(YMUserAccount *)acct :(id)results
{
  NSLog(@"process networks and tokens start");
  NSMutableArray *networks = [NSMutableArray array];
//  NSLog(@"results %@", results);
  if ([results count] == 2) {
    id o = [results objectAtIndex:0];
    id o2 = [results objectAtIndex:1];
    if (![o isKindOfClass:[NSArray class]] && ![o2 isKindOfClass:[NSArray class]]) return EMPTY_ARRAY;
    SQLiteInstanceManager *db = [SQLiteInstanceManager sharedManager];
    @synchronized(self)  {
      [db executeUpdateSQL:@"BEGIN TRANSACTION;"];
      
      // create networks from request, saving auth info
      for (NSDictionary *d in [results objectAtIndex:0]) {

        NSDictionary *ad = nil;
        for (NSDictionary *_ in [results objectAtIndex:1]) {
          if ([_ isKindOfClass:[NSDictionary class]] && [d isKindOfClass:[NSDictionary class]]
              && [[_ objectForKey:@"network_id"] isEqual:[d objectForKey:@"id"]])
            ad = _;
        }
        if (!ad) continue;
        
        // create and save the network object
        YMNetwork *n;
        NSString *criteria = [NSString stringWithFormat:
                              @"WHERE user_account_p_k=%i AND network_i_d='%@'",
                              acct.pk, [d objectForKey:@"id"]];
        
        if (![YMNetwork countByCriteria:criteria]) {
          n = [[[YMNetwork alloc] init] autorelease];
        } else {
          n = (YMNetwork *)[YMNetwork findFirstByCriteria:criteria];
        }
        n.userAccountPK = nsni(acct.pk);
        n.community = [d objectForKey:@"community"];
        n.url = [d objectForKey:@"web_url"];
        n.permalink = [d objectForKey:@"permalink"];
        n.name = [d objectForKey:@"name"];
        n.networkID = [d objectForKey:@"id"];
        n.unseenMessageCount = [d objectForKey:@"unseen_message_count"];
        n.token = [ad objectForKey:@"token"];
        n.secret = [ad objectForKey:@"secret"];
        n.userID = [ad objectForKey:@"user_id"];
        [n save];
        [networks addObject:n];
      }
      [db executeUpdateSQL:@"COMMIT TRANSACTION;"];
    }
    if (self.shouldUpdateBadgeIcon) {
      [self updateUIApplicationBadge];
    }
  }
  NSLog(@"process networks and tokens done");
  return networks;
}

/***/
- (id)_failedGetNetworksAndTokens:(NSError *)error
{
  NSLog(@"_failedGetNetowrksAndTokens: %@ %@", error, [error userInfo]);
  return error;
}

- (DKDeferred *)autocomplete:(YMUserAccount *)acct string:(NSString *)str
{
  DKDeferred *d = [[[DKDeferredURLConnection alloc] initWithRequest:
                    [self mutableRequestWithMethod:@"autocomplete.json" 
                     account:acct defaults:dict_(str, @"prefix")] 
                   pauseFor:0 decodeFunction:callbackP(__decodeJSON)] autorelease];
  return [d addCallback:curryTS(self, @selector(_gotAutocompleteResults:results:), acct)];
}

- (id)_gotAutocompleteResults:(YMUserAccount *)acct results:(id)results
{
  return results;
}

#pragma mark -
#pragma mark Messages

- (DKDeferred *)getMessages:(YMUserAccount *)acct withTarget:(NSString *)target 
withID:(NSNumber *)targetID params:(NSDictionary *)params fetchToID:(NSNumber *)toID unseenLeft:(NSNumber *)unseenLeftCount
{
  NSString *method = nil;
  target = (target != nil ? target : YMMessageTargetAll);
  if (targetID != nil && ![targetID isEqual:[NSNull null]]) 
    method = [NSString stringWithFormat:
              @"messages/%@/%@.json", target, targetID];
  else if (![target isEqual:YMMessageTargetAll])
    method = [NSString stringWithFormat:@"messages/%@.json", target];
  else
    method = @"messages.json";
  
  if ([target isEqual:YMMessageTargetFollowing]) {
    id r = [NSMutableDictionary dictionaryWithDictionary:params];
    [r setObject:@"true" forKey:@"update_last_seen_message_id"];
    params = r;
  }
  
  return [[[[[DKDeferredURLConnection alloc] initWithRequest:
           [self mutableRequestWithMethod:method
            account:acct defaults:params]
           pauseFor:0 decodeFunction:nil] autorelease]
          addCallback:
           curryTS(self, @selector(_saveCookieToUserAccount:andDecodeResponse:), acct)]
          addCallback:
            curryTS(self, @selector(_gotMessages:target:targetID:page:fetchToID:networkID:unseenLeft:results:), 
                    acct, target, (targetID != nil ? targetID : (id)[NSNull null]),
                    nsni(1), (toID != nil ? toID : (id)[NSNull null]), [[acct.activeNetworkPK copy] autorelease], 
                    (unseenLeftCount != nil ? unseenLeftCount : nsni(0)))];
}

- (id)_gotMessages:(YMUserAccount *)acct target:(id)target targetID:(id)targetID
              page:(id)page fetchToID:(id)toID networkID:(id)networkID unseenLeft:(id)unseenLeftCount results:(id)results
{
  return [DKDeferred deferInThread:
          curryTS(self, @selector(_saveMessagesThread:target:targetID:page:fetchToID:networkID:unseenLeft:results:),
                  acct, target, targetID, page, toID, networkID, unseenLeftCount)
                         withObject:results];
}

/// yes this method has become rediculiously bloated
/// im sorry.
- (id)_saveMessagesThread:(YMUserAccount *)acct target:(id)target targetID:(id)targetID
page:(id)page fetchToID:(id)toID networkID:(id)networkID unseenLeft:(id)unseenLeftCount results:(id)results 
{
  NSMutableArray *ret = [NSMutableArray array];

  BOOL fetchToIdFound = NO;
  BOOL fetchingTo = ![toID isEqual:[NSNull null]];
  
  NSLog(@" save messages thread %@ %@ %@ %@ %i %@", target, targetID, page, toID, fetchingTo, unseenLeftCount);
  
  if (![results isKindOfClass:[NSDictionary class]]) return ret;
  
//  NSLog(@"meta %@", [results objectForKey:@"meta"]);
  
  SQLiteInstanceManager *db = [SQLiteInstanceManager sharedManager];
  
  NSNumber *lastSeenID = [[results objectForKey:@"meta"] objectForKey:@"last_seen_message_id"];
  NSString *olderAvailable = [[results objectForKey:@"meta"] objectForKey:@"older_available"];
  NSNumber *unseenCount = nil;
  BOOL markRead = NO;
  if ([target isEqual:YMMessageTargetFollowing]) {
    unseenCount = [[results objectForKey:@"meta"] objectForKey:@"unseen_message_count_following"];
    markRead = YES;
  }
  if ([target isEqual:YMMessageTargetReceived]) {
    unseenCount = [[results objectForKey:@"meta"] objectForKey:@"unseen_message_count_received"];
  } 
  
  if (markRead && lastSeenID && intv(unseenLeftCount) == 0) {
    [db executeUpdateSQL:[NSString stringWithFormat:@"UPDATE y_m_message SET read=1 WHERE message_i_d <= %i",
                          intv([[results objectForKey:@"meta"] objectForKey:@"last_seen_message_id"])]];
  }
  
  
  if ([[results objectForKey:@"messages"] count]) {
    NSArray *likedIDs = [[results objectForKey:@"meta"] objectForKey:@"liked_message_ids"];
    
    @synchronized(self) {
      [db executeUpdateSQL:@"BEGIN TRANSACTION;"];
      
      int i = intv(unseenLeftCount);
      
      for (NSDictionary *m in [results objectForKey:@"messages"]) {     
        NSString *q = [NSString stringWithFormat:@"WHERE message_i_d=%i AND target='%@'%@",
                       intv([m objectForKey:@"id"]), target,
                       (![targetID isEqual:[NSNull null]] 
                        ? [NSString stringWithFormat:@" AND target_i_d=%i", intv(targetID)] : @"")];
        YMMessage *message = nil;
        if ([YMMessage countByCriteria:q])
          message = (id)[YMMessage findFirstByCriteria:q];
        if (!message) message = [[[YMMessage alloc] init] autorelease];
        message = [self messageWith:message fromDictionary:m withReferences:
                   [results objectForKey:@"references"]];
        
        message.networkPK = networkID;
        message.target = target;
        message.targetID = (![targetID isEqual:[NSNull null]] ? targetID : nil);
        message.hasAttachments = nsnb([[m objectForKey:@"attachments"] count]);
        // TODO: sometimes this marks too many messages read.

        if (i > 0)
          message.read = nsnb(NO);
        else
          message.read = nsnb(!lastSeenID || (intv(lastSeenID) >= intv(message.messageID)));
        message.liked = nsnb([likedIDs containsObject:message.messageID]);
        i--;

        [message save];
        
        // build out attachments
        if ([[m objectForKey:@"attachments"] count]) {
          //NSLog(@"m %@", [m objectForKey:@"attachments"]);
          for (NSDictionary *a in [m objectForKey:@"attachments"]) {
            YMAttachment *attachment;
            if (!(attachment = (id)[YMAttachment findFirstByCriteria:
                                @"WHERE attachment_i_d=%i", intv([a objectForKey:@"id"])]))
              attachment = [[[YMAttachment alloc] init] autorelease];
            attachment.attachmentID = [a objectForKey:@"id"];
            attachment.messageID = message.messageID;
            attachment.type = [a objectForKey:@"type"];
            attachment.name = [a objectForKey:@"name"];
            attachment.webURL = [a objectForKey:@"web_url"];
            attachment.messagePK = nsni(message.pk);
            attachment.size = [a objectForKey:@"size"];
            if ([attachment.type isEqualToString:@"image"]) {
              attachment.size = [[a objectForKey:@"image"] objectForKey:@"size"];
              attachment.isImage = nsnb(YES);
              attachment.url = [[a objectForKey:@"image"] objectForKey:@"url"];
              attachment.imageThumbnailURL = [[a objectForKey:@"image"] objectForKey:@"thumbnail_url"];
            } else if ([attachment.type isEqual:@"ymodule"]) {
              attachment.imageThumbnailURL = [[a objectForKey:@"ymodule"] objectForKey:@"icon_url"];
              attachment.isImage = nsnb(NO);
            } else {
              attachment.isImage = nsnb(NO);
              attachment.size = [[a objectForKey:@"file"] objectForKey:@"size"];
              attachment.url = [[a objectForKey:@"file"] objectForKey:@"url"];
            }
            [attachment save];
          }
        }
        
        [ret addObject:message];
        if (fetchingTo && !fetchToIdFound && intv([m objectForKey:@"id"]) == intv(toID))
          fetchToIdFound = YES;
      }
      [db executeUpdateSQL:@"COMMIT TRANSACTION;"];
    }
  }
  
  if ([target isEqual:YMMessageTargetFollowing] || [target isEqual:YMMessageTargetReceived]) {
    if (intv(unseenLeftCount) > 0 || (unseenCount && intv(unseenCount) > [ret count])) {
      YMMessage *lastFetched = [ret lastObject];
      return dict_(nsnb(YES), @"olderAvailable",
                   ((intv(unseenLeftCount) > 0) 
                    ? nsni(intv(unseenLeftCount) - [ret count]) 
                    : nsni(intv(unseenCount) - [ret count])), @"unseenItemsLeftToFetch",
                   lastSeenID, @"lastSeenID",
                   lastFetched.messageID, @"lastFetchedID");
    }
  }
  if (olderAvailable && boolv(olderAvailable)) {
    YMMessage *lastFetched = [ret lastObject];
    return dict_(nsnb(YES), @"olderAvailable", lastFetched.messageID, @"lastFetchedID");
  }
  
  return EMPTY_DICT;
}

- (id)messageWith:(YMMessage *)message fromDictionary:(NSDictionary *)m withReferences:(NSDictionary *)refs
{
  static NSDateFormatter *formatter = nil;
  if (!formatter) {
    formatter = [[[NSDateFormatter alloc] init] retain];
    [formatter setDateFormat:@"yyyy/MM/dd HH:mm:ss ZZ"];
  }
  message.liked = nsnb(NO);
  message.read = nsnb(NO);
  message.messageID = [m objectForKey:@"id"];
  message.groupID = _nil([m objectForKey:@"group_id"]);
  message.directToID = _nil([m objectForKey:@"direct_to_id"]);
  message.url = [m objectForKey:@"url"];
  message.webURL = [m objectForKey:@"web_url"];
  message.repliedToID = _nil([m objectForKey:@"replied_to_id"]);
  message.threadID = _nil([m objectForKey:@"thread_id"]);
  message.bodyPlain = [self truncateLinks:[[m objectForKey:@"body"] objectForKey:@"plain"] plain:YES]; //[[m objectForKey:@"body"] objectForKey:@"plain"];
  message.bodyParsed = [self parseMessageBody:[[m objectForKey:@"body"] objectForKey:@"parsed"]
                               withReferences:refs];
  message.messageType = [m objectForKey:@"message_type"];
  message.clientType = [m objectForKey:@"client_type"];
  message.senderID = [m objectForKey:@"sender_id"];
  message.senderType = [m objectForKey:@"sender_type"];
//  NSLog(@"sender type id %@ type %@", message.senderID, message.senderType);
  message.createdAt = [formatter dateFromString:[m objectForKey:@"created_at"]];
  message.hasAttachments = nsnb(NO);
  
  // connect important references
  if (message.repliedToID) {
    for (NSDictionary *ref in refs) {
      if ([[ref objectForKey:@"type"] isEqual:@"message"] 
          && [[ref objectForKey:@"id"] isEqual:message.repliedToID]) {
        message.repliedToSenderID = _nil([ref objectForKey:@"sender_id"]);
        break;
      }
    }
  }
  
//  YMContact *directTo = nil, *repliedTo = nil, *sender = nil;
  
  // build out contacts
  if (message.directToID && ![YMContact countByCriteria:
                              @"WHERE user_i_d=%@", message.directToID])
    [[self contactforId:message.directToID type:message.senderType withReferences:refs] save];
  if (![YMContact countByCriteria:@"WHERE user_i_d=%@", message.senderID])
    [[self contactforId:message.senderID type:message.senderType withReferences:refs] save];
  if (message.repliedToSenderID && ![YMContact countByCriteria:
                                     @"WHERE user_i_d=%@", message.repliedToSenderID])
    [[self contactforId:message.repliedToSenderID type:message.senderType withReferences:refs] save];
  
//  if (directTo)
//    message.directToSenderName = directTo.fullName;
//  if (repliedTo)
//    message.repliedToSenderName = repliedTo.fullName;
//  if (sender) {
//    message.senderName = sender.fullName;
//    message.senderMugshot = sender.mugshotURL;
//  }
  
  for (NSDictionary *g in refs) {
    if ([[g objectForKey:@"type"] isEqual:@"group"]) {
      YMGroup *group;
      if (!(group = (YMGroup *)[YMGroup findFirstByCriteria:
                                @"WHERE group_i_d=%i", intv([g objectForKey:@"id"])]))
        group = [[[YMGroup alloc] init] autorelease];
      group.groupID = [g objectForKey:@"id"];
      group.fullName = [[g objectForKey:@"full_name"] stringByAppendingString:
                        ([[g objectForKey:@"privacy"] isEqual:@"private"] ? @" (private)" : @"")];
      if (message.groupID && [message.groupID isEqual:[g objectForKey:@"id"]])
        message.groupName = group.fullName;
      group.name = [g objectForKey:@"name"];
      group.url = [g objectForKey:@"url"];
      group.privacy = [g objectForKey:@"privacy"];
      group.webURL = [g objectForKey:@"web_url"];
      group.mugshotURL = [g objectForKey:@"mugshot_url"];
      [group save];
    } else if ([[g objectForKey:@"type"] isEqual:message.senderType]) {
      if (message.directToID && [[g objectForKey:@"id"] isEqual:message.directToID])
        message.directToSenderName = [g objectForKey:@"full_name"];
      if (message.repliedToSenderID && [[g objectForKey:@"id"] isEqual:message.repliedToSenderID])
        message.repliedToSenderName = [g objectForKey:@"full_name"];
      if (message.senderID && [[g objectForKey:@"id"] isEqual:message.senderID]) {
        message.senderName = [g objectForKey:@"full_name"];
        message.senderMugshot = [g objectForKey:@"mugshot_url"];
      } 
    }
  }
  
  return message;  
}

- (id)messageFromDictionary:(NSDictionary *)m withReferences:(NSDictionary *)refs
{
  YMMessage *message = [[[YMMessage alloc] init] autorelease];
  return [self messageWith:message fromDictionary:m withReferences:refs];
}

- (YMContact *)contactforId:(NSNumber *)userId type:(id)typ withReferences:(NSDictionary *)refs
{
  for (NSDictionary *ref in refs) {
    if ([[ref objectForKey:@"type"] isEqual:typ] 
        && [[ref objectForKey:@"id"] isEqual:userId]) {
      return [self contactFromReference:ref];
    }
  }
  return nil;
}

- (NSString *)parseMessageBody:(NSString *)parsedBody withReferences:(NSDictionary *)refs
{
  static NSCharacterSet *openBracketSet = nil;
  static NSCharacterSet *closeBracketSet = nil;
  static NSString *parsedBodyRegex = @"\\[\\[([^\\[\\]]*?)\\]\\]";
  
  static RKLRegexOptions opts = (RKLCaseless | RKLMultiline 
                                 | RKLDotAll | RKLUnicodeWordBoundaries);
  
  parsedBody = [parsedBody stringByEncodingXMLEntities];
  
  if (!openBracketSet) 
    openBracketSet = [[NSCharacterSet characterSetWithCharactersInString:@"["] retain];
  if (!closeBracketSet) 
    closeBracketSet = [[NSCharacterSet characterSetWithCharactersInString:@"]"] retain];
  
  NSMutableString *html = [NSMutableString string];
  int idx = 0;
  
  while (idx <= [parsedBody length]) {
    NSRange match = [parsedBody rangeOfRegex:parsedBodyRegex options:opts inRange:
                     NSMakeRange(idx, [parsedBody length] - idx) capture:0 error:nil];
    if (match.location != NSNotFound) { 
      [html appendString:[parsedBody substringWithRange:NSMakeRange(idx, match.location - idx)]];
      idx = match.location + match.length;
    } 
    else break;
    
    // TODO: this could be optimized
    NSArray *typeAndID = [[parsedBody substringWithRange:match]
                          componentsSeparatedByString:@":"];
    if ([typeAndID count] != 2) {
      [html appendString:[typeAndID componentsJoinedByString:@""]];
      continue;
    }
    NSString *typ = [[typeAndID objectAtIndex:0] stringByTrimmingCharactersInSet:openBracketSet];
    NSString *eyed = [[typeAndID objectAtIndex:1] stringByTrimmingCharactersInSet:closeBracketSet];
    for (NSDictionary *ref in refs) {
      if ([[ref objectForKey:@"type"] isEqual:typ] && intv([ref objectForKey:@"id"]) == intv(eyed)) {
        if ([typ isEqual:@"user"] || [typ isEqual:@"tag"]) {
          [html appendFormat:@"<a href=\"yammer://%@/%@\">%@%@</a>", typ, eyed, 
           ([typ isEqual:@"user"] ? @"@" : @"#"), [ref objectForKey:@"name"]];
        } else {
          [html appendString:[ref objectForKey:@"name"]];
        }
        break;
      }
    }
  }
  
  [html appendString:[parsedBody substringFromIndex:idx]];
  
  [html replaceOccurrencesOfString:@"\n" withString:@"<br>" options:
   NSLiteralSearch range:NSMakeRange(0, [html length] - 1)];
  
  return [self truncateLinks:html plain:NO];
}

- (NSString *)truncateLinks:(NSString *)html plain:(BOOL)isPlain
{
  static NSString *linkRegex = @"((?:(?:ht|f)tp(?:s?)\\:\\/\\/|www\\.[^\\.])\\S+[A-Za-z0-9\\/])";
  static RKLRegexOptions opts = (RKLCaseless | RKLMultiline | RKLDotAll | RKLUnicodeWordBoundaries);
  
  NSMutableString *ret = [NSMutableString string];
  int idx = 0;
  NSRange match;
  NSString *word;
  
  while (idx <= [html length]) {
    match = [html rangeOfRegex:linkRegex options:opts inRange:
             NSMakeRange(idx, [html length] - idx) capture:0 error:nil];
    if (match.location != NSNotFound) {
      [ret appendString:[html substringWithRange:NSMakeRange(idx, match.location - idx)]];
      idx = match.location + match.length;
    } else break;
    word = [html substringWithRange:match];
    if (!isPlain)
      [ret appendFormat:@"<a href=\"%@\">%@...</a>", word, ([word length] > 20 ? [word substringToIndex:20] : word)];
    else 
      [ret appendFormat:@"%@...", ([word length] > 20 ? [word substringToIndex:20] : word)];
  }
  
  [ret appendString:[html substringFromIndex:idx]];
  return ret;
}

- (DKDeferred *)postMessage:(YMUserAccount *)acct body:(NSString *)body 
replyOpts:(NSDictionary *)replyOpts attachments:(NSDictionary *)attaches
{
  NSMutableDictionary *opts = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                               body, YMBodyKey, nil];
  [opts addEntriesFromDictionary:replyOpts];
  [opts addEntriesFromDictionary:attaches];
  
  return [[[[[DKDeferredURLConnection alloc] initWithRequest:
           [self mutableMultipartRequestWithMethod:
             @"messages.json" account:acct defaults:opts]
            pauseFor:0 decodeFunction:callbackP(__decodeJSON)] autorelease]
           addCallback:curryTS(self, @selector(_didPostMessage:::), acct, [[acct.activeNetworkPK copy] autorelease])]
          addErrback:curryTS(self, @selector(_postMessageDidFail::), acct)];
}

- (id)_didPostMessage:(YMUserAccount *)acct :(id)networkPK :(id)results
{
//  NSLog(@"_didPostMessage: %@ %@", acct, results);
  if (![results isKindOfClass:[NSDictionary class]] || 
      ![[results objectForKey:@"messages"] isKindOfClass:[NSArray class]]) return results;
  if ([[results objectForKey:@"messages"] count]) {
    for (NSDictionary *m in [results objectForKey:@"messages"]) {
      YMMessage *message = [self messageFromDictionary:m withReferences:
                            [results objectForKey:@"references"]];
      message.target = YMMessageTargetSent;
      message.targetID = nil;
      message.networkPK = networkPK;
      message.read = nsni(1);
      [message save];
    }
  }
  [[NSNotificationCenter defaultCenter]
   postNotificationName:YMWebServiceDidUpdateMessages object:nil];
  return results;
}

- (id)_postMessageDidFail:(YMUserAccount *)acct :(NSError *)error 
{
  NSLog(@"_postMessageDidFail:%@ %@ %@", acct, error, [error userInfo]);
  return error;
}



- (DKDeferred *)deleteMessage:(YMUserAccount *)acct messageID:(NSString *)messageID
{
  NSMutableURLRequest *req = [self mutableRequestWithMethod:
   [NSString stringWithFormat:@"messages/%@", messageID] 
   account:acct defaults:EMPTY_DICT];
  
  [req setHTTPMethod:@"DELETE"];
  
  return [[[[DKDeferredURLConnection alloc] 
           initWithRequest:req pauseFor:0 decodeFunction:nil] autorelease]
          addCallback:curryTS(self, @selector(_didDeleteMessageID::), messageID)];
}

- (id)_didDeleteMessageID:(NSString *)messageID :(id)results
{
  NSLog(@"_didDeleteMessageID: %@ %@", messageID, results);
  return results;
}

- (DKDeferred *)syncGroups:(YMUserAccount *)acct
{
  return [[[[DKDeferredURLConnection alloc]
           initWithRequest:[self mutableRequestWithMethod:
                            @"f" account:acct defaults:
                            dict_(@"1", @"page")] 
           pauseFor:0 decodeFunction:callbackP(__decodeJSON)] autorelease]
          addCallback:curryTS(self, @selector(_gotGroups::::), acct, [[acct.activeNetworkPK copy] autorelease], nsni(1))];
}

- (id)_gotGroups:(YMUserAccount *)acct :(id)networkPK :(NSNumber *)page :(id)results
{
  BOOL fetchMore = NO;
  if ([results isKindOfClass:[NSArray class]] && [results count]) {
    fetchMore = YES;
    SQLiteInstanceManager *db = [SQLiteInstanceManager sharedManager];
    YMNetwork *network = (YMNetwork *)[YMNetwork findByPK:intv(networkPK)];
    @synchronized(self) {
      [db executeUpdateSQL:@"BEGIN TRANSACTION;"];
      for (NSDictionary *g in results) {
        YMGroup *group;
        if (!(group = (YMGroup *)[YMGroup findFirstByCriteria:
               @"WHERE group_i_d=%i", intv([g objectForKey:@"id"])])) {
          group = [[[YMGroup alloc] init] autorelease];
        }
        group.url = [g objectForKey:@"url"];
        group.webURL = [g objectForKey:@"web_url"];
        group.mugshotURL = [g objectForKey:@"mugshot_url"];
        group.name = [g objectForKey:@"name"];
        group.groupID = [g objectForKey:@"id"];
        group.fullName = [[g objectForKey:@"full_name"] stringByAppendingString:
                          ([[g objectForKey:@"privacy"] isEqual:@"private"] ? @" (private)" : @"")];
        group.privacy = [g objectForKey:@"privacy"];
        group.networkID = network.networkID;
        [group save];
      }
      [db executeUpdateSQL:@"COMMIT TRANSACTION;"];
    }
  }
  if (fetchMore) {
    NSNumber *nextPage = nsni(intv(page)+1);
    return [[[[DKDeferredURLConnection alloc]
             initWithRequest:[self mutableRequestWithMethod:
                              @"groups.json" account:acct defaults:
                              dict_([nextPage stringValue], @"page")] 
             pauseFor:0 decodeFunction:callbackP(__decodeJSON)] autorelease]
            addCallback:curryTS(self, @selector(_gotGroups:::), acct, nextPage)];
  }
  return results;
}

- (DKDeferred *)allTags:(YMUserAccount *)acct
{
  return [[[DKDeferredURLConnection alloc]
          initWithRequest:[self mutableRequestWithMethod:
                           @"tags.json" account:acct defaults:EMPTY_DICT]
          pauseFor:0 decodeFunction:callbackP(__decodeJSON)] autorelease];
}

- (YMContact *)contactFromReference:(NSDictionary *)ref
{
  YMContact *contact;
  if ([YMContact countByCriteria:@"WHERE user_i_d=%@", [ref objectForKey:@"id"]]) {
    contact = (YMContact *)[YMContact findFirstByCriteria:
                            @"WHERE user_i_d=%@", [ref objectForKey:@"id"]];
  } else {
    contact = [[[YMContact alloc] init] autorelease];
    contact.gotFullRep = nsnb(NO);
  }
  contact.userID = [ref objectForKey:@"id"];
  contact.username = [ref objectForKey:@"name"];
  contact.fullName = _nil([ref objectForKey:@"full_name"]);
  contact.mugshotURL = _nil([ref objectForKey:@"mugshot_url"]);
  contact.type = [ref objectForKey:@"type"];
  contact.webURL = [ref objectForKey:@"web_url"];
  return contact;
}

- (DKDeferred *)syncUsers:(YMUserAccount *)acct 
{
  if (self.syncUsersDeferred)
    return self.syncUsersDeferred;
  NSMutableURLRequest *req = [self mutableRequestWithMethod:@"users.json" 
                              account:acct defaults:dict_(@"1", @"page", @"foo", @"refs")];
  id d = [[[[[DKDeferredURLConnection alloc]
            initWithRequest:req pauseFor:0 decodeFunction:callbackP(__decodeJSON)] autorelease]
           addCallback:curryTS(self, @selector(_gotUsers::::), acct, [[acct.activeNetworkPK copy] autorelease], nsni(1))]
          addErrback:callbackTS(self, _getUsersFailed:)];
  self.syncUsersDeferred = d;
  return d;
}

- (id)_gotUsers:(YMUserAccount *)acct :(id)networkPK :(NSNumber *)page :(id)results
{
  return [[DKDeferred deferInThread:curryTS(self, @selector(_importUsersThread::::), acct, networkPK, page) withObject:results]
          addCallback:curryTS(self, @selector(_doneImportingPageOfUsers::::), acct, networkPK, page)];
}

- (id)_doneImportingPageOfUsers:(id)a :(id)n :(id)p :(id)r
{
  NSString *nextPage;
  if ([r isKindOfClass:[NSDictionary class]] && 
      (nextPage = [r objectForKey:@"nextPage"]))
    return [[[[[DKDeferredURLConnection alloc] initWithRequest:
              [self mutableRequestWithMethod:@"users.json"
                account:a defaults:dict_([nextPage description], @"page", @"foo", @"refs")]
               pauseFor:0 decodeFunction:callbackP(__decodeJSON)] autorelease]
             addCallback:curryTS(self, @selector(_gotUsers::::), a, n, nextPage)]
            addErrback:callbackTS(self, _getUsersFailed:)];
  self.syncUsersDeferred = nil;
  return r;
}

- (id)_importUsersThread:(YMUserAccount *)acct :(id)networkPK :(NSNumber *)page :(id)results
{
  id thr = [NSThread currentThread];
  if ([thr respondsToSelector:@selector(setThreadPriority:)]) [thr setThreadPriority:0.0]; 
  //[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
  
  BOOL fetchMore = NO;
  YMNetwork *curNetwork = (YMNetwork *)[YMNetwork findByPK:intv(networkPK)];
  if ([results isKindOfClass:[NSArray class]] && [results count]) {
    fetchMore = YES;
    SQLiteInstanceManager *db = [SQLiteInstanceManager sharedManager];
    @synchronized(self) {
      [db executeUpdateSQL:@"BEGIN TRANSACTION;"];
      for (NSDictionary *u in results) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        YMContact *c = [self contactFromReference:u];
        c.networkID = curNetwork.networkID;
        [c save];
      }
      [db executeUpdateSQL:@"COMMIT TRANSACTION;"];
    }
  }
  if (fetchMore) {
    NSNumber *nextPage = nsni((intv(page)+1));
    NSLog(@"nextPage %@", nextPage);
    return dict_(nextPage, @"nextPage");
  } else {
    id k = [NSString stringWithFormat:@"YMGotFullContactsFor%@", curNetwork.networkID];
    PREF_SET(k, nsnb(YES));
  }
  return results;
}

- (YMContact *)contactFromFullRepresentation:(NSDictionary *)u
{
  YMContact *contact;
  if ([YMContact countByCriteria:@"WHERE user_i_d=%@", [u objectForKey:@"id"]]) {
    contact = (YMContact *)[YMContact findFirstByCriteria:
                            @"WHERE user_i_d=%@", [u objectForKey:@"id"]];
  } else {
    contact = [[[YMContact alloc] init] autorelease];
  }
  
  contact.userID = [u objectForKey:@"id"];
  
  contact.gotFullRep = nsnb(YES);
  contact.username = [u objectForKey:@"name"];
  contact.fullName = _nil([u objectForKey:@"full_name"]);
  contact.mugshotURL = _nil([u objectForKey:@"mugshot_url"]);
  contact.type = [u objectForKey:@"type"];
  contact.webURL = [u objectForKey:@"web_url"];
  contact.jobTitle = _nil([u objectForKey:@"job_title"]);
  contact.url = [u objectForKey:@"url"];
  contact.state = [u objectForKey:@"state"];
  contact.location = _nil([u objectForKey:@"location"]);
//  contact.emailAddresses = [NSMutableArray array];
  NSMutableArray *ems = [NSMutableArray array];
  for (NSDictionary *em in [[u objectForKey:@"contact"]
                            objectForKey:@"email_addresses"])
    [ems addObject:em];
  contact.emailAddresses = ems;
//  contact.phoneNumbers = [NSMutableArray array];
  NSMutableArray *phs = [NSMutableArray array];
  for (NSDictionary *ph in [[u objectForKey:@"contact"]
                            objectForKey:@"phone_numbers"])
    [phs addObject:ph];
  contact.phoneNumbers = phs;
//  contact.im = [NSMutableArray array];
  NSMutableArray *ims = [NSMutableArray array];
  if ([[[[u objectForKey:@"contact"] objectForKey:@"im"] 
        objectForKey:@"provider"] length]) {
    [ims addObject:
     [[u objectForKey:@"contact"] objectForKey:@"im"]];
  }
  contact.im = ims;
  contact.externalURLs = [u objectForKey:@"external_urls"];
  contact.birthDate = _nil([u objectForKey:@"birth_date"]);
  contact.hireDate = _nil([u objectForKey:@"hire_date"]);
  contact.summary = _nil([u objectForKey:@"summary"]);
  contact.timeZone = _nil([u objectForKey:@"time_zone"]);
  contact.networkID = [u objectForKey:@"network_id"];
  contact.networkName = [u objectForKey:@"network_name"];
  contact.networkDomains = [u objectForKey:@"network_domains"];
  contact.stats = [u objectForKey:@"stats"];
  
  return contact;
}

- (id)_getUsersFailed:(NSError *)error
{
  NSLog(@"_getUsersFailed %@ %@", error, [error userInfo]);
  return error;
}

- (DKDeferred *)updateUser:(YMUserAccount *)acct contact:(YMContact *)contact
{
  return [[[[DKDeferredURLConnection alloc] 
           initWithRequest:[self mutableRequestWithMethod:
            [@"users/" stringByAppendingFormat:@"%i.json", 
             intv(contact.userID)] account:acct defaults:EMPTY_DICT]
           pauseFor:0 decodeFunction:callbackP(__decodeJSON)] autorelease]
          addCallback:callbackTS(self, _gotUser:)];
}

- (id)_gotUser:(NSDictionary *)results
{
  if (![results isKindOfClass:[NSDictionary class]]) return results;
  YMContact *ret = [self contactFromFullRepresentation:results];
  [ret save];
  return ret;
}

- (DKDeferred *)syncSubscriptions:(YMUserAccount *)acct
{
  return [[[[DKDeferredURLConnection alloc]
           initWithRequest:[self mutableRequestWithMethod:
           @"users/current.json" account:acct defaults:
           dict_(@"1", @"include_followed_users", @"1", 
                 @"include_followed_tags", @"1", @"include_group_memberships")] 
           pauseFor:0 decodeFunction:callbackP(__decodeJSON)] autorelease]
          addCallback:curryTS(self, @selector(_gotCurrentUser:::), acct, [[acct.activeNetworkPK copy] autorelease])];
}

- (id)_gotCurrentUser:(YMUserAccount *)acct :(id)networkPK :(NSDictionary *)user
{
  return [DKDeferred deferInThread:
          curryTS(self, @selector(_saveSubscriptionsThread:::), acct, networkPK) withObject:user];
}

- (id)_saveSubscriptionsThread:(YMUserAccount *)acct :(id)networkPK :(NSDictionary *)user 
{
  // TODO: currently this ignores followed tags
  
//  NSLog(@"gotCurrentUser %@", user);
  
  YMNetwork *network = (YMNetwork *)[YMNetwork findByPK:intv(networkPK)];
  
  NSMutableArray 
    *groups = [NSMutableArray array],
    *users = [NSMutableArray array];
  SQLiteInstanceManager *db = [SQLiteInstanceManager sharedManager];
  @synchronized(self) {
    [db executeUpdateSQL:@"BEGIN TRANSACTION;"];
    for (NSDictionary *g in [user objectForKey:@"group_memberships"]) {
      YMGroup *group;
      if (!(group = (YMGroup *)[YMGroup findFirstByCriteria:
          @"WHERE group_i_d=%i", intv([g objectForKey:@"id"])]))
        group = [[[YMGroup alloc] init] autorelease];
      group.groupID = [g objectForKey:@"id"];
      group.fullName = [[g objectForKey:@"full_name"] stringByAppendingString:
                        ([[g objectForKey:@"privacy"] isEqual:@"private"] ? @" (private)" : @"")];
      group.name = [g objectForKey:@"name"];
      group.url = [g objectForKey:@"url"];
      group.webURL = [g objectForKey:@"web_url"];
      group.mugshotURL = [g objectForKey:@"mugshot_url"];
      group.networkID = network.networkID;
      group.privacy = [g objectForKey:@"privacy"];
      [group save];
      [groups addObject:group.groupID];
    }
    
    for (NSDictionary *s in [user objectForKey:@"subscriptions"]) {
      if ([[s objectForKey:@"type"] isEqual:@"user"]) {
        YMContact *c = [self contactFromReference:s];
        c.networkID = network.networkID;
        [c save];
        [users addObject:c.userID];
      }
    }
    network.userSubscriptionIds = users;
    network.groupSubscriptionIds = groups;
    [network save];
    [db executeUpdateSQL:@"COMMIT TRANSACTION;"];
  }
  [[NSNotificationCenter defaultCenter]
   postNotificationName:YMWebServiceDidUpdateSubscriptions object:nil];
  
  return user;
}

- (DKDeferred *)like:(YMUserAccount *)acct message:(YMMessage *)message
{
  return [[[[DKDeferredURLConnection alloc]
           initWithRequest:
           [self mutableMultipartRequestWithMethod:@"messages/liked_by/current.json"
            account:acct defaults:dict_([message.messageID description], @"message_id")]
           pauseFor:0 decodeFunction:nil] autorelease]
          addCallback:curryTS(self, @selector(_finishedLike:::), acct, message)];
}

- (id)_finishedLike:(YMUserAccount *)acct :(YMMessage *)message :(id)results
{
  NSLog(@"finishedLike %@ %@", message, [NSString stringWithUTF8String:[results bytes]]);
  message.liked = nsnb(YES);
  [message save];
  return results;
}

- (DKDeferred *)unlike:(YMUserAccount *)acct message:(YMMessage *)message
{
  NSMutableURLRequest *req = 
    [self mutableMultipartRequestWithMethod:@"messages/liked_by/current.json" 
          account:acct defaults:dict_([message.messageID description], 
                                      @"message_id", @"DELETE", @"_method")]; 
  [req setHTTPMethod:@"DELETE"];
  return [[[[DKDeferredURLConnection alloc]
           initWithRequest:req pauseFor:0 decodeFunction:nil] autorelease]
          addCallback:curryTS(self, @selector(_finishedUnlike:::), acct, message)];
}

- (id)_finishedUnlike:(YMUserAccount *)acct :(YMMessage *)message :(NSData *)results
{
  NSLog(@"finishedUnlike: %@ %@", message, [NSString stringWithUTF8String:[results bytes]]);
  message.liked = nsnb(NO);
  [message save];
  return results;
}

- (DKDeferred *)suggestions:(YMUserAccount *)acct fromContacts:(NSArray *)contactDicts
{
  NSMutableURLRequest *req = [self mutableRequestWithMethod:@"suggestions/from_contacts"
                                                    account:acct defaults:EMPTY_DICT];
  [req setHTTPMethod:@"POST"];
  NSString *json = [contactDicts JSONRepresentation];
  NSData *bod = [NSData dataWithBytes:[json UTF8String] length:
                 [json lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
  [req setHTTPBody:bod];
  [req setValue:[NSString stringWithFormat:@"%i", [bod length]]
   forHTTPHeaderField:@"Content-Length"];
  [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

  return [[[[DKDeferredURLConnection alloc]
           initWithRequest:req pauseFor:0 decodeFunction:nil] autorelease]
          addCallback:callbackTS(self, _gotContactSuggestions:)];
}

- (id)_gotContactSuggestions:(id)r
{
  NSLog(@"got contact suggestions %@", [NSString stringWithUTF8String:[r bytes]]);
  return r;
}

- (DKDeferred *)subscribe:(YMUserAccount *)acct to:(NSString *)type withID:(int)theID
{
  return [[[[DKDeferredURLConnection alloc]
           initWithRequest:
           [self mutableMultipartRequestWithMethod:@"subscriptions/"
            account:acct defaults:dict_([NSString stringWithFormat:@"%i", theID],
                                        @"target_id", type, @"target_type")] 
           pauseFor:0 decodeFunction:nil] autorelease]
          addBoth:callbackTS(self, _didSubscribe:)];
}

- (DKDeferred *)unsubscribe:(YMUserAccount *)acct to:(NSString *)type withID:(int)theID
{
  NSMutableURLRequest *req = [self mutableRequestWithMethod:@"subscriptions/" account:acct 
                               defaults:dict_([NSString stringWithFormat:@"%i", theID],
                               @"target_id", type, @"target_type", @"DELETE", @"_method")];
  [req setHTTPMethod:@"DELETE"];
  return [[[[DKDeferredURLConnection alloc]
           initWithRequest:req
           pauseFor:0 decodeFunction:nil]
          addBoth:callbackTS(self, _didUnsubscribe:)] autorelease];
}

- _didSubscribe:(id)r
{
  NSLog(@"_didSubscribe %@", [NSString stringWithUTF8String:[r bytes]]);
  return r;
}

- _didUnsubscribe:(id)r
{
  NSLog(@"_didUbsubscribe: %@", [NSString stringWithUTF8String:[r bytes]]);
  return r;
}

- (DKDeferred *)joinGroup:(YMUserAccount *)acct withId:(int)theId
{
  return [[[[DKDeferredURLConnection alloc] 
           initWithRequest:
           [self mutableMultipartRequestWithMethod:
            @"group_memberships.json" account:acct 
            defaults:dict_([NSString stringWithFormat:@"%i", theId], @"group_id")] 
           pauseFor:0 decodeFunction:nil] autorelease]
          addBoth:callbackTS(self, _didJoinGroup:)];
}

- (DKDeferred *)leaveGroup:(YMUserAccount *)acct withId:(int)theId
{
  return [[[[DKDeferredURLConnection alloc]
           initWithRequest:
           [self mutableRequestWithMethod:
            [NSString stringWithFormat:@"group_memberships/%i.json", theId] 
           account:acct defaults:
            dict_([NSString stringWithFormat:@"%i", theId], @"groupID", @"DELETE", @"_method")] 
           pauseFor:0 decodeFunction:nil] autorelease]
          addBoth:callbackTS(self, _didLeaveGroup:)];                                                                                                   
}

- _didJoinGroup:(id)r
{
  NSLog(@"didJoinGroup %@", [NSString stringWithUTF8String:[r bytes]]);
  return r;
}

- _didLeaveGroup:(id)r
{
  NSLog(@"didLeaveGroup %@", [NSString stringWithUTF8String:[r bytes]]);
  return r;
}

#pragma mark -
#pragma mark Contact Images

- (DKDeferred *)loadCachedContactImagesForUserAccount:(YMUserAccount *)acct
{
  YMNetwork *curNetwork = (YMNetwork *)[YMNetwork findByPK:
                                        intv(acct.activeNetworkPK)];
  NSMutableArray *keys = [[[[YMContact pairedArraysForProperties:
                             array_(@"mugshotURL") 
           withCriteria:@"WHERE network_i_d=%i", intv(curNetwork.networkID)]
          objectAtIndex:1] retain] autorelease];
  
  // limit total fetch to 300
  NSIndexSet *indexSet;
  if ([keys count] > 300)
    indexSet = [NSIndexSet indexSetWithIndexesInRange:
                NSMakeRange(0, 300)];
  else if ([keys count])
    indexSet = [NSIndexSet indexSetWithIndexesInRange:
                NSMakeRange(0, [keys count] - 1)];
  else 
    indexSet = [NSIndexSet indexSet];

  
  NSArray *fetchKeys = [keys objectsAtIndexes:indexSet];
  
  DKDeferredCache *cache = [self deferredDiskCache];
  DKDeferred *d = [cache getManyValues:fetchKeys];
  return [d addCallback:curryTS(self, @selector(_gotContactImages:::), fetchKeys, acct)];
}

- (id)_gotContactImages:(NSArray *)keys :(YMUserAccount *)acct :(NSArray *)values 
{
//  int i = 0;
//  NSLog(@"_gotContactImages %@ %@", keys, values);
//  DataCache *memCache = [self contactImageCache];
//  for (id k in keys) {
//    if (![k isEqual:[NSNull null]] && ![[values objectAtIndex:i] 
//                                        isEqual:[NSNull null]]) {
//      [memCache setObject:[UIImage imageWithData:[values objectAtIndex:i]] forKey:k];
//    }
//    i++;
//  }
  if (userAccountForCachedContactImages) [userAccountForCachedContactImages release];
  userAccountForCachedContactImages = [acct retain];
  return nil;
}

- (BOOL)didLoadContactImagesForUserAccount:(YMUserAccount *)acct
{
  return userAccountForCachedContactImages == acct;
}

- (void) purgeCachedContactImages
{
//  [DKDeferred deferInThread:curryTS(self, @selector(_purgeCachedKeys::), nsnb(YES))
//                 withObject:[[self contactImageCache] allKeys]];
}

- (void)writeCachedContactImages
{
//  [DKDeferred deferInThread:curryTS(self, @selector(_purgeCachedKeys::), nsnb(NO))
//                 withObject:[[self contactImageCache] allKeys]];
}

//- (id)_purgeCachedKeys:(NSNumber *)memoryToo :(NSArray *)keys
//{
//  BOOL removeFromMem = boolv(memoryToo);
//  DKDeferredCache *c = [self deferredDiskCache];
//  DataCache *mem = [self contactImageCache];
//  for (NSString *k in keys) {
//    if (![c hasKey:k])
//      [c _setValue:UIImagePNGRepresentation([mem objectForKey:k])
//            forKey:k timeout:nsni(864000) arg:nil];
//    if (removeFromMem)
//      [mem invalidateKey:k];
//  }
//  if (removeFromMem) {
//    [userAccountForCachedContactImages release];
//    userAccountForCachedContactImages = nil;
//  }
//  return nil;
//}

- (DKDeferred *)contactImageForURL:(NSString *)url
{
  if ([url isEqual:[NSNull null]] || [url isMatchedByRegex:@"no_photo_small\\.gif$"])
    return [DKDeferred succeed:[UIImage imageNamed:@"user-70.png"]];
  
  id ret = [[self deferredDiskCache] objectForKeyInMemory:url];
  if (ret) return [DKDeferred succeed:ret];
  id d = nil;
  if ([[DKDeferred cache] hasKey:url]) 
    d = [[DKDeferred cache] valueForKey:url paused:YES];
  else d = [[DKDeferred loadURL:url paused:YES] addCallback:
            curryTS(self, @selector(_gotMugshotKey:data:), url)];
  return [self.loadingPool add:d key:url];
}

- (id)_gotMugshotKey:(NSString *)k data:(NSData *)mugshot
{
  if ([mugshot isKindOfClass:[NSData class]]) {
    UIImage *img = [UIImage imageWithData:mugshot];
    if (img) {
      UIImage *scaled = [[img imageCroppedToFitSize:CGSizeMake(44, 44)] 
                         roundedCornerImage:3 borderSize:1];
      if (!scaled) return nil;
      [[DKDeferred cache] setValue:scaled forKey:k timeout:-1];
      return scaled;
    }
  }
  return nil;
}
      

- (id)imageForURLInMemoryCache:(NSString *)url
{
  return [[self deferredDiskCache] objectForKeyInMemory:url];
}

#pragma mark -
#pragma mark Mostly Private Stuff


- (id)deferredDiskCache
{
  return [DKDeferred cache];
}

- (DKDeferredPool *)loadingPool
{
  if (!loadingPool) {
    loadingPool = [[[DKDeferredPool alloc] init] retain];
    [loadingPool setConcurrency:3];
  }
  return loadingPool;
}

/**
 In UIKit applications, this will update the application
 icon badge for unread messages in all persistent YMNetworks combined
 */

- (int)totalUnseen
{
  NSArray *counts = [YMNetwork pairedArraysForProperties:
                     array_(@"unseenMessageCount")];
  //NSLog(@"counts %@", counts);
  int totalUnseen = 0;
  for (NSNumber *unseenCount in [counts objectAtIndex:1]) {
    totalUnseen += intv(unseenCount);
  }
  return totalUnseen;
}

- (void)updateUIApplicationBadge
{
  id app = [NSClassFromString(@"UIApplication") sharedApplication];
  if (app != NULL)
    [app setApplicationIconBadgeNumber:[self totalUnseen]];
}

- (void)subtractUnseenCount:(int)ct fromNetwork:(YMNetwork *)network
{
  int c = intv(network.unseenMessageCount) - ct;
  if (c < 0) c = 0;
  network.unseenMessageCount = nsni(c);
  [[SQLiteInstanceManager sharedManager]
   executeUpdateSQL:[NSString stringWithFormat:
   @"UPDATE y_m_network SET unseen_message_count=%i WHERE pk=%i", c, network.pk]];
}

/**
 Builds a new NSMutableURLRequest with the proper headers for OAuth 1.0
 If the supplied YMUserAccount has an active network (IE: one they want
 to look at currently, the OAuth token/secret for that network will be
 used.
 */
- (id)mutableRequestWithMethod:(id)method 
account:(YMUserAccount *)acct defaults:(NSDictionary *)defaults
{
  NSMutableString *params = [NSMutableString string];
  if (defaults && [[defaults allKeys] count]) {
    [params setString:@"?"];
    for (NSString *k in [defaults allKeys]) {
      [params appendFormat:@"%@=%@&", [k encodedURLParameterString], 
       [[defaults objectForKey:k] encodedURLParameterString]];
    }
    if ([params length] > 1)
      [params replaceCharactersInRange:
       NSMakeRange([params length] - 1, 1) withString:@""];
  }
  
  NSMutableURLRequest *req = 
  [NSMutableURLRequest requestWithURL:
   [NSURL URLWithString:[[WS_MOUNTPOINT(acct.serviceUrl) description]
                         stringByAppendingFormat:@"/%@%@", method, params]]
                          cachePolicy:NSURLRequestUseProtocolCachePolicy
                      timeoutInterval:20.0];

  [self authorizeRequest:req withAccount:acct];
  
  return req;
}

- (void)authorizeRequest:(NSMutableURLRequest *)req withAccount:(YMUserAccount *)acct
{
  NSString *tok = @"", *sec = @"", *verifier = @"";
  NSString *sig = [NSString stringWithFormat:@"%@%%26", self.appSecret];
  if (acct.activeNetworkPK) {
    YMNetwork *network = (YMNetwork *)[YMNetwork findByPK:intv(acct.activeNetworkPK)];
    tok = network.token;
    sec = network.secret;
  } else {
    if (acct.wrapSecret && acct.wrapToken) {
      tok = acct.wrapToken;
      sec = acct.wrapSecret;
    }
  }
  if (tok) {
    tok = [NSString stringWithFormat:@"oauth_token=\"%@\", ", tok];
    sig = [NSString stringWithFormat:@"%@%@", sig, sec];
  }
  NSTimeInterval ts = [[NSDate date] timeIntervalSince1970];
  NSString *header = [NSString stringWithFormat:
                      @"OAuth realm=\"\", oauth_consumer_key=\"%@\", %@"
                      @"oauth_signature_method=\"PLAINTEXT\", "
                      @"oauth_signature=\"%@\", oauth_timestamp=\"%f\", "
                      @"oauth_nounce=\"%f\", %@oauth_version=\"1.0\"",
                      self.appKey, tok, sig, ts, ts, verifier];
//  NSLog(@"auth header %@", header);
  [req setValue:header forHTTPHeaderField:@"Authorization"];
  [req setHTTPShouldHandleCookies:NO];
  [req setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
}

/**
 Builds a new NSMutableURLRequest suitable for posting files to the server.
 Returns an NSMutableURLRequest with the http method set to "POST", the
 content-type, post data and content-length already filled in. It will
 contain all the OAuth information same as `-mutableRequstWithMethod:account:defaults:`
 */
- (id)mutableMultipartRequestWithMethod:(id)method 
account:(YMUserAccount *)acct defaults:(NSDictionary *)defs
{
  NSMutableURLRequest *req = [self mutableRequestWithMethod:method 
                                  account:acct defaults:EMPTY_DICT];
  NSString *boundaryID = [NSString stringWithUUID];
  NSString *boundary = [NSString stringWithFormat:@"--%@\r\n", boundaryID];
  
  id val;
  int attachmentCount = 1;
  NSMutableData *body = [NSMutableData data];
  
  for (NSString *key in [defs allKeys]) {
    [body appendData:[boundary dataUsingEncoding:NSUTF8StringEncoding]];
    val = [defs objectForKey:key];
    if ([val isKindOfClass:[NSString class]]) {
      [body appendData:[[NSString stringWithFormat:
       @"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key]
                        dataUsingEncoding:NSUTF8StringEncoding]];
      [body appendData:[val dataUsingEncoding:NSUTF8StringEncoding]];
    } else if ([val isKindOfClass:[NSData class]]) {
      [body appendData:[[NSString stringWithFormat:
       @"Content-Disposition: form-data; name=\"attachment%i\"; filename=\"%@\"\r\n",
       attachmentCount, key] dataUsingEncoding:NSUTF8StringEncoding]];
      [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n"
                        dataUsingEncoding:NSUTF8StringEncoding]];
      [body appendData:val];
      attachmentCount++;
    } else if ([val isKindOfClass:[UIImage class]]) {
      [body appendData:[[NSString stringWithFormat:
                         @"Content-Disposition: form-data; name=\"attachment%i\"; filename=\"%@\"\r\n",
                         attachmentCount, key] dataUsingEncoding:NSUTF8StringEncoding]];
      [body appendData:[@"Content-Type: image/jpeg\r\n\r\n"
                        dataUsingEncoding:NSUTF8StringEncoding]];
      
      [body appendData:UIImageJPEGRepresentation(
       [(UIImage *)val resizedImageWithContentMode:
        UIViewContentModeScaleAspectFit bounds:CGSizeMake(1024, 1024) 
                              interpolationQuality:kCGInterpolationDefault], 5)];
      attachmentCount++;
    }
    [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
  }
  
  [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundaryID]
                    dataUsingEncoding:NSUTF8StringEncoding]];
  
  [req setHTTPMethod:@"POST"];
  [req setHTTPBody:body];
  [req setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@",
                 boundaryID] forHTTPHeaderField:@"Content-Type"];
  [req setValue:[NSString stringWithFormat:@"%i", [body length]] 
   forHTTPHeaderField:@"Content-Length"];
  
  return req;
}

@end
