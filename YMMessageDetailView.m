//
//  YMMessageDetailView.m
//  Yammer
//
//  Created by Samuel Sutch on 5/14/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "YMMessageDetailView.h"
#import "YMWebService.h"
#import <QuartzCore/QuartzCore.h>

@interface YMMessageDetailView (PrivateParts)

- (void)sizeViewsToFit;

@end


@implementation YMMessageDetailView

@synthesize message, parentViewController;

- (void)setMessage:(YMMessage *)m
{
  [message release];
  message = [m retain];
  [fromContact release];
  [toContact release];
  
  if (message.senderID)
    fromContact = (YMContact *)[YMContact findFirstByCriteria:
                                @"WHERE user_i_d=%i", intv(message.senderID)];
  if (message.repliedToSenderID)
    toContact = (YMContact *)[YMContact findFirstByCriteria:
                              @"WHERE user_i_d=%i", intv(message.repliedToSenderID)];
  
  NSString *to = @"";
  if (toContact) to = [NSString stringWithFormat:@" re: %@", toContact.fullName];
  titleLabel.text = [fromContact.fullName stringByAppendingString:to];
  dateLabel.text = [message.createdAt description];
  
  [messageBodyWebView loadHTMLString:self.htmlValue 
                 baseURL:[NSURL URLWithString:@""]];
  messageBodyWebView.backgroundColor = [UIColor colorWithPatternImage:
                                        [UIImage imageNamed:@"msg-body-bg.png"]];
  
  id img = nil;
  if (fromContact && [fromContact.mugshotURL isKindOfClass:[NSString class]])
    img = [[YMWebService sharedWebService]
           imageForURLInMemoryCache:fromContact.mugshotURL];
  if (!img) img = [UIImage imageNamed:@"user-70.png"];
  avatarImageView.image = img;
  avatarImageView.layer.masksToBounds = YES;
  avatarImageView.layer.borderColor = [UIColor colorWithWhite:.5 alpha:1].CGColor;
  avatarImageView.layer.cornerRadius = 3;
  avatarImageView.layer.borderWidth = 1;
}

- (NSString *)htmlValue
{
  NSString *template = 
    @"<html><head><style>"
  @"body { font-size: 12px; font-family: Helvetica; margin: 0; padding: 10px;}"
  @"</style></head><body>%@</body></html>";
  
  return [NSString stringWithFormat:template, self.message.bodyPlain];
}

- (void)sizeViewsToFit
{
//  static CGFloat fixedUsage = 188.0;
//  static CGFloat headerHeight = 60.0;
//  static CGFloat footerHeight = 128.0;
//  static CGFloat portraitLandscapeHeight = 416.0;
//  CGSize sizeWanted = [self.message.bodyPlain sizeWithFont:
//                       [UIFont systemFontOfSize:12] constrainedToSize:
//                       CGSizeMake(self.bounds.size.width - 20., 100000) 
//                                 lineBreakMode:UILineBreakModeWordWrap] + 20.;
//  CGFloat webviewHeight = ((sizeWanted + fixedUsage) < portraitLandscapeHeight) 
//                          ? portraitLandscapeHeight : (sizeWanted + fixedUsage);
  
}

- (IBAction)user:(id)sender {}
- (IBAction)like:(id)sender {}
- (IBAction)thread:(id)sender {}
- (IBAction)reply:(id)sender {}
- (IBAction)bookmark:(id)sender {}
- (IBAction)attachments:(id)sender {}
- (IBAction)send:(id)sender {}
- (IBAction)follow:(id)sender {}

- (void)dealloc
{
  self.message = nil;
  [super dealloc];
}


@end

