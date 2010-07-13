//
//  YMNetworksViewController.h
//  Yammer
//
//  Created by Samuel Sutch on 4/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class YMWebService;
@class YMNetwork, YMUserAccount;
@class YMMessageListViewController;
@class YMContactsListViewController;
@class YMFeedListViewController;


@interface YMNetworksViewController : UITableViewController <UIAlertViewDelegate>
{
  YMWebService *web;
  UITabBarController *tabs;
  YMContactsListViewController *directoryController;
  YMMessageListViewController *myMessagesController;
  YMMessageListViewController *receivedMessagesController;
  YMFeedListViewController *feedsController;
  BOOL animateNetworkTransition;
  NSArray *networkPKs;
  
  YMNetwork *scrape_network;
  YMUserAccount *scrape_acct;
}

@property (nonatomic, readonly) YMWebService *web;

- (void)refreshNetworks;
- (void)gotoNetwork:(YMNetwork *)network;
- (void)doContactScrape:(YMUserAccount *)_acct network:(YMNetwork *)_network;

@end
