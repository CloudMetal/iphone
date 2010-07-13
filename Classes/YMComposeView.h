//
//  YMComposeView.h
//  Yammer
//
//  Created by Samuel Sutch on 5/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class YMMessageTextView;

@interface YMComposeView : UIView <UITextViewDelegate> {
  IBOutlet YMMessageTextView *messageTextView;
  IBOutlet UILabel *toLabel;
  IBOutlet UILabel *toTargetLabel;
  IBOutlet UIToolbar *actionBar;
  IBOutlet UIBarButtonItem *kb, *photo, *at, *hash;
  BOOL onHash, onUser, onPartial;
  IBOutlet UITableView *tableView;
  IBOutlet UIActivityIndicatorView *activity;
  id<DKCallback> onUserInputsHash, onUserInputsAt, onPartialWillClose, onUserPhoto;
  IBOutlet UIImagePickerController *imagePicker;
}

@property(nonatomic, readwrite, retain) id<DKCallback> onUserInputsHash, onUserInputsAt, onPartialWillClose, onUserPhoto;
@property(nonatomic, readwrite, retain) YMMessageTextView *messageTextView;
@property(nonatomic, readwrite, retain) UILabel *toLabel, *toTargetLabel;
@property(nonatomic, retain) UIToolbar *actionBar;
@property(nonatomic, retain) UITableView *tableView;
@property(nonatomic, assign) BOOL onHash, onUser, onPhoto, onPartial;
@property(nonatomic, retain) UIActivityIndicatorView *activity;
@property(nonatomic, retain) UIImagePickerController *imagePicker;

- (void)performAutocomplete:(NSString *)str isAppending:(BOOL)appending;

- (IBAction)photo:(id)s;
- (IBAction)kb:(id)s;
- (IBAction)at:(id)s;
- (IBAction)hash:(id)s;
- (void)revealPartial;
- (void)hidePartial;

@end
