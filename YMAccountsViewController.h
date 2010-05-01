//
//  YMAccountsViewController.h
//  Yammer
//
//  Created by Samuel Sutch on 4/30/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class YMWebService;

@interface YMAccountsViewController : UITableViewController 
{
  YMWebService *web;
}

@property (nonatomic, readonly) YMWebService *web;

@end
