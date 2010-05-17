//
//  YMMessageDetailView.h
//  Yammer
//
//  Created by Samuel Sutch on 5/14/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class YMMessage;
@class YMWebService;
@class YMContact;

@interface YMMessageDetailView : UIView {
  IBOutlet UIButton *userButton, *likeButton, *threadButton,
  *replyButton, *bookmarkButton, *attachmentsButton, *sendButton, *followButton;
  IBOutlet UILabel *titleLabel, *dateLabel;
  IBOutlet UIImageView *avatarImageView, *actionsBackgroundView;
  IBOutlet UIWebView *messageBodyWebView;
  IBOutlet UIViewController *parentViewController;
  YMMessage *message;
  YMContact *fromContact;
  YMContact *toContact;
  YMWebService *web;
}

@property(nonatomic, readwrite, retain) YMMessage *message;
@property(nonatomic, readonly) NSString *htmlValue;
@property(nonatomic, assign) UIViewController *parentViewController;

- (IBAction)user:(id)sender;
- (IBAction)like:(id)sender;
- (IBAction)thread:(id)sender;
- (IBAction)reply:(id)sender;
- (IBAction)bookmark:(id)sender;
- (IBAction)attachments:(id)sender;
- (IBAction)send:(id)sender;
- (IBAction)follow:(id)sender;

@end
