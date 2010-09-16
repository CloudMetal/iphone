//
//  YMComposeViewController.h
//  Yammer
//
//  Created by Samuel Sutch on 5/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YMDraft.h"
#import "MBProgressHUD.h"

@class YMWebService;
@class YMUserAccount;
@class YMGroup, YMContact, YMMessage, YMNetwork;
@class YMMessageTextView;
@class YMComposeView;


@interface YMComposeViewController : UIViewController 
<UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, UIActionSheetDelegate,
UIImagePickerControllerDelegate, UINavigationControllerDelegate, UISearchBarDelegate,
MBProgressHUDDelegate> 
{
  YMWebService *web;
  YMUserAccount *userAccount;
  YMNetwork *network;
  YMMessageTextView *textView;
  YMMessage *inReplyTo;
  YMGroup *inGroup;
  YMContact *directTo;
  IBOutlet UITableView *autocompleteTable;
  NSArray *usernames;
  NSArray *fullNames;
  NSArray *hashes;
  NSMutableArray *searchIndexSet;
  BOOL gotPartialWillCloseMessage;
  YMComposeView *composeView;
  NSMutableArray *attachments;
  BOOL onPhoto, onDrafts;
  NSIndexPath *hmm;
  id<DKCallback> onCompleteSend;
  BOOL searchBarWillClear;
  YMDraft *draft;
  MBProgressHUD *HUD;
  NSString *text;
}

@property (nonatomic, retain) YMDraft *draft;
@property (nonatomic, retain) id<DKCallback> onCompleteSend;
@property (nonatomic, readwrite, retain) YMUserAccount *userAccount;
@property (nonatomic, readwrite, retain) YMGroup *inGroup;
@property (nonatomic, readwrite, retain) YMNetwork *network;
@property (nonatomic, readwrite, retain) YMMessage *inReplyTo;
@property (nonatomic, readwrite, retain) YMContact *directTo;
@property (nonatomic, readonly) UIImagePickerController *imagePicker;

- (void)showFromController:(UIViewController *)controller animated:(BOOL)animated;
- (void)addAttachment:(id)s;

@end
