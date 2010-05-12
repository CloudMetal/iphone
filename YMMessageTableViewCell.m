//
//  YMMessageTableViewCell.m
//  Yammer
//
//  Created by Samuel Sutch on 5/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "YMMessageTableViewCell.h"
#import <QuartzCore/QuartzCore.h>
#import "UIColor+Extensions.h"


@implementation YMMessageTableViewCell

@synthesize avatarImageView, titleLabel, dateLabel, bodyLabel;

//- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
//  if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
//    se
//  }
//  return self;
//}

- (id)initWithCoder:(NSCoder *)aDecoder
{
  if ((self = [super initWithCoder:aDecoder])) {
    avatarImageView.layer.cornerRadius = 2;
    avatarImageView.layer.borderColor = [UIColor colorWithWhite:.6 alpha:1].CGColor;
    avatarImageView.layer.borderWidth = 1;
  }
  return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (void)dealloc {
    [super dealloc];
}


@end
