//
//  YMNetworkTableViewCell.m
//  Yammer
//
//  Created by Samuel Sutch on 5/3/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "YMNetworkTableViewCell.h"
#import "UIColor+Extensions.h"
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>


@implementation YMNetworkTableViewCell

@synthesize unreadLabel;

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)reuseIdentifier
{
  if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
    self.unreadLabel = [[[UILabel alloc] initWithFrame:CGRectMake(240, 8, 50, 28)] autorelease];
    self.unreadLabel.layer.cornerRadius = 10;
    self.unreadLabel.backgroundColor = [UIColor colorWithHexString:@"8bacd0"];
    self.unreadLabel.textAlignment = UITextAlignmentCenter;
    self.unreadLabel.contentMode = UIViewContentModeCenter;
    self.unreadLabel.textColor = [UIColor whiteColor];
    self.unreadLabel.font = [UIFont boldSystemFontOfSize:17];
    self.unreadLabel.text = @"60+";
    [self addSubview:self.unreadLabel];
  }
  return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
  [super setSelected:selected animated:animated];
}


- (void)dealloc
{
  self.unreadLabel = nil;
  [super dealloc];
}

@end
