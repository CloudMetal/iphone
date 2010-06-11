//
//  YMContactsListViewController.h
//  Yammer
//
//  Created by Samuel Sutch on 5/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class YMWebService, YMUserAccount;

@interface YMContactsListViewController : UITableViewController
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
  UINavigationController *rootNavController;
}

@property (nonatomic, readwrite, retain) NSString *filterText;
@property (nonatomic, readwrite, retain) YMUserAccount *userAccount;
@property (nonatomic, assign) UINavigationController *rootNavController;

@end
