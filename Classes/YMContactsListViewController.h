//
//  YMContactsListViewController.h
//  Yammer
//
//  Created by Samuel Sutch on 5/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YMTableViewController.h"

@class YMWebService, YMUserAccount;

@interface YMContactsListViewController : YMTableViewController
<UISearchBarDelegate>
{
  YMWebService *web;
  YMUserAccount *userAccount;
  NSArray *contactPKs;
  NSMutableArray *mugshots;
  NSMutableArray *names;
  NSMutableArray *ids;
  NSMutableArray *mugshotURLs;
  NSArray *alphabet;
  NSMutableArray *alphabetGroups;
  NSString *filterText;
  UISearchBar *searchBar;
  BOOL shouldHideSectionIndex;
  UIView *lastView;
  BOOL isPicker, canRemove;
  UINavigationController *rootNavController;
  NSMutableArray *selected;
  id<DKCallback> onDone;
}

@property (nonatomic, retain) id onDone;
@property (nonatomic, assign) BOOL isPicker, canRemove;
@property (nonatomic, retain) NSMutableArray *selected;

@property (nonatomic, readwrite, retain) NSString *filterText;
@property (nonatomic, readwrite, retain) YMUserAccount *userAccount;
@property (nonatomic, assign) UINavigationController *rootNavController;

@end
