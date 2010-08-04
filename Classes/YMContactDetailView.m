//
//  YMContactDetailView.m
//  Yammer
//
//  Created by Samuel Sutch on 5/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "YMContactDetailView.h"
#import "YMWebService.h"
#import "NSDate+Helper.h"
#import <QuartzCore/QuartzCore.h>


@implementation YMContactDetailView

@synthesize onFollow, onMessage, onFeed, contact, followButton,
followingCountLabel, followersLabel, yamCountLabel, joinDateLabel;

+ (id)contactDetailViewWithRect:(CGRect)rect
{
  for (UIView *v in [[NSBundle mainBundle] 
                     loadNibNamed:@"YMContactDetailView"
                     owner:nil options:nil]) {
    if ([v isMemberOfClass:[self class]])
      return v;
  }
  return nil;
}

- (void) setContact:(YMContact *)c
{
  UIImage *img;
  if (!c.mugshotURL || [c.mugshotURL isEqual:[NSNull null]] 
      || ![c.mugshotURL length] 
      || !(img = [[YMWebService sharedWebService]
                  imageForURLInMemoryCache:c.mugshotURL]))
    img = [UIImage imageNamed:@"user-70.png"];
  mugImageView.image = img;
  mugImageView.layer.masksToBounds = YES;
  mugImageView.layer.borderColor = [UIColor colorWithWhite:.5 alpha:1].CGColor;
  mugImageView.layer.cornerRadius = 3;
  mugImageView.layer.borderWidth = 1;
  fullNameLabel.text = ([c.fullName length] ? c.fullName : c.username);
  jobTitleLabel.text = ([c.jobTitle length] ? c.jobTitle : 
                        ([c.location length] ? c.location : @""));
  locationLabel.text = ([c.jobTitle length] ? c.location : @"");
  
  [feedButton setTitle:[NSString stringWithFormat:@"%@'s Messages", 
                        fullNameLabel.text] forState:UIControlStateNormal];
  
  joinDateLabel.text = c.hireDate;
  followingCountLabel.text = [[c.stats objectForKey:@"following"] description];
  yamCountLabel.text = [[c.stats objectForKey:@"updates"] description];
  followersLabel.text = [[c.stats objectForKey:@"followers"] description];
  if (![c.type isEqual:@"user"]) {
    [self hideFollowAndPM];
    followersLabel.hidden = YES;
    followingCountLabel.hidden = YES;
  } else {
    followersLabel.hidden = NO;
    followingCountLabel.hidden = NO;
  }
  
  if (contact) [contact release];
  contact = nil;
  contact = [c retain];
}

- (void)hideFollowAndPM
{
  self.frame = CGRectMake(0, 0, self.frame.size.width, 137);
  feedButton.frame = CGRectOffset(feedButton.frame, 0, -96);
  followButton.hidden = YES;
  messageButton.hidden = YES;
}

- (void)message:(id)sender
{
  if (self.onMessage) [self.onMessage :self.contact];
}

- (void)follow:(id)sender
{
  if (self.onFollow) [self.onFollow :self.contact];
}

- (void)feed:(id)sender
{
  if (self.onFeed) [self.onFeed :self.contact];
}

- (void)dealloc
{
  [super dealloc];
}

@end
