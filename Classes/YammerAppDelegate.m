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
  
  [YMGroup tableCheck];
  [YMMessage tableCheck];
  [YMContact tableCheck];
  
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
  [[YMWebService sharedWebService] updateUIApplicationBadge];
  if (PREF_KEY(@"lastNetworkPK")) {
    YMNetwork *n = (YMNetwork *)[YMNetwork findByPK:
                                 intv(PREF_KEY(@"lastNetworkPK"))];
    if (n) {
      [[SQLiteInstanceManager sharedManager]
       executeUpdateSQL:
       [NSString stringWithFormat:
        @"UPDATE y_m_message SET read=1 WHERE network_p_k=%i", n.pk]];
    }
  }
}

- (void)dealloc 
{
  [super dealloc];
}


@end
