    //
//  YMMessageDetailViewController.m
//  Yammer
//
//  Created by Samuel Sutch on 5/14/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "YMMessageDetailViewController.h"
#import "YMWebService.h"
#import "YMContactDetailViewController.h"
#import "YMMessageListViewController.h"
#import "YMComposeViewController.h"
#import "DrillDownWebController.h"
#import "NSData+Base64.h"
#import "NSString+UUID.h"
#import "YMSimpleWebView.h"
#import "StatusBarNotifier.h"

@implementation YMMessageDetailViewController

@synthesize message, userAccount;

- (void)loadView
{
  self.tableView = [[UITableView alloc] initWithFrame:
                    CGRectMake(0, 0, 320, 460) style:UITableViewStylePlain];
  self.tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                     UIViewAutoresizingFlexibleHeight);
  self.tableView.delegate = self;
  self.tableView.dataSource = self;
  self.tableView.backgroundColor = [UIColor whiteColor];
  self.title = @"Message";
  
  for (id v in [[NSBundle mainBundle] loadNibNamed:
                @"YMMessageDetailView" owner:nil options:nil]) {
    if (![v isKindOfClass:[YMMessageDetailView class]]) continue;
    detailView = [v retain];
    break;
  }
  
  if (!web) web = [YMWebService sharedWebService];
}

- (void)setMessage:(YMMessage *)m
{
  [message release];
  message = nil;
  message = [m retain];
}

- (id)showUser:(id)contact
{
  if (![contact isKindOfClass:[YMContact class]]) {
    YMContactDetailViewController *c = [[[YMContactDetailViewController alloc] init] autorelease];
    c.contact = (YMContact *)[YMContact findFirstByCriteria:@"WHERE user_i_d=%i",
                              intv(self.message.senderID)];
    c.userAccount = self.userAccount;
    [self.navigationController pushViewController:c animated:YES];
    return nil;
  }
  
  YMContactDetailViewController *c = [[[YMContactDetailViewController alloc] init] autorelease];
  c.contact = contact;
  c.userAccount = self.userAccount;
  
  [self.navigationController pushViewController:c animated:YES];
  return contact;
}

- (id)showTag:(NSString *)tag
{
  YMMessageListViewController *c = [[[YMMessageListViewController alloc] init] autorelease];
  c.userAccount = self.userAccount;
  c.network = (YMNetwork *)[YMNetwork findByPK:intv(self.userAccount.activeNetworkPK)];
  c.target = YMMessageTargetTaggedWith;
  c.targetID = nsni(intv(tag));
  [self.navigationController pushViewController:c animated:YES];
  return tag;
}

- (id)showThread:(NSString *)sender
{
  YMMessageListViewController *c = [[[YMMessageListViewController alloc] init] autorelease];
  c.userAccount = self.userAccount;
  c.network = (YMNetwork *)[YMNetwork findByPK:intv(self.userAccount.activeNetworkPK)];
  c.target = YMMessageTargetInThread;
  c.title = @"Thread";
  c.targetID = self.message.threadID;
  [self.navigationController pushViewController:c animated:YES];
  return nil;
}

- (id)showReply:(id)sender
{
  YMComposeViewController *c = [[[YMComposeViewController alloc] init] autorelease];
  c.userAccount = self.userAccount;
  c.network = (YMNetwork *)[YMNetwork findByPK:intv(self.userAccount.activeNetworkPK)];
  c.inReplyTo = self.message;
  [c showFromController:self animated:YES];
  return nil;
}

