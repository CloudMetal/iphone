//
//  ECLoginViewController.h
//  Yammer
//
//  Created by Samuel Sutch on 4/30/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class YMWebService;

@interface YMLoginViewController : UITableViewController
<UITextFieldDelegate>
{
  YMWebService *web;
}

@property (nonatomic, readonly) YMWebService *web;

- (void)performLoginWithUsername:(id)username password:(id)password;

@end
