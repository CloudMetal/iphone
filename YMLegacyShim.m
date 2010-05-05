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
#import "NSString-SQLiteColumnName.h"

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

- (id)_cleanupBeforeLoggingOutAccount:(YMUserAccount *)acct
{
  NSNumber *curNetworkID = (NSNumber *)[LocalStorage getSetting:@"current_network_id"];
  if (curNetworkID != nil) {
    NSArray *networks = [YMNetwork findByCriteria:@"WHERE %@=%i", 
                         [@"userAccountPK" stringAsSQLColumnName], acct.pk];
    YMNetwork *network;
    BOOL broken = NO;
    for (network in networks) {
      if ([network.networkID isEqualToNumber:curNetworkID]) {
        broken = YES;
        break;
      }
    }
    if (broken) {
      [LocalStorage removeFile:[APIGateway push_file]];
      [LocalStorage removeFile:SETTINGS];
//      [LocalStorage saveSetting:@"current_network_id" value:nil];
//      [LocalStorage saveSetting:@"last_in" value:nil];
      [LocalStorage deleteAccountInfo];
      YammerAppDelegate *del = (YammerAppDelegate *)[[UIApplication sharedApplication] delegate];
      del.network_id = nil;
      del.dateOfSelection = nil;
      del.network_name = nil;
    }
  }
  return acct;
}

- (id)_cleanupMultipleAccountsUpgrade
{
  [LocalStorage removeFile:[APIGateway push_file]];
  [LocalStorage removeFile:SETTINGS];
  [LocalStorage deleteAccountInfo];
  YammerAppDelegate *del = (YammerAppDelegate *)[[UIApplication sharedApplication] delegate];
  del.network_id = nil;
  del.dateOfSelection = nil;
  del.network_name = nil;
  return nil;
}

@end
