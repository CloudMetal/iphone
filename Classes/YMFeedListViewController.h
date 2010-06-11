//
//  YMFeedListViewController.h
//  Yammer
//
//  Created by Samuel Sutch on 5/25/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class YMWebService;
@class YMUserAccount;
@class YMNetwork;

@interface YMFeedListViewController : UITableViewController
{
  YMWebService *web;
  YMUserAccount *userAccount;
  YMNetwork *network;
  NSArray *feeds;
  NSMutableArray *mugshots;
  BOOL didUpdateSubscriptions;
}

@property(nonatomic, readwrite, retain) YMUserAccount *userAccount;
@property(nonatomic, readwrite, retain) YMNetwork *network;

@end
