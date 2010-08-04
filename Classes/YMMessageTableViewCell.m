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
static UIFont *groupFont = nil;
static UIColor *bodyColor = nil;
static UIFont *dateFont = nil;
static UIColor *groupColor = nil;
static UIColor *dateColor = nil;
static UIImage *backgroundImage = nil;
static UIColor *borderColor = nil;
static UIImage *unreadBackgroundImage = nil;
static UIImage *selectedBackgroundImage = nil;
static UIImage *smallLikeImage = nil;
static UIImage *smallAttachmentImage = nil;
static UIImage *smallFollowingImage = nil;
static UIImage *smallPrivateImage = nil;


@implementation YMFastMessageTableViewCell

@synthesize title, body, date, avatar, unread, hasAttachments, liked, following, isPrivate, group;

+ (void)initialize
{
  if (self = [YMFastMessageTableViewCell class]) {
    titleFont = [[UIFont boldSystemFontOfSize:13] retain];
    bodyFont = [[UIFont systemFontOfSize:13] retain];
    bodyColor = [[UIColor colorWithWhite:.15 alpha:1] retain];
    dateFont = [[UIFont systemFontOfSize:13] retain];
    groupFont = [[UIFont systemFontOfSize:12] retain];
    groupColor = [[UIColor colorWithWhite:.3 alpha:1] retain];
    dateColor = [[UIColor colorWithRed:(65.0/255.0) green:(87.0/255.0) blue:(143.0/255.0) alpha:1] retain]; // 65 87 143
    backgroundImage = [[UIImage imageNamed:@"msg-bg.png"] retain];
    borderColor = [[UIColor colorWithWhite:.5 alpha:1] retain];
    unreadBackgroundImage = [[UIImage imageNamed:@"unread-msg-bg.png"] retain];
    selectedBackgroundImage = [[UIImage imageNamed:@"selected-msg-bg.png"] retain];
    smallLikeImage = [[UIImage imageNamed:@"liked-tiny.png"] retain];
    smallAttachmentImage = [[UIImage imageNamed:@"paperclip-tiny.png"] retain];
    smallFollowingImage = [[UIImage imageNamed:@"following-tiny.png"] retain];
    smallPrivateImage = [[UIImage imageNamed:@"lock.png"] retain];
  }
}

+ (void)updateFontSize
{
  [titleFont release];
  [bodyFont release];
  [dateFont release];
  [groupFont release];
  int fontSize = 13;
  id p = PREF_KEY(@"fontsize");
  if (p) fontSize = intv(p);
  titleFont = [[UIFont boldSystemFontOfSize:fontSize] retain];
  bodyFont = [[UIFont systemFontOfSize:fontSize] retain];
  dateFont = [[UIFont systemFontOfSize:fontSize] retain];
  groupFont = [[UIFont systemFontOfSize:fontSize - 1] retain];
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
    
    unread = NO;
    liked = NO;
    hasAttachments = NO;
    following = NO;
    isPrivate = NO;
  }
  return self;
}

- (void)setIsPrivate:(BOOL)p
{
  isPrivate = p;
  [self setNeedsDisplay];
}

- (void)setLiked:(BOOL)l
{
  liked = l;
  [self setNeedsDisplay];
}

- (void)setHasAttachments:(BOOL)a
{
  hasAttachments = a;
  [self setNeedsDisplay];
}

- (void)setFollowing:(BOOL)f
{
  following = f;
  [self setNeedsDisplay];
}

- (void)setUnread:(BOOL)u
{
  unread = u;
  [self setNeedsDisplay];
}

- (void) setSelected:(BOOL)s
{
  [super setSelected:s];
  [self setNeedsDisplay];
}

- (void)setBody:(NSString *)b
{
  [body release];
  body = [b retain];
  [self setNeedsDisplay];
}

- (void)setDate:(NSString *)d
{
  [date release];
  date = [d retain];
  [self setNeedsDisplay];
}

- (void)setTitle:(NSString *)t
{
  [title release];
  title = [t retain];
  [self setNeedsDisplay];
}

- (void)setGroup:(NSString *)g
{
  [group release];
  group = [g retain];
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
  [group release];
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
  
  [(self.selected ? selectedBackgroundImage : 
    (unread ? unreadBackgroundImage : backgroundImage)) drawInRect:r];
  
  CGRect titleSize = CGRectMake(62, 4, r.size.width - 137.0 
                                - (hasAttachments ? 10.0 : 0) 
                                - (isPrivate ? 14.0 : 0) 
                                - (liked ? 15.0 : 0), 
                                21);
  CGRect bodySize = CGRectMake(62, 23.0, r.size.width - 72.0, r.size.height - 32.0);
  CGRect dateLabel = CGRectMake(r.size.width - 73.0, 4, 63, 21);
  
  if (hasAttachments) {
    CGRect ar = CGRectMake(r.size.width - 83.0 
                           - (liked ? 14.0 : 0) 
                           - (isPrivate ? 14.0 : 0), 6.0, 8.0, 16.0);
    [smallAttachmentImage drawInRect:ar];
  }
  if (isPrivate) {
    CGRect fr = CGRectMake(r.size.width - 85.0 - (liked ? 14.0 : 0), 7, 12, 12);
    [smallPrivateImage drawInRect:fr];
  }
  if (liked) {
    CGRect lr = CGRectMake(r.size.width - 84.0, 7, 13, 13);
    [smallLikeImage drawInRect:lr];
  }
  
  if (group) {
    CGSize s = [group sizeWithFont:groupFont];
    CGRect gr = CGRectMake(62, r.size.height - (s.height + 5.0), r.size.width - 72.0, 17);
    [groupColor set];
    [group drawInRect:gr withFont:groupFont];
  }
  
  [[UIColor blackColor] set];
  [title drawInRect:titleSize withFont:titleFont 
      lineBreakMode:UILineBreakModeTailTruncation];
  
  [bodyColor set];
  [body drawInRect:bodySize withFont:bodyFont 
     lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentLeft];
  
  [dateColor set];
  [date drawInRect:dateLabel withFont:dateFont 
     lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentRight];
  
  [imageView.layer drawInContext:ctx];
}

@end
