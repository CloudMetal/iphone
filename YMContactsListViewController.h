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
  NSArray *alphabet;
  NSMutableArray *alphabetGroups;
  NSString *filterText;
}

@property (nonatomic, readwrite, retain) NSString *filterText;
@property (nonatomic, readwrite, retain) YMUserAccount *userAccount;

@end
