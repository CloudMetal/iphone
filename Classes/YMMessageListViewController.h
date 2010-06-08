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
@class YMNetwork;

@interface YMMessageListViewController : UITableViewController {
  YMWebService *web;
  YMUserAccount *userAccount;
  YMNetwork *network;
  
  // messages arrays
  NSArray *messagePKs;
  NSMutableArray *mugshots;
  NSMutableArray *reads;
  NSArray *bodies;
  NSArray *dates;
  NSArray *titles;
  NSArray *mugshotURLs;
  
  // ui elements
  UIButton *refreshButton;
  UIButton *moreButton;
  UILabel *totalLoadedLabel;
  
  NSIndexPath *selectedIndexPath;
  
  // messages state
  NSDate *lastUpdated;
  NSMutableIndexSet *newlyReadMessageIndexes;
  BOOL shouldScrollToTop;
  int limit;
  BOOL viewHasAppeared;
  BOOL shouldUpdateBadge;
  
  NSString *target;
  NSNumber *targetID;
  NSNumber *olderThan;
  NSNumber *newerThan;
  NSNumber *threaded;
  NSNumber *remainingUnseenItems;
  NSNumber *lastLoadedMessageID;
  NSNumber *lastSeenMessageID;
}

@property(nonatomic, assign) int limit;
@property(nonatomic, readwrite, retain) NSIndexPath *selectedIndexPath;
@property(nonatomic, readwrite, retain) YMUserAccount *userAccount;
@property(nonatomic, readwrite, retain) YMNetwork *network;
@property(nonatomic, readwrite, copy) NSString *target;
@property(nonatomic, readwrite, copy) NSNumber *targetID;
@property(nonatomic, readwrite, copy) NSNumber *olderThan;
@property(nonatomic, readwrite, copy) NSNumber *newerThan;
@property(nonatomic, readwrite, copy) NSNumber *threaded;
@property(nonatomic, readwrite, copy) NSNumber *remainingUnseenItems;
@property(nonatomic, readwrite, copy) NSNumber *lastLoadedMessageID, *lastSeenMessageID;
@property(nonatomic, assign) BOOL loadedAvatars, shouldUpdateBadge;

- (id)doReload:(id)arg;

@end
