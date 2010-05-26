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

}


- (void)dealloc {
    [super dealloc];
}


@end


@interface YMFastTableViewCellView : UIView
//{
//  UIImageView *imageView;
//}

//@property(nonatomic, readwrite, retain) UIImageView *imageView;

@end

@implementation YMFastTableViewCellView

//@synthesize imageView;

- (void)drawRect:(CGRect)r
{
  [(id)[self superview] drawContentView:r];
}

@end

static UIFont *titleFont = nil;
static UIFont *bodyFont = nil;
static UIColor *bodyColor = nil;
static UIColor *dateColor = nil;
static UIImage *backgroundImage = nil;
static UIColor *borderColor;


@implementation YMFastMessageTableViewCell

@synthesize title, body, date, avatar;

+ (void)initialize
{
  if (self = [YMFastMessageTableViewCell class]) {
    titleFont = [[UIFont boldSystemFontOfSize:13] retain];
    bodyFont = [[UIFont systemFontOfSize:11] retain];
    bodyColor = [[UIColor colorWithWhite:.6 alpha:1] retain];
    dateColor = [[UIColor colorWithRed:.2 green:.55 blue:.7 alpha:1] retain];
    backgroundImage = [[UIImage imageNamed:@"msg-bg.png"] retain];
    borderColor = [[UIColor colorWithWhite:.5 alpha:1] retain];
  }
}

- (id)initWithFrame:(CGRect)f reuseIdentifier:(NSString *)reuseIdent
{
  if ((self = [super initWithFrame:f reuseIdentifier:reuseIdent])) {
    contentView = [[YMFastTableViewCellView alloc] initWithFrame:CGRectZero];
    contentView.opaque = YES;
    [self addSubview:contentView];
    [contentView release];
    
    imageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 8, 44, 44)];
    imageView.layer.masksToBounds = YES;
    imageView.layer.borderColor = borderColor.CGColor;
    imageView.layer.cornerRadius = 3;
    imageView.layer.borderWidth = 1;
    imageView.contentMode = UIViewContentModeScaleToFill;
    imageView.backgroundColor = [UIColor clearColor];
    [contentView addSubview:imageView];
    [imageView release];
    
  }
  return self;
}

- (void)setBody:(NSString *)b
{
  [body release];
  body = [b copy];
  [self setNeedsDisplay];
}

- (void)setDate:(NSString *)d
{
  [date release];
  date = [d copy];
  [self setNeedsDisplay];
}

- (void)setTitle:(NSString *)t
{
  [title release];
  title = [t copy];
  [self setNeedsDisplay];
}

- (void)setAvatar:(UIImage *)a
{
  imageView.image = a;
  [self setNeedsDisplay];
}

- (void)dealloc
{
  [body release];
  [date release];
  [title release];
  [avatar release];
  [super dealloc];
}

- (void)setFrame:(CGRect)f
{
	[super setFrame:f];
	CGRect b = [self bounds];
	b.size.height -= 1; // leave room for the seperator line
	[contentView setFrame:b];
  [self setNeedsDisplay];
}

- (void)setNeedsDisplay
{
	[super setNeedsDisplay];
	[contentView setNeedsDisplay];
}

- (void)drawContentView:(CGRect)r
{
  CGContextRef ctx = UIGraphicsGetCurrentContext();
  
  [[UIColor whiteColor] set];
  CGContextFillRect(ctx, r);
  
  [backgroundImage drawInRect:r];
  
  CGRect titleSize = CGRectMake(62, 3, r.size.width - 137.0, 21);
  CGRect bodySize = CGRectMake(62, 24.0, r.size.width - 72.0, r.size.height - 32.0);
  CGRect dateLabel = CGRectMake(r.size.width - 73.0, 3, 63, 21);
  
  [[UIColor blackColor] set];
  [title drawInRect:titleSize withFont:titleFont 
      lineBreakMode:UILineBreakModeTailTruncation];
  
  [bodyColor set];
  [body drawInRect:bodySize withFont:bodyFont 
     lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentLeft];
  
  [dateColor set];
  [date drawInRect:dateLabel withFont:titleFont 
     lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentRight];
  
  [imageView.layer drawInContext:ctx];
}

@end
