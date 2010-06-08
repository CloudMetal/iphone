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
@synthesize onUser, onTag, onLike, onThread, onReply, onBookmark, 
            onAttachments, onSend, onFollow;

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
  @"html { background-color: #f9f9f9}"
  @"body { font-size: 13px; font-family: Helvetica; margin: 0; padding: 10px;}"
  @"a { font-size:13px; font-weight: bold; color: white; display:inline-block; " 
  @"    padding: 2px 3px; background-color: #256ac7; -webkit-border-radius:2px; text-decoration:none;}"
  @"</style></head><body>%@</body></html>";
  
  return [NSString stringWithFormat:template, self.message.bodyParsed];
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

- (BOOL) webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request
  navigationType:(UIWebViewNavigationType)navigationType
{
  static NSString *yammerUrlRegex = @"(yammer://)([a-z]+)/([0-9]+)";
  NSLog(@"request %@ %@", request, [request.URL description]);
  NSString *url = [request.URL description];
  NSArray *comp = [url arrayOfCaptureComponentsMatchedByRegex:yammerUrlRegex];
  if ([comp count]) comp = [comp objectAtIndex:0];
  NSLog(@"comp %@", comp);
  if ([comp count] == 4 && [[comp objectAtIndex:1] isEqual:@"yammer://"]) {
    if ([[comp objectAtIndex:2] isEqual:@"user"]) {
      YMContact *c = (YMContact *)[YMContact findFirstByCriteria:@"WHERE user_i_d=%@",
                                   [comp objectAtIndex:3]];
      NSLog(@"c %@", c);
      if (self.onUser && c)
        [self.onUser :c];
    } else if ([[comp objectAtIndex:2] isEqual:@"tag"]) {
      if (self.onTag) [self.onTag :[comp objectAtIndex:3]];
    }
  }
  return NO;
}

- (IBAction)user:(id)sender { if (self.onUser) [self.onUser :self]; }
- (IBAction)like:(id)sender { if (self.onLike) [self.onLike :self]; }
- (IBAction)thread:(id)sender { if (self.onThread) [self.onThread :self]; }
- (IBAction)reply:(id)sender { if (self.onReply) [self.onReply :self]; }
- (IBAction)bookmark:(id)sender { if (self.onBookmark) [self.onBookmark :self]; }
- (IBAction)attachments:(id)sender { if (self.onAttachments) [self.onAttachments :self]; }
- (IBAction)send:(id)sender { if (self.onSend) [self.onSend :self]; }
- (IBAction)follow:(id)sender { if (self.onFollow) [self.onFollow :self]; }

- (void)dealloc
{
  [fromContact release];
  [toContact release];
  self.onTag = nil;
  self.onUser = nil;
  self.message = nil;
  [super dealloc];
}

@end

