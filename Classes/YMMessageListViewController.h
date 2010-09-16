//
//  YMMessageListViewController.h
//  Yammer
//
//  Created by Samuel Sutch on 5/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YMTableViewController.h"

@class YMWebService;
@class YMUserAccount;
@class YMNetwork;

@interface YMMessageListViewController : YMTableViewController {
  YMWebService *web;
  YMUserAccount *userAccount;
  YMNetwork *network;
  
  DKDeferred *loadingDeferred;
  
  // messages arrays
  NSArray *messagePKs;
  NSMutableArray *mugshots;
  NSMutableArray *reads;
  NSArray *bodies;
  NSArray *dates;
  NSArray *titles;
  NSArray *mugshotURLs;
  NSArray *hasattachments;
  NSArray *likeds;
  NSArray *followeds;
  NSArray *privates;
  NSArray *groups;
  
  // ui elements
  UIButton *moreButton;
  UIActivityIndicatorView *bottomLoadingView;
  
  NSIndexPath *selectedIndexPath;
  
  // messages state
  BOOL loadedAvatars;
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
  
  // state specific stuffs
  BOOL wasInactive;
  int previousFontSize;

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

- (void)refreshFeed:(id)sender;
- (void)refreshMessagePKs;
- (id)doReload:(id)arg;
- (void)reloadTableViewDataSource;
- (id)gotoUserIndexPath:(NSIndexPath *)indexPath sender:(id)s;
- (id)gotoMessageIndexPath:(NSIndexPath *)indexPath sender:(id)s;
- (id)gotoThreadIndexPath:(NSIndexPath *)indexPath sender:(id)s;
- (id)gotoReplyIndexPath:(NSIndexPath *)indexPath sender:(id)s;
- (id)gotoLikeIndexPath:(NSIndexPath *)companionIndexPath sender:(id)s;

@end
