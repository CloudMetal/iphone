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

static YMWebService *__sharedWebService;

@interface YMWebService (PrivateStuffs)

- (id)mutableRequestWithMethod:(id)method 
account:(YMUserAccount *)acct defaults:(NSDictionary *)defaults;

- (id)mutableMultipartRequestWithMethod:(id)method 
account:(YMUserAccount *)acct defaults:(NSDictionary *)defs;

- (id)contactImageCache;
- (id)deferredDiskCache;

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
    id ret = [[[SBJSON alloc] init]
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

@synthesize mountPoint, appKey, appSecret;
@synthesize shouldUpdateBadgeIcon;


///
/// constructors
///

+ (id)sharedWebService 
{
  @synchronized(self) {
    if (!__sharedWebService || __sharedWebService == nil) {
      __sharedWebService = [[[self alloc] init] retain];
      __sharedWebService.mountPoint = WS_MOUNTPOINT;
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
                           WS_URL, @"/oauth_wrap/access_token"]]];
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
  DKDeferred *d = [[DKDeferredURLConnection alloc]
                   initRequest:req decodeFunction:
                   callbackP(__decodeURLEncodedParams) paused:NO];
  return [d addCallbacks:curryTS(self, @selector(_gotAccessToken::), acct) 
                        :callbackTS(self, _failedGetAccessToken:)];
}

- (id)_gotAccessToken:(YMUserAccount *)acct :(id)result 
{
  NSLog(@"_gotAccessToken: %@", result);
  
  if (![[result allKeys] count])
    return [NSError errorWithDomain:@"YMWebService" code:403 
            userInfo:dict_(@"Invalid Login Credentials", @"message")];
  
  acct.wrapToken = [result objectForKey:@"wrap_access_token"];
  acct.wrapSecret = [result objectForKey:@"wrap_refresh_token"];
  acct.loggedIn = nsni(1);
  [acct save];
  return acct;
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
  DKDeferred *d = [DKDeferred gatherResults:
     array_([[DKDeferredURLConnection alloc]
             initRequest:req decodeFunction:callbackP(__decodeJSON) paused:NO],
            [[DKDeferredURLConnection alloc]
             initRequest:req2 decodeFunction:callbackP(__decodeJSON) paused:NO])];
  return [d addCallbacks:curryTS(self, @selector(_gotNetworksAndTokens::), acct) 
                        :callbackTS(self, _failedGetNetworksAndTokens:)];
}

- (id)_gotNetworksAndTokens:(YMUserAccount *)acct :(id)results
{
  NSMutableArray *networks = [NSMutableArray array];
  if ([results count] == 2) {
    // remove existing networks and their associated data
    int i;
    SQLiteInstanceManager *db = [SQLiteInstanceManager sharedManager];
    [db executeUpdateSQL:@"BEGIN TRANSACTION;"];
    
    // create networks from request, saving auth info
    for (NSDictionary *d in [results objectAtIndex:0]) {
      // get the auth stuff from the tokens array
      i = 0;
      NSDictionary *ad = [[results objectAtIndex:1] objectAtIndex:i];
      while (![[ad objectForKey:@"network_id"] isEqual:[d objectForKey:@"id"]]) 
        ad = [[results objectAtIndex:1] objectAtIndex:i++];
      
      // create and save the network object
      YMNetwork *n;
      NSString *criteria = [NSString stringWithFormat:
                            @"WHERE user_account_p_k=%i AND network_i_d='%@'",
                            acct.pk, [d objectForKey:@"id"]];
      
      if (![YMNetwork countByCriteria:criteria]) {
        n = [YMNetwork new];
      } else {
        n = [[YMNetwork findFirstByCriteria:criteria] autorelease];
      }
      n.userAccountPK = nsni(acct.pk);
      n.url = [d objectForKey:@"web_url"];
      n.permalink = [d objectForKey:@"permalink"];
      n.name = [d objectForKey:@"name"];
      n.networkID = [d objectForKey:@"id"];
      n.unseenMessageCount = [d objectForKey:@"unseen_message_count"];
      n.token = [ad objectForKey:@"token"];
      n.secret = [ad objectForKey:@"secret"];
      [n save];
      [networks addObject:n];
    }
    [db executeUpdateSQL:@"COMMIT TRANSACTION;"];
    if (self.shouldUpdateBadgeIcon) {
      [self updateUIApplicationBadge];
    }
  }
  return networks;
}

