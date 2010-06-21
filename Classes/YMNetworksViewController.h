//
//  YMNetworksViewController.h
//  Yammer
//
//  Created by Samuel Sutch on 4/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class YMWebService;
@class YMNetwork;
@class YMMessageListViewController;
@class YMContactsListViewController;
@class YMFeedListViewController;


@interface YMNetworksViewController : UITableViewController
{
  YMWebService *web;
  UITabBarController *tabs;
  YMContactsListViewController *directoryController;
  YMMessageListViewController *myMessagesController;
  YMMessageListViewController *receivedMessagesController;
  YMFeedListViewController *feedsController;
  BOOL animateNetworkTransition;
  NSArray *networkPKs;
}

@property (nonatomic, readonly) YMWebService *web;

- (void)refreshNetworks;
- (void)gotoNetwork:(YMNetwork *)network;

@end
