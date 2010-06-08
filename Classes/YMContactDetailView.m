//
//  YMContactDetailView.m
//  Yammer
//
//  Created by Samuel Sutch on 5/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "YMContactDetailView.h"
#import "YMWebService.h"


@implementation YMContactDetailView

@synthesize onFollow, onMessage, onFeed, contact;

+ (id) contactDetailViewWithRect:(CGRect)rect
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
  fullNameLabel.text = ([c.fullName length] ? c.fullName : c.username);
  jobTitleLabel.text = ([c.jobTitle length] ? c.jobTitle : 
                        ([c.location length] ? c.location : @""));
  locationLabel.text = ([c.jobTitle length] ? c.location : @"");
  [feedButton setTitle:[NSString stringWithFormat:@"%@'s feed", 
                        fullNameLabel.text] forState:UIControlStateNormal];
  if (contact) [contact release];
  contact = nil;
  contact = [c retain];
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