- (id)_failedGetNetworksAndTokens:(NSError *)error
{
  NSLog(@"_failedGetNetowrksAndTokens: %@ %@", error, [error userInfo]);
  return error;
}

#pragma mark -
#pragma mark Messages

- (DKDeferred *)getMessages:(YMUserAccount *)acct params:(NSDictionary *)params
{
  return [[[DKDeferredURLConnection alloc] initWithRequest:
           [self mutableRequestWithMethod:@"messages.json" account:acct defaults:params]
           pauseFor:0 decodeFunction:callbackP(__decodeJSON)]
          addCallback:curryTS(self, @selector(_gotMessages::::), acct, 
                              YMMessageTargetAll, [NSNull null])];
}

- (DKDeferred *)getMessages:(YMUserAccount *)acct 
withTarget:(id)target params:(NSDictionary *)params
{
  return [[[DKDeferredURLConnection alloc] initWithRequest:
           [self mutableRequestWithMethod:
            [NSString stringWithFormat:@"messages/%@.json", target]
           account:acct defaults:params]
          pauseFor:0 decodeFunction:callbackP(__decodeJSON)]
         addCallback:curryTS(self, @selector(_gotMessages::::), acct, 
                             target, [NSNull null])];
}

- (DKDeferred *)getMessages:(YMUserAccount *)acct 
withTarget:(id)target withID:(NSString *)targetID params:(NSDictionary *)params
{
  return [[[DKDeferredURLConnection alloc] initWithRequest:
           [self mutableRequestWithMethod:
            [NSString stringWithFormat:
             @"messages/%@/%@.json", target, targetID]
            account:acct defaults:params]
           pauseFor:0 decodeFunction:callbackP(__decodeJSON)]
          addCallback:curryTS(self, @selector(_gotMessages::::), acct,
                              target, targetID)];
}

- (id)_gotMessages:(YMUserAccount *)acct :(id)target :(id)targetID :(id)results
{
//  NSLog(@"gotMessages %@", results);
  NSMutableArray *ret = [NSMutableArray array];
  NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
  [formatter setDateFormat:@"yyyy/MM/dd HH:mm:ss ZZ"];
  
  if ([[results objectForKey:@"messages"] count]) {
    SQLiteInstanceManager *db = [SQLiteInstanceManager sharedManager];
    
    NSArray *existingMessageIDs = 
      [YMMessage pairedArraysForProperties:array_(@"messageID") withCriteria:
       [NSString stringWithFormat:@"WHERE network_p_k=%i AND target='%@'%@", intv(acct.activeNetworkPK), target, 
        (![targetID isEqual:[NSNull null]] 
         ? [NSString stringWithFormat:@" AND target_i_d='%@'", targetID] 
         : @"")]];
    
    NSMutableArray *existings = [NSMutableArray array];
    for (NSString *existingIDAsString in [existingMessageIDs objectAtIndex:1])
      [existings addObject:nsni([existingIDAsString intValue])];
    
    [db executeUpdateSQL:@"BEGIN TRANSACTION;"];
    
    for (NSDictionary *m in [results objectForKey:@"messages"]) {      
      if (![existings containsObject:[m objectForKey:@"id"]]) {
        YMMessage *message = [YMMessage new];
        message.messageID = [m objectForKey:@"id"];
        message.groupID = _nil([m objectForKey:@"group_id"]);
        message.directToID = _nil([m objectForKey:@"direct_to_id"]);
        message.url = [m objectForKey:@"url"];
        message.webURL = [m objectForKey:@"web_url"];
        message.repliedToID = _nil([m objectForKey:@"replied_to_id"]);
        message.threadID = _nil([m objectForKey:@"thread_id"]);
        message.bodyPlain = [[m objectForKey:@"body"] objectForKey:@"plain"];
        message.bodyParsed = [[m objectForKey:@"body"] objectForKey:@"parsed"];
        message.messageType = [m objectForKey:@"message_type"];
        message.clientType = [m objectForKey:@"client_type"];
        message.senderID = [m objectForKey:@"sender_id"];
        message.senderType = [m objectForKey:@"sender_type"];
        message.createdAt = [formatter dateFromString:[m objectForKey:@"created_at"]];
        message.read = nsni(0);
        message.attachmentPKs = [NSArray array];
        message.networkPK = acct.activeNetworkPK;
        message.target = target;
        message.targetID = (![targetID isEqual:[NSNull null]] ? targetID : nil);
        [message save];
        
        [ret addObject:message];
      }
    }
    [db executeUpdateSQL:@"COMMIT TRANSACTION;"];
  }
  
  return ret;
}

