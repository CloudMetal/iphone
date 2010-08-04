//
//  YammerAppDelegate.m
//  Yammer
//
//  Created by Samuel Sutch on 5/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "YammerAppDelegate.h"
#import "YMWebService.h"
#import "YMNetworksViewController.h"
#import "SQLiteInstanceManager.h"


@implementation YammerAppDelegate

- (void)applicationDidFinishLaunching:(UIApplication*)application
{
  [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
  
	UIWindow* window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	window.backgroundColor = [UIColor blackColor];
	[window makeKeyAndVisible];
  
  [YMUserAccount tableCheck];
  [YMGroup tableCheck];
  [YMAttachment tableCheck];
  [YMMessage tableCheck];
  [YMContact tableCheck];
  [YMNetwork tableCheck];
  
  NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
  NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
  NSString *prevVersion = [defs objectForKey:@"YMPreviousBundleVersion"];
  
  if (!prevVersion) {
    // reset when upgrading from no version
    NSLog(@"upgrading to %@", version);
    [[SQLiteInstanceManager sharedManager] executeUpdateSQL:@"DELETE FROM y_m_message;"];
    [[SQLiteInstanceManager sharedManager] executeUpdateSQL:@"DELETE FROM y_m_attachment;"];
    [[SQLiteInstanceManager sharedManager] executeUpdateSQL:@"DELETE FROM y_m_group;"];
    [[SQLiteInstanceManager sharedManager] executeUpdateSQL:@"DELETE FROM y_m_contact;"];
    [[SQLiteInstanceManager sharedManager] executeUpdateSQL:@"DELETE FROM y_m_network;"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"lastNetworkPK"];
    for (YMUserAccount *userAcct in [YMUserAccount allObjects]) {
      userAcct.activeNetworkPK = nil;
      [userAcct save];
    }
  }
  [defs setObject:version forKey:@"YMPreviousBundleVersion"];
  [defs synchronize];
  
  [[YMWebService sharedWebService] setShouldUpdateBadgeIcon:YES];
  
  UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:
                                 [[[YMNetworksViewController alloc] initWithStyle:
                                   UITableViewStylePlain] autorelease]];
  [window addSubview:nav.view];
  [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
   (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];

}

- (void)application:(UIApplication *)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
  [[YMWebService sharedWebService] setPushID:
   [[[[deviceToken description] stringByReplacingOccurrencesOfString:@"<"withString:@""] 
     stringByReplacingOccurrencesOfString:@">" withString:@""]
    stringByReplacingOccurrencesOfString:@" " withString:@""]];
}


- (void)application:(UIApplication *)application 
didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
	[[[[UIAlertView alloc]
     initWithTitle:@"Yammer" message:
     @"Could not register for push notifications." 
     delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil]
    autorelease]
   show];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
  if (PREF_KEY(@"lastNetworkPK")) {
    YMNetwork *n = (YMNetwork *)[YMNetwork findByPK:
                                 intv(PREF_KEY(@"lastNetworkPK"))];
    if (n) {
      n.unseenMessageCount = nsni(([YMMessage countByCriteria:@"WHERE network_p_k=%i AND read=0 AND (target='following' OR target='received')", n.pk]));
      [n save];
      NSLog(@"unseenMessageCount %@", n.unseenMessageCount);
    }
//    if (n) {
//      [[SQLiteInstanceManager sharedManager]
//       executeUpdateSQL:
//       [NSString stringWithFormat:
//        @"UPDATE y_m_message SET read=1 WHERE network_p_k=%i AND target='following' OR target='received'", n.pk]];
//      n.unseenMessageCount = nsni(0);
//    }
//    int c = [YMMessage countByCriteria:@"WHERE network_p_k=%i AND target='received'"];
//    int c1 = [YMMessage countByCriteria:@"WHERE network_p_k=%i AND target='following'"];
//    n.unseenMessageCount = intv(n.unseenMessageCount) - (c + c1);
  }
  [[YMWebService sharedWebService] updateUIApplicationBadge];
}

- (void)dealloc 
{
  [super dealloc];
}


@end
