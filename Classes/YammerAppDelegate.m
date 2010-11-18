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
#import "YMAccountsViewController.h"
#import "YMMenuController.h"


@implementation YammerAppDelegate

- (void)applicationDidFinishLaunching:(UIApplication*)application
{
  [YMUserAccount tableCheck];
  [YMGroup tableCheck];
  [YMAttachment tableCheck];
  [YMMessage tableCheck];
  [YMContact tableCheck];
  [YMNetwork tableCheck];
  
  [DKDeferred setCache:[DKDeferredSqliteCache sharedCache]];
  
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
//    [[SQLiteInstanceManager sharedManager] executeUpdateSQL:@"DELETE FROM y_m_draft;"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"lastNetworkPK"];
    for (YMUserAccount *userAcct in [YMUserAccount allObjects]) {
      userAcct.activeNetworkPK = nil;
      [userAcct save];
    }
  } 
  if ([prevVersion isEqual:@"3.1.0.968"]) { // 3.1 => 3.1.1 upgrade path 
    [[DKDeferred cache] deleteAllValues];
  }
  if (![prevVersion isEqual:version]) {
    [[SQLiteInstanceManager sharedManager] executeUpdateSQL:@"DELETE FROM y_m_message;"];
    [[SQLiteInstanceManager sharedManager] executeUpdateSQL:@"DELETE FROM y_m_attachment;"];
    [[SQLiteInstanceManager sharedManager] executeUpdateSQL:@"DELETE FROM y_m_group;"];
  }
  
  [defs setObject:version forKey:@"YMPreviousBundleVersion"];
  [defs synchronize];
  
  [[YMWebService sharedWebService] setShouldUpdateBadgeIcon:YES];
  [[YMWebService sharedWebService] trimMessageCache];
  
  [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
  UIWindow *mainWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  
  NSLog(@"mainWindow %@", mainWindow);
  [mainWindow makeKeyAndVisible];
  
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
//    id sc = [[YMSplitViewController alloc] init];
//    YMMenuController *menu = [[[YMMenuController alloc] initWithStyle:
//                               UITableViewStyleGrouped] autorelease];
//    sc.viewControllers = array_([[[UINavigationController alloc] 
//                                  initWithRootViewController:menu] autorelease], 
//                                [menu viewControllerForSecondPane]);
//    [mainWindow addSubview:sc.view];
  } 
  else {
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:
                                    [[YMNetworksViewController alloc] initWithStyle:
                                      UITableViewStylePlain]];
    [mainWindow addSubview:nav.view];
  }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
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

- (void) applicationWillEnterForeground:(UIApplication *)application
{
  
  [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
   (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
//  this is done in the network now
//  if (PREF_KEY(@"lastNetworkPK")) {
//    YMNetwork *n = (YMNetwork *)[YMNetwork findByPK:
//                                 intv(PREF_KEY(@"lastNetworkPK"))];
//    if (n) {
//      n.unseenMessageCount = nsni(([YMMessage countByCriteria:
//       @"WHERE network_p_k=%i AND read=0 AND (target='following' OR target='received')", n.pk]));
//      [n save];
//      NSLog(@"unseenMessageCount %@", n.unseenMessageCount);
//    }
//  }
  [[YMWebService sharedWebService] trimMessageCache];
  [[YMWebService sharedWebService] updateUIApplicationBadge];
  [[DKDeferred cache] purgeMemoryCache];
}
  

- (void)applicationWillTerminate:(UIApplication *)application
{
//  this is done in the network now
//  if (PREF_KEY(@"lastNetworkPK")) {
//    YMNetwork *n = (YMNetwork *)[YMNetwork findByPK:
//                                 intv(PREF_KEY(@"lastNetworkPK"))];
//    if (n) {
//      n.unseenMessageCount = nsni(([YMMessage countByCriteria:
//       @"WHERE network_p_k=%i AND read=0 AND (target='following' OR target='received')", n.pk]));
//      [n save];
//      NSLog(@"unseenMessageCount %@", n.unseenMessageCount);
//    }
//  }
  [[YMWebService sharedWebService] updateUIApplicationBadge];
  [DKDeferred cache].forceImmediateCaching = YES;
  [[DKDeferred cache] purgeMemoryCache];
}

- (void)dealloc 
{
  [super dealloc];
}


@end
