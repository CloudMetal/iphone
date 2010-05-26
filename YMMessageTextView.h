//
//  YMMessageTextView.h
//  Yammer
//
//  Created by Samuel Sutch on 5/20/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface YMMessageTextView : UITextView {
  NSArray *keyboardViews;
  IBOutlet UITableView *userTableView;
  IBOutlet UITableView *hashTableView;
  CGRect keyboardRect;
  CGRect subKeyboardRect;
  IBOutlet NSObject<UITableViewDataSource, UITableViewDelegate> *userDataSource;
  IBOutlet NSObject<UITableViewDataSource, UITableViewDelegate> *hashDataSource;
  UIView *keyboardContainer;
  UIWindow *kbWindow;
  BOOL onAt;
  BOOL onHash;
  BOOL autocompleteEnabled;
  BOOL onPartial;
  CGPoint kbButtonCenter;
  CGPoint hashButtonCenter;
  CGPoint atButtonCenter;
}

@property (nonatomic, readwrite, retain) UITableView *userTableView, *hashTableView;
@property (nonatomic, readwrite, retain) NSObject<UITableViewDataSource, UITableViewDelegate>
  *userDataSource, *hashDataSource;
@property (nonatomic, readonly) BOOL autocompleteEnabled, onPartial;

- (void)doKeyboard:(id)sender;
- (void)doAt:(id)sender;
- (void)doHash:(id)sender;

- (void)revealPartialAt:(id)sender;
- (void)revealPartialHash:(id)sender;

- (void)hidePartials:(id)sender;

@end
