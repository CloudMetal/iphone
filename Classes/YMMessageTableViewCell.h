//
//  YMMessageTableViewCell.h
//  Yammer
//
//  Created by Samuel Sutch on 5/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface YMMessageTableViewCell : UITableViewCell {
  IBOutlet UIImageView *avatarImageView;
  IBOutlet UILabel *titleLabel;
  IBOutlet UILabel *bodyLabel;
  IBOutlet UILabel *dateLabel;
}

@property (nonatomic, readwrite, assign) UIImageView *avatarImageView;
@property (nonatomic, readwrite, assign) UILabel *titleLabel, *bodyLabel, *dateLabel;

@end

@interface YMFastMessageTableViewCell : UITableViewCell
{
  UIView *contentView;
  NSString *title;
  NSString *body;
  NSString *date;
  NSString *group;
  UIImage *avatar;
  UIImageView *imageView;
  BOOL unread;
  BOOL hasAttachments;
  BOOL liked;
  BOOL following;
  BOOL isPrivate;
  
  BOOL trackingMovement;
  CGPoint movementTrackFirstTouch;
  SEL swipeSelector;
  id swipeTarget;
}

@property(nonatomic, assign) BOOL unread, hasAttachments, liked, following, isPrivate;
@property(nonatomic, assign) SEL swipeSelector;
@property(nonatomic, assign) id swipeTarget;
@property(nonatomic, copy) NSString *title, *body, *date, *group;
@property(nonatomic, retain) UIImage *avatar;

- (void)drawContentView:(CGRect)r;
- (BOOL)detectSwipeWithTouch:(UITouch *)t;
+ (void)updateFontSize;

@end
