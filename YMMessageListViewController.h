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
  NSString *targetID;
  NSString *olderThan;
  NSString *newerThan;
  NSNumber *threaded;
  NSArray *messagePKs;
  id lastView;
  BOOL loadedAvatars;
  NSMutableArray *mugshots;
}

@property(nonatomic, readwrite, retain) YMUserAccount *userAccount;
@property(nonatomic, readwrite, retain) NSString *target;
@property(nonatomic, readwrite, retain) NSString *targetID;
@property(nonatomic, readwrite, retain) NSString *olderThan;
@property(nonatomic, readwrite, retain) NSString *newerThan;
@property(nonatomic, readwrite, retain) NSNumber *threaded;

@end
