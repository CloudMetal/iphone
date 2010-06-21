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

@interface YMMessageDetailFooter : UIView
{
  id<DKCallback> onUser, onTag, onLike, onThread, onReply, 
  onBookmark, onAttachments, onSend, onFollow;
  IBOutlet UIButton *userButton, *likeButton, *threadButton,
  *replyButton, *bookmarkButton, *attachmentsButton, *sendButton, *followButton;
}

@property(nonatomic, readwrite, retain) id<DKCallback> 
onUser, onTag, onLike, onThread, onReply, onBookmark, 
onAttachments, onSend, onFollow;
@property(nonatomic, assign) UIButton *likeButton;

- (IBAction)user:(id)sender;
- (IBAction)like:(id)sender;
- (IBAction)thread:(id)sender;
- (IBAction)reply:(id)sender;
- (IBAction)bookmark:(id)sender;
- (IBAction)attachments:(id)sender;
- (IBAction)send:(id)sender;
- (IBAction)follow:(id)sender;

@end


@interface YMMessageDetailHeader : UIView
{
  IBOutlet UIImageView *avatarImageView;
  IBOutlet UILabel *titleLabel, *dateLabel, *postedInLabel;
  IBOutlet UIImageView *lockImageView, *backgroundImageView;
}

@property(nonatomic, readwrite, retain) UIImageView *avatarImageView, *lockImageView, *backgroundImageView;
@property(nonatomic, readwrite, retain) UILabel *titleLabel, *dateLabel, *postedInLabel;

@end


@interface YMMessageDetailView : UITableViewCell <UIWebViewDelegate> {
  IBOutlet UIWebView *messageBodyWebView;
  IBOutlet UIViewController *parentViewController;
  YMMessage *message;
  YMContact *fromContact;
  YMContact *toContact;
  BOOL direct;
  YMWebService *web;
  IBOutlet YMMessageDetailFooter *footerView;
  IBOutlet YMMessageDetailHeader *headerView;
  id<DKCallback> onFinishLoad;
}

@property(nonatomic, readwrite, retain) id<DKCallback> onFinishLoad;
@property(nonatomic, readwrite, retain) YMMessageDetailFooter *footerView;
@property(nonatomic, readwrite, retain) YMMessageDetailHeader *headerView;
@property(nonatomic, readwrite, retain) YMMessage *message;
@property(nonatomic, readonly) NSString *htmlValue;
@property(nonatomic, assign) UIViewController *parentViewController;

@end
