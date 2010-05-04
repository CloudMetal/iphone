//
//  YMLegacyAppShim.m
//  Yammer
//
//  Created by Samuel Sutch on 5/3/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "YMLegacyShim.h"
#import "YMNetwork.h"
#import "LocalStorage.h"
#import "APIGateway.h"
#import "YammerAppDelegate.h"
#import "YMUserAccount.h"

YMLegacyShim *__sharedLegacyShim = nil;


@implementation YMLegacyShim

+ (id)sharedShim
{
  if (!__sharedLegacyShim)
    __sharedLegacyShim = [[[[self class] alloc] init] retain];
  return __sharedLegacyShim;
}

- (id)_legacyEnterAppWithNetwork:(YMNetwork *)network
{  
  YMUserAccount *acct = (YMUserAccount *)[YMUserAccount findByPK:intv(network.userAccountPK)];
  
  NSString *pushSettingsJSON = [LocalStorage getFile:[APIGateway push_file_with_id:intv(network.networkID)]];
  
  [LocalStorage saveAccessToken:
   [NSString stringWithFormat:@"oauth_token=%@&oauth_token_secret=%@",
    acct.wrapToken, acct.wrapSecret]];
  
  [APIGateway usersCurrent:@"silent"];
  [APIGateway networksCurrent:@"silent"];
  
  YammerAppDelegate *del = (YammerAppDelegate *)[[UIApplication sharedApplication] delegate];
  del.network_id = network.networkID;
  del.dateOfSelection = [[NSDate date] description];
  del.network_name = network.name;
  [LocalStorage saveAccessToken:[NSString stringWithFormat:
                                 @"oauth_token=%@&oauth_token_secret=%@",
                                 network.token, network.secret]];
  [LocalStorage saveSetting:@"current_network_id" value:network.networkID];
  [LocalStorage saveSetting:@"last_in" value:@"network"];
  
  if (del.pushToken && [APIGateway sendPushToken:del.pushToken] && pushSettingsJSON != nil) {
    NSMutableDictionary *pushSettings = [pushSettingsJSON JSONValue];
    NSMutableDictionary *existingPushSettings = [APIGateway pushSettings:@"silent"];
    if (existingPushSettings) {
      [APIGateway updatePushSettingsInBulk:[existingPushSettings objectForKey:@"id"] pushSettings:pushSettings];
    }
    [LocalStorage removeFile:[APIGateway push_file]];
  }
  
  return network;
}

@end
