//
//  YMNetworksViewController.h
//  Yammer
//
//  Created by Samuel Sutch on 4/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YMTableViewController.h"

@class YMWebService;
@class YMNetwork, YMUserAccount;
@class YMMessageListViewController;
@class YMContactsListViewController;
@class YMFeedListViewController;
@class YMSettingsViewController, YMAccountsViewController;


@interface YMNetworksViewController : UITableViewController <UIAlertViewDelegate>
{
  YMWebService *web;
  UITabBarController *tabs;
  YMContactsListViewController *directoryController;
  YMMessageListViewController *myMessagesController;
  YMMessageListViewController *receivedMessagesController;
  YMFeedListViewController *feedsController;
  YMSettingsViewController *settingsController;
  YMAccountsViewController *accountsController;
  BOOL animateNetworkTransition;
  NSArray *networkPKs;
  
  YMNetwork *scrape_network;
  YMUserAccount *scrape_acct;
  UITableViewStyle style;
  id<DKCallback> onChooseNetwork;
  BOOL updatingNetworks;
}

@property (nonatomic, retain) id<DKCallback> onChooseNetwork;
@property (nonatomic, readonly) YMWebService *web;

- (void)refreshNetworks;
- (void)gotoNetwork:(YMNetwork *)network;
- (void)doContactScrape;

@end
