//
//  ECLoginViewController.h
//  Yammer
//
//  Created by Samuel Sutch on 4/30/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YMTableViewController.h"

@class YMWebService;

@interface YMThisIsWhereIWantToGoView : UIView <ActionTableViewHeader, UITextFieldDelegate>
{
  UITextField *theTextField;
  BOOL isFlipped;
  BOOL hasFlipped;
}

@property BOOL isFlipped;
@property (retain) UITextField *theTextField;

@end


@interface YMLoginViewController : YMTableViewController
<UITextFieldDelegate>
{
  YMWebService *web;
  BOOL emailAlreadyBecameFirstResponder;
}

@property (nonatomic, readonly) YMWebService *web;

- (void)performLoginWithUsername:(id)username password:(id)password;

@end