- (id)finishedLoading:(id)s
{
  [self.tableView reloadData];
  return s;
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  detailView.message = message;
  detailView.parentViewController = self;

  detailView.footerView.onUser = callbackTS(self, showUser:);
  detailView.footerView.onTag = callbackTS(self, showTag:);
  detailView.footerView.onReply = callbackTS(self, showReply:);
  detailView.footerView.onThread = callbackTS(self, showThread:);
  detailView.footerView.onLike = callbackTS(self, doLike:);
  detailView.onFinishLoad = callbackTS(self, finishedLoading:);
  [detailView.footerView.likeButton setImage:[UIImage imageNamed:
   (boolv(message.liked) ? @"liked-inline.png" : @"like-inline.png")] 
                                    forState:UIControlStateNormal];
  self.tableView.tableHeaderView = detailView.headerView;
  self.tableView.tableFooterView = detailView.footerView;
  if (attachments) [attachments release];
  attachments = nil;
  attachments = [[YMAttachment findByCriteria:@"WHERE message_p_k=%i", message.pk] retain];
  if (attachmentCache) [attachmentCache release];
  attachmentCache = [[NSMutableDictionary dictionary] retain];
  if (!loadingPool) loadingPool = [[[DKDeferredPool alloc] init] retain];
  [self.tableView reloadData];
}

- (id)doLike:(id)s
{
  if (!boolv(message.liked)) {
    [[StatusBarNotifier sharedNotifier]
     flashLoading:@"Liking Message" deferred:
     [[web like:self.userAccount message:message]
      addCallback:callbackTS(self, _updatedLike:)]];
  } else {
    [[StatusBarNotifier sharedNotifier]
     flashLoading:@"Unliking Message" deferred:
     [[web unlike:self.userAccount message:message]
      addCallback:callbackTS(self, _updatedLike:)]];
  }
  return s;
}

- (id)_updatedLike:(id)r
{
  [detailView.footerView.likeButton setImage:[UIImage imageNamed:
   (boolv(message.liked) ? @"liked-inline.png" : @"like-inline.png")] 
                                    forState:UIControlStateNormal];
  return r;
}
  

- (CGFloat) tableView:(UITableView *)table
heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  return indexPath.section == 0 ? detailView.frame.size.height : detailView.headerView.frame.size.height;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)table
{
  return 2;
}

- (NSInteger) tableView:(UITableView *)table
numberOfRowsInSection:(NSInteger)section
{
  return section == 0 ? 1 : [attachments count];
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
  if (section == 0) return nil;
  if (![attachments count]) return nil;
  return [NSString stringWithFormat:@"%i Attachment%@", 
          [attachments count], ([attachments count] > 1 ? @"s" : @"")];
}

- (UITableViewCell *) tableView:(UITableView *)table
cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (indexPath.section == 0) return detailView;
  static NSString *ident = @"YMAttachmentCell1";
  UITableViewCell *cell = [table dequeueReusableCellWithIdentifier:ident];
  if (!cell) cell = [[[UITableViewCell alloc] initWithStyle:
                      UITableViewCellStyleSubtitle reuseIdentifier:ident] autorelease];
  YMAttachment *a = [attachments objectAtIndex:indexPath.row];
  cell.textLabel.text = a.name;
  cell.detailTextLabel.text = [NSString stringWithFormat:@"%dk", intv(a.size)/1024];
  NSLog(@"a %@ %@", a, a.imageThumbnailURL);
  UIImage *image = nil;
  if ([attachmentCache objectForKey:a.imageThumbnailURL]) {
    image = [attachmentCache objectForKey:a.imageThumbnailURL];
  } else if (a.imageThumbnailURL) {
    image = [UIImage imageNamed:@"42-photos.png"];
    
    NSMutableURLRequest *req = [[[NSMutableURLRequest alloc] initWithURL:
                                 [NSURL URLWithString:a.imageThumbnailURL]] autorelease];
    [web authorizeRequest:req withAccount:self.userAccount];
    [[loadingPool add:[[[DKDeferredURLConnection alloc] 
                        initRequest:req decodeFunction:nil paused:YES] autorelease]
                  key:a.imageThumbnailURL]
     addCallback:curryTS(self, @selector(_gotThumbnail::), indexPath)];
  } else {
    image = [UIImage imageNamed:@"68-paperclip.png"];
  }
  cell.imageView.image = image;
  return cell;
}

