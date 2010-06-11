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
  UIImage *avatar;
  UIImageView *imageView;
  BOOL unread;
  BOOL hasAttachments;
  BOOL liked;
  BOOL following;
}

@property(nonatomic, assign) BOOL unread, hasAttachments, liked, following;
@property(nonatomic, copy) NSString *title, *body, *date;
@property(nonatomic, retain) UIImage *avatar;

- (void)drawContentView:(CGRect)r;

@end