- (DKDeferred *)postMessage:(YMUserAccount *)acct body:(NSString *)body 
replyOpts:(NSDictionary *)replyOpts attachments:(NSDictionary *)attaches
{
  NSMutableDictionary *opts = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                               body, YMBodyKey, nil];
  [opts addEntriesFromDictionary:replyOpts];
  [opts addEntriesFromDictionary:attaches];
  
  return [[[DKDeferredURLConnection alloc] initWithRequest:
           [self mutableMultipartRequestWithMethod:
            @"messages/" account:acct defaults:opts]
           pauseFor:0 decodeFunction:callbackP(__decodeJSON)]
          addCallback:curryTS(self, @selector(_didPostMessage::), acct)];
}

- (id)_didPostMessage:(YMUserAccount *)acct :(id)results
{
  NSLog(@"_didPostMessage: %@ %@", acct, results);
  return results;
}

- (DKDeferred *)deleteMessage:(YMUserAccount *)acct messageID:(NSString *)messageID
{
  NSMutableURLRequest *req = [self mutableRequestWithMethod:
   [NSString stringWithFormat:@"messages/%@", messageID] 
   account:acct defaults:EMPTY_DICT];
  
  [req setHTTPMethod:@"DELETE"];
  
  return [[[DKDeferredURLConnection alloc] 
           initWithRequest:req pauseFor:0 decodeFunction:nil]
          addCallback:curryTS(self, @selector(_didDeleteMessageID::), messageID)];
}

- (id)_didDeleteMessageID:(NSString *)messageID :(id)results
{
  NSLog(@"_didDeleteMessageID: %@ %@", messageID, results);
  return results;
}

- (DKDeferred *)syncUsers:(YMUserAccount *)acct 
{
  NSLog(@"mm sync? %@", acct);
  NSMutableURLRequest *req = [self mutableRequestWithMethod:@"users.json" 
                                   account:acct defaults:EMPTY_DICT];
  return [[[[DKDeferredURLConnection alloc]
            initWithRequest:req pauseFor:0 decodeFunction:callbackP(__decodeJSON)]
           addCallback:curryTS(self, @selector(_gotUsers:::), acct, nsni(0))]
          addErrback:callbackTS(self, _getUsersFailed:)];
}

//- (id)_gotUsers:(YMUserAccount *)acct :(NSNumber *)page :(id)results
//{
//  return [[DKDeferred deferInThread:curryTS(self, @selector(_gotUsersThread:::), 
//                                           acct, page) withObject:results]
//          addCallback:callbackTS(self, _r:)];
//}
//
//- (id)_r:(id)r { return r; }

