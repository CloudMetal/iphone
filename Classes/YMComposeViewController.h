//
//  YMComposeViewController.h
//  Yammer
//
//  Created by Samuel Sutch on 5/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class YMWebService;
@class YMUserAccount;
@class YMGroup, YMContact, YMMessage, YMNetwork;
@class YMMessageTextView;
@class YMComposeView;

@interface YMComposeViewController : UIViewController 
<UITableViewDataSource, UITableViewDelegate, UITextViewDelegate> {
  YMWebService *web;
  YMUserAccount *userAccount;
  YMNetwork *network;
  YMMessageTextView *textView;
  YMMessage *inReplyTo;
  YMGroup *inGroup;
  YMContact *directTo;
  IBOutlet UITableView *autocompleteTable;
  NSArray *usernames;
  NSArray *hashes;
  BOOL gotPartialWillCloseMessage;
}

@property (nonatomic, readwrite, retain) YMUserAccount *userAccount;
@property (nonatomic, readwrite, retain) YMGroup *inGroup;
@property (nonatomic, readwrite, retain) YMNetwork *network;
@property (nonatomic, readwrite, retain) YMMessage *inReplyTo;
@property (nonatomic, readwrite, retain) YMContact *directTo;

- (void)showFromController:(UIViewController *)controller animated:(BOOL)animated;

@end
