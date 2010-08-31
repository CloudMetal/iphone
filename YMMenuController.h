//
//  YMMenuController.h
//  Yammer
//
//  Created by Samuel Sutch on 8/18/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class YMWebService, YMNetwork, YMUserAccount, YMNetworksViewController,
       YMMessageListViewController, YMContactsListViewController;

@interface YMMenuController : UITableViewController <UIPopoverControllerDelegate>
{
  NSArray *builtins;
  NSMutableArray *feeds;
  YMNetwork *network;
  YMUserAccount *userAccount;
  YMWebService *web;
  YMNetworksViewController *networksController;
  UINavigationController *networksNavController;
  YMMessageListViewController *messagesController;
  UINavigationController *messagesNavController;
  UIPopoverController *networksPopController;
  NSIndexPath *activeFeed;
  YMContactsListViewController *contactsController;
  UINavigationController *contactsNavController;
}

@property (nonatomic, retain) YMNetwork *network;
@property (nonatomic, retain) YMUserAccount *userAccount;
@property (nonatomic, retain) UINavigationController *networksNavController;

- (UIViewController *)viewControllerForSecondPane;
- (void)refreshFeeds;

@end