- (id)_gotUsers:(YMUserAccount *)acct :(NSNumber *)page :(id)results
{
  BOOL fetchMore = NO;
  if ([results isKindOfClass:[NSArray class]] && [results count]) {
    fetchMore = YES;
    SQLiteInstanceManager *db = [SQLiteInstanceManager sharedManager];
    [db executeUpdateSQL:@"BEGIN TRANSACTION;"];
    for (NSDictionary *u in results) {
      //      NSLog(@"u %@", u);
      YMContact *contact;
      if ([YMContact countByCriteria:@"WHERE user_i_d=%@", [u objectForKey:@"id"]]) {
        contact = (YMContact *)[YMContact findFirstByCriteria:
                                @"WHERE user_i_d=%@", [u objectForKey:@"id"]];
      } else {
        contact = [YMContact new];
      }
      
      contact.userID = [u objectForKey:@"id"];
      contact.type = [u objectForKey:@"type"];
      contact.state = [u objectForKey:@"state"];
      contact.username = [u objectForKey:@"name"];
      contact.fullName = _nil([u objectForKey:@"full_name"]);
      contact.mugshotURL = _nil([u objectForKey:@"mugshot_url"]);
      contact.url = [u objectForKey:@"url"];
      contact.webURL = [u objectForKey:@"web_url"];
      contact.jobTitle = _nil([u objectForKey:@"job_title"]);
      contact.location = _nil([u objectForKey:@"location"]);
      contact.emailAddresses = [NSMutableArray array];
      for (NSDictionary *em in [[u objectForKey:@"contact"]
                                objectForKey:@"email_addresses"])
        [(NSMutableArray *)contact.emailAddresses addObject:em];
      contact.phoneNumbers = [NSMutableArray array];
      for (NSDictionary *ph in [[u objectForKey:@"contact"]
                                objectForKey:@"phone_numbers"])
        [(NSMutableArray *)contact.phoneNumbers addObject:ph];
      contact.im = [NSMutableArray array];
      if ([[[[u objectForKey:@"contact"] objectForKey:@"im"] 
            objectForKey:@"provider"] length]) {
        [(NSMutableArray *)contact.im addObject:
         [[u objectForKey:@"contact"] objectForKey:@"im"]];
      }
      contact.externalURLs = [u objectForKey:@"external_urls"];
      contact.birthDate = _nil([u objectForKey:@"birth_date"]);
      contact.hireDate = _nil([u objectForKey:@"hire_date"]);
      contact.summary = _nil([u objectForKey:@"summary"]);
      contact.timeZone = _nil([u objectForKey:@"time_zone"]);
      contact.networkID = [u objectForKey:@"network_id"];
      contact.networkName = [u objectForKey:@"network_name"];
      contact.networkDomains = [u objectForKey:@"network_domains"];
      contact.stats = [u objectForKey:@"stats"];
      [contact save];
    }
    [db executeUpdateSQL:@"COMMIT TRANSACTION;"];
  }
  if (fetchMore) {
    NSNumber *nextPage = nsni((intv(page)+1));
    NSLog(@"nextPage %@", nextPage);
    return [[[[DKDeferredURLConnection alloc] initWithRequest:
              [self mutableRequestWithMethod:@"users.json"
                                     account:acct defaults:dict_([nextPage description], @"page")]
                                                     pauseFor:0 decodeFunction:callbackP(__decodeJSON)]
             addCallback:curryTS(self, @selector(_gotUsers:::), acct, nextPage)]
            addErrback:callbackTS(self, _getUsersFailed:)];
  }
  return results;
}

- (id)_getUsersFailed:(NSError *)error
{
  NSLog(@"_getUsersFailed %@ %@", error, [error userInfo]);
  return error;
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
  return [d addCallback:curryTS(self, @selector(_gotContactImages::), fetchKeys)];
}

