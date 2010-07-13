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
#import "DrillDownWebController.h"
#import "NSDate+Helper.h"
#import "NSString+XMLEntities.h"


@implementation YMMessageDetailFooter

@synthesize onUser, onTag, onLike, onThread , onReply , onBookmark , onAttachments, onSend, onFollow, likeButton, userButton;

- (IBAction)user:(id)sender { if (self.onUser) [self.onUser :self]; }
- (IBAction)like:(id)sender { if (self.onLike) [self.onLike :self]; }
- (IBAction)thread:(id)sender { if (self.onThread) [self.onThread :self]; }
- (IBAction)reply:(id)sender { if (self.onReply) [self.onReply :self]; }
- (IBAction)bookmark:(id)sender { if (self.onBookmark) [self.onBookmark :self]; }
- (IBAction)attachments:(id)sender { if (self.onAttachments) [self.onAttachments :self]; }
- (IBAction)send:(id)sender { if (self.onSend) [self.onSend :self]; }
- (IBAction)follow:(id)sender { if (self.onFollow) [self.onFollow :self]; }

@end


@implementation YMMessageDetailHeader

@synthesize avatarImageView, titleLabel, dateLabel, lockImageView, postedInLabel, backgroundImageView;

@end


@implementation YMMessageDetailView

@synthesize message, parentViewController, onFinishLoad, headerView, footerView;

- (void)setMessage:(YMMessage *)m
{
  [message release];
  message = [m retain];
  [fromContact release];
  [toContact release];
  direct = NO;
  
  if (message.senderID)
    fromContact = (YMContact *)[YMContact findFirstByCriteria:
                                @"WHERE user_i_d=%i", intv(message.senderID)];
  if (message.repliedToSenderID)
    toContact = (YMContact *)[YMContact findFirstByCriteria:
                              @"WHERE user_i_d=%i", intv(message.repliedToSenderID)];
  if (message.directToID) {
    toContact = (YMContact *)[YMContact findFirstByCriteria:
                              @"WHERE user_i_d=%i", intv(message.directToID)];
    direct = YES;
  }
  
  footerView.userButton.enabled = [fromContact.type isEqual:@"user"];
  
  if (message.groupID) {
    YMGroup *g = (id)[YMGroup findFirstByCriteria:@"WHERE group_i_d=%i", intv(message.groupID)];
    headerView.postedInLabel.text = [@"posted in " stringByAppendingString:g.fullName];
    if ([g.privacy isEqual:@"private"]) direct = YES;
//    headerView.frame = CGRectInset(headerView.frame, 0, 20);
//    headerView.backgroundImageView.frame = CGRectInset(headerView.backgroundImageView.frame, 0, 20);
  } else {
    YMNetwork *n = (id)[YMNetwork findByPK:intv(message.networkPK)];
    headerView.postedInLabel.text = [@"posted in " stringByAppendingString:n.name];
  }
  
  NSString *to = @"";
  if (toContact) to = [NSString stringWithFormat:@" %@ %@", (direct ? @"to" : @"re:"), toContact.fullName];
  headerView.titleLabel.text = [fromContact.fullName stringByAppendingString:to];
  NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
  [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
  [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
  headerView.dateLabel.text = [dateFormatter stringFromDate:message.createdAt];
  headerView.lockImageView.hidden = !direct;
  
  [messageBodyWebView loadHTMLString:self.htmlValue 
                 baseURL:[NSURL URLWithString:@""]];
  messageBodyWebView.backgroundColor = [UIColor colorWithPatternImage:
                                        [UIImage imageNamed:@"msg-body-bg.png"]];
  messageBodyWebView.hidden = YES;
  
  id img = nil;
  if (fromContact && [fromContact.mugshotURL isKindOfClass:[NSString class]])
    img = [[YMWebService sharedWebService]
           imageForURLInMemoryCache:fromContact.mugshotURL];
  if (!img) img = [UIImage imageNamed:@"user-70.png"];
  headerView.avatarImageView.image = img;
  headerView.avatarImageView.layer.masksToBounds = YES;
  headerView.avatarImageView.layer.borderColor = [UIColor colorWithWhite:.5 alpha:1].CGColor;
  headerView.avatarImageView.layer.cornerRadius = 3;
  headerView.avatarImageView.layer.borderWidth = 1;
}

- (NSString *)htmlValue
{
  NSString *template = 
  @"<html><head><style>"
  @"html { background-color: #f9f9f9}"
  @"body { font-size: 14px; font-family: Helvetica; margin: 0; padding: 10px;}"
  @"a { font-weight: bold; text-decoration: underline; color: #374a70; }" 
  @"</style></head><body>%@</body></html>";
  
  return [NSString stringWithFormat:template, self.message.bodyParsed];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
  float newSize = [[webView stringByEvaluatingJavaScriptFromString:
                    @"document.documentElement.scrollHeight"] floatValue];
//  webView.frame = CGRectMake(0, 0, webView.frame.size.width, newSize);
  CGRect f = self.frame;
  f.size.height = newSize + 10.0;
  NSLog(@"f %@ to %@ %.2f", NSStringFromCGRect(self.frame), NSStringFromCGRect(f), newSize);
  self.frame = f;
  webView.hidden = NO;
  if (self.onFinishLoad) [self.onFinishLoad :self];
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
      if (self.footerView.onUser && c)
        [self.footerView.onUser :c];
    } else if ([[comp objectAtIndex:2] isEqual:@"tag"]) {
      if (self.footerView.onTag) [self.footerView.onTag :[comp objectAtIndex:3]];
    }
  } else {
    [self.parentViewController.navigationController pushViewController:
     [[DrillDownWebController alloc] initWithWebRoot:[request.URL description]
      andTitle:@"Loading Page" andSplashImage:[UIImage imageNamed:@"web-loading-splash.png"]]
     animated:YES];
  }
  return NO;
}

- (void)dealloc
{
  [fromContact release];
  [toContact release];
  self.message = nil;
  [super dealloc];
}

@end

