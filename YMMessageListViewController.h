//
//  YMMessageListViewController.h
//  Yammer
//
//  Created by Samuel Sutch on 5/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class YMWebService;
@class YMUserAccount;

@interface YMMessageListViewController : UITableViewController {
  YMWebService *web;
  YMUserAccount *userAccount;
  NSString *target;
  NSNumber *targetID;
  NSNumber *olderThan;
  NSNumber *newerThan;
  NSNumber *threaded;
  NSArray *messagePKs;
  id lastView;
  BOOL loadedAvatars;
  NSMutableArray *mugshots;
  NSMutableArray *reads;
  NSArray *bodies;
  NSArray *dates;
  NSIndexPath *selectedIndexPath;
  BOOL shouldRearrangeWhenDeselecting;
  NSArray *titles;
  NSArray *mugshotURLs;
  UIButton *refreshButton;
  UIButton *moreButton;
  UILabel *totalLoadedLabel;
  NSDate *lastUpdated;
  BOOL shouldScrollToTop;
  int limit;
  UINavigationController *rootNavController;
  NSMutableIndexSet *newlyReadMessageIndexes;
  BOOL viewHasAppeared;
  BOOL shouldUpdateBadge;
}

@property(nonatomic, assign) UINavigationController *rootNavController;
@property(nonatomic, assign) int limit;
@property(nonatomic, readwrite, retain) NSIndexPath *selectedIndexPath;
@property(nonatomic, readwrite, retain) YMUserAccount *userAccount;
@property(nonatomic, readwrite, copy) NSString *target;
@property(nonatomic, readwrite, copy) NSNumber *targetID;
@property(nonatomic, readwrite, copy) NSNumber *olderThan;
@property(nonatomic, readwrite, copy) NSNumber *newerThan;
@property(nonatomic, readwrite, copy) NSNumber *threaded;
@property(nonatomic, assign) BOOL loadedAvatars, shouldUpdateBadge;

- (id)doReload:(id)arg;

@end