- (id)_gotContactImages:(NSArray *)keys :(NSArray *)values
{
  int i = 0;
//  NSLog(@"_gotContactImages %@ %@", keys, values);
  DataCache *memCache = [self contactImageCache];
  for (id k in keys) {
    if (![k isEqual:[NSNull null]] && ![[values objectAtIndex:i] 
                                        isEqual:[NSNull null]]) {
      [memCache setObject:[UIImage imageWithData:[values objectAtIndex:i]] forKey:k];
    }
    i++;
  }
  return nil;
}

- (void) purgeCachedContactImages
{
  [DKDeferred deferInThread:callbackTS(self, _purgeCachedKeys:)
                 withObject:[[self contactImageCache] allKeys]];
}

- (id)_purgeCachedKeys:(NSArray *)keys
{
  DKDeferredCache *c = [self deferredDiskCache];
  DataCache *mem = [self contactImageCache];
  for (NSString *k in keys) {
    [c _setValue:UIImagePNGRepresentation([mem objectForKey:k])
          forKey:k timeout:nsni(864000) arg:nil];
    [mem invalidateKey:k];
  }
  return nil;
}

- (DKDeferred *)contactImageForURL:(NSString *)url
{
  if ([url isEqual:[NSNull null]] || [url isMatchedByRegex:@"no_photo_small\\.gif$"])
    return [DKDeferred succeed:[UIImage imageNamed:@"user-70.png"]];
  
  id ret = [[self contactImageCache] objectForKey:url];
  if (ret) return [DKDeferred succeed:ret];
  return [[DKDeferred loadImage:url sizeTo:CGSizeMake(44, 44) cached:NO] 
          addCallback:curryTS(self, @selector(_placeLoadedImageInCache::), url)];
}

- (id)imageForURLInMemoryCache:(NSString *)url
{
  return [[self contactImageCache] objectForKey:url];
}

- (id)_placeLoadedImageInCache:(NSString *)url :(UIImage *)img
{
  if ([img isEqual:[NSNull null]])
    img = [UIImage imageNamed:@"user-70.png"];
  [[self contactImageCache] setObject:img forKey:url];
  return img;
}

#pragma mark -
#pragma mark Mostly Private Stuff

- (id)contactImageCache
{
  if (!_contactImageCache)
    _contactImageCache = [[[DataCache alloc] initWithCapacity:300] retain];
  return _contactImageCache;
}

static DKDeferredCache *__diskCache;

- (id)deferredDiskCache
{
  if (!__diskCache)
    __diskCache = [[[DKDeferredCache alloc] initWithDirectory:@"cc" maxEntries:1000 cullFrequency:20] retain];
  return __diskCache;
}

/**
 In UIKit applications, this will update the application
 icon badge for unread messages in all persistent YMNetworks combined
 */
- (void)updateUIApplicationBadge
{
  NSArray *counts = [YMNetwork pairedArraysForProperties:
                     array_(@"unseenMessageCount")];
  NSLog(@"counts %@", counts);
  int totalUnseen = 0;
  for (NSNumber *unseenCount in [counts objectAtIndex:1]) {
    totalUnseen += intv(unseenCount);
  }
  id app = [NSClassFromString(@"UIApplication") sharedApplication];
  [app setApplicationIconBadgeNumber:totalUnseen];
}

/**
 Builds a new NSMutableURLRequest with the proper headers for OAuth 1.0
 If the supplied YMUserAccount has an active network (IE: one they want
 to look at currently, the OAuth token/secret for that network will be
 used.
 */
- (id)mutableRequestWithMethod:(id)method 
                       account:(YMUserAccount *)acct 
                      defaults:(NSDictionary *)defaults
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
   [NSURL URLWithString:[[self.mountPoint description] 
                         stringByAppendingFormat:@"/%@%@", method, params]]
                          cachePolicy:NSURLRequestUseProtocolCachePolicy
                      timeoutInterval:20.0];
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
  [req setValue:header forHTTPHeaderField:@"Authorization"];
  req.HTTPShouldHandleCookies = NO;
  return req;
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
  int attachmentCount = 0;
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