- (void) tableView:(UITableView *)table
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (indexPath.section == 1) {
    YMAttachment *a = [attachments objectAtIndex:indexPath.row];
    NSString *ext = [a.name pathExtension];
    NSArray *sup = array_(@"xls", @"key.zip", @"numbers.zip", @"pages.zip", @"pdf", 
                          @"ppt", @"doc", @"rft", @"rtfd.zip", @"key", @"numbers", @"pages");
    NSLog(@"ext %@ sup %@", ext, sup);
    if (![sup containsObject:ext] && !boolv(a.isImage)) {
      [[[[UIAlertView alloc]
         initWithTitle:@"Unsupported Attachment" message:
         @"Cannot open that type of attachment in this app. Please use the web interface to download it." 
         delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil]
        autorelease]
       show];
    } else {
      NSMutableURLRequest *req = [[[NSMutableURLRequest alloc] initWithURL:
                                   [NSURL URLWithString:a.url]] autorelease];
      [web authorizeRequest:req withAccount:self.userAccount];
      [[[StatusBarNotifier sharedNotifier]
        flashLoading:@"Loading File" deferred:
        [[[DKDeferredURLConnection alloc] initRequest:
          req decodeFunction:nil paused:NO] autorelease]]
       addCallback:curryTS(self, @selector(_showFullsize:::), [NSURL fileURLWithPath:[NSString stringWithFormat:@"/%@", a.name]], a.isImage)];
    }
  }
  [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (id)_showFullsize:(NSURL *)url :(NSNumber *)isImage :(id)result
{
  if ([result isKindOfClass:[NSData class]] && boolv(isImage))
    result = [UIImage imageWithData:result];
  if ([result isKindOfClass:[UIImage class]]) {
    NSString *fn = [[[DKDeferredCache sharedCache] dir] stringByAppendingPathComponent:
                    [[NSString stringWithUUID] stringByAppendingString:@".jpg"]];
    [UIImageJPEGRepresentation(result, 7) writeToFile:fn atomically:NO];
    NSString *html = [NSString stringWithFormat:
                      @"<html><body><img src=\"file://%@\" /></body></html>", fn];
    YMSimpleWebView *c = [[[YMSimpleWebView alloc] initWithNibName:@"YMSimpleWebView" bundle:nil] autorelease];
    
    c.title = [[url relativePath] lastPathComponent];
    [self.navigationController pushViewController:c animated:YES];
    [c.webView loadHTMLString:html baseURL:[[NSURL URLWithString:fn] baseURL]];
    NSLog(@"html %@ %@", html, c.webView);
  } else if ([result isKindOfClass:[NSData class]]) {
    NSString *fn = [[[DKDeferredCache sharedCache] dir] stringByAppendingPathComponent:
                    [[NSString stringWithUUID] stringByAppendingFormat:@".%@", [[url relativePath] pathExtension]]];
    NSLog(@"loading %@", fn);
    [(NSData *)result writeToFile:fn atomically:NO];
    NSURL *u = [NSURL fileURLWithPath:fn];
    NSURLRequest *req = [NSURLRequest requestWithURL:u];
    YMSimpleWebView *c = [[[YMSimpleWebView alloc] initWithNibName:@"YMSimpleWebView" bundle:nil] autorelease];
    c.title = [[url relativePath] lastPathComponent];
    [self.navigationController pushViewController:c animated:YES];
    [c.webView loadRequest:req];
  }
  return result;
}

- (id)_gotThumbnail:(NSIndexPath *)indexPath :(id)result
{
  if ([result isKindOfClass:[NSData class]])
    result = [UIImage imageWithData:result];
  if ([result isKindOfClass:[UIImage class]]) {
    UITableViewCell *c = [self.tableView cellForRowAtIndexPath:indexPath];
    [attachmentCache setObject:result forKey:
     [[attachments objectAtIndex:indexPath.row] imageThumbnailURL]];
    if (c) c.imageView.image = result;
  }
  return result;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)o
{
 return YES;
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}

- (void)viewDidUnload
{
  [super viewDidUnload];
}

- (void)dealloc
{
  [message release];
  self.tableView = nil;
  [super dealloc];
}


@end
