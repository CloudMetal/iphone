//
//  YMMessageListViewController.m
//  Yammer
//
//  Created by Samuel Sutch on 5/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "YMMessageListViewController.h"
#import "YMWebService.h"
#import "YMContactsListViewController.h"
#import "StatusBarNotifier.h"
#import "UIColor+Extensions.h"
#import "NSDate+Helper.h"
#import "YMMessageTableViewCell.h"
#import "NSMutableArray-MultipleSort.h"
#import <QuartzCore/QuartzCore.h>
#import "YMMessageCompanionTableViewCell.h"
#import "YMContactDetailViewController.h"
#import "YMMessageDetailViewController.h"
#import "YMComposeViewController.h"
#import "NSDate-SQLitePersistence.h"
#import "SQLiteInstanceManager.h"
#import "YMContactsListViewController.h"

@interface YMMessageListViewController (PrivateStuffs)

- (NSString *)listCriteria;
- (void)refreshMessagePKs;
- (NSInteger)rowForIndexPath:(NSIndexPath *)indexPath;
- (CGFloat)expandedHeightOfRow:(NSInteger)idx;
- (void)updateBadge;
- (void)updateNewlyReadMessages;
- (void)markAllMessagesRead;
- (id)gotoMessageIndexPath:(NSIndexPath *)indexPath sender:(id)s;

@end


@implementation YMMessageListViewController

@synthesize target, targetID, olderThan, newerThan, threaded, loadedAvatars, 
          userAccount, selectedIndexPath, limit, shouldUpdateBadge, privateThread, 
          remainingUnseenItems, lastLoadedMessageID, lastSeenMessageID, network, 
          numberOfUnseenInThread, lastLoadedThreadID;

- (id)init
{
  if ((self = [super init])) {
    self.title = @"Messages";
    self.target = YMMessageTargetAll;
    self.targetID = nil;
    self.olderThan = nil;
    self.newerThan = nil;
    self.threaded = nsnb(NO);
    self.remainingUnseenItems = nil;
    self.lastLoadedMessageID = nil;
    self.lastSeenMessageID = nil;
    self.lastLoadedThreadID = nil;
    self.actionTableViewHeaderClass = [YMRefreshView class];
    loadedIds = nil;
    threadInfo = nil;
    
    wasInactive = NO;
    privateThread = NO;
    loadedAvatars = NO;
    shouldScrollToTop = YES;
    limit = 50;
    shouldUpdateBadge = NO;
    loadedAvatars = YES;

    didGetFirstUpdate = didRefresh = NO;

    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(messagesDidUpdate:) 
     name:YMWebServiceDidUpdateMessages object:nil];
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(orientationDidChange:) name:
     UIDeviceOrientationDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(networksDidUpdate:) name:@"YMNetworksUpdated" object:nil];

    if (&UIApplicationWillEnterForegroundNotification != NULL) {
      [[NSNotificationCenter defaultCenter]
       addObserver:self selector:@selector(didBackground:) name:
       UIApplicationDidEnterBackgroundNotification object:nil];
      [[NSNotificationCenter defaultCenter]
       addObserver:self selector:@selector(didBecomeActive:) name:
       UIApplicationDidBecomeActiveNotification object:nil];
    }
    web = [YMWebService sharedWebService];
    HUD = nil;
  }
  return self;
}

- (void)didBackground:(id)n
{
  wasInactive = YES;
}

- (void)didBecomeActive:(id)n
{
  NSLog(@"didBecomeActive %@", n);
  if (wasInactive && ([self.target isEqual:YMMessageTargetPrivate] 
                   || [self.target isEqual:YMMessageTargetFollowing]) && self.tabBarController.view.window) {
    wasInactive = NO;
    [self reloadTableViewDataSource];
  }
}

- (void)networksDidUpdate:(id)n
{
  [self updateBadge];
}

- (void)loadView
{
  self.tableView = [[UITableView alloc] initWithFrame:
                    CGRectMake(0, 0, 320, 460) style:UITableViewStylePlain];
  self.tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                     UIViewAutoresizingFlexibleHeight);
  self.tableView.delegate = self;
  self.tableView.dataSource = self;
  self.tableView.backgroundColor = [UIColor whiteColor];
  
  UIView *tf = [[[UIView alloc] initWithFrame:
                 CGRectMake(0, 0, 320, 41)] autorelease];
  tf.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  moreButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
  moreButton.frame = CGRectMake(0, 0, 320, 41);
  moreButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  [moreButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
  [moreButton setTitle:@"Show More Messages" forState:UIControlStateNormal];
  moreButton.titleLabel.font = [UIFont systemFontOfSize:13];
  [moreButton setBackgroundImage:
   [[UIImage imageNamed:@"inline-button-bg-blue.png"] stretchableImageWithLeftCapWidth:
    0 topCapHeight:0] forState:UIControlStateNormal];
  [moreButton setBackgroundImage:
   [[UIImage imageNamed:@"inline-button-bg-blue-pressed.png"] stretchableImageWithLeftCapWidth:
    0 topCapHeight:0] forState:UIControlStateHighlighted];
  [moreButton addTarget:self action:@selector(loadMore:) 
       forControlEvents:UIControlEventTouchUpInside];
  [tf addSubview:moreButton];
  moreButton.hidden = YES;
  bottomLoadingView = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:
                        UIActivityIndicatorViewStyleGray] autorelease];
  bottomLoadingView.hidesWhenStopped = YES;
  bottomLoadingView.autoresizingMask 
    = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
  bottomLoadingView.frame = CGRectMake(149, 7, 22, 22);
  [bottomLoadingView stopAnimating];
  [tf insertSubview:bottomLoadingView atIndex:0];
  
  
  self.tableView.tableFooterView = tf;
}

- (void)setNetwork:(YMNetwork *)n
{
  [network release];
  network = [n retain];
  [messagePKs release];
  messagePKs = nil;
  [self.tableView reloadData];
  self.selectedIndexPath = nil;
  [self setHeaderTitle:self.title andSubtitle:network.name];
}

- (void) viewWillAppear:(BOOL)animated
{
  self.navigationController.delegate = self;
  self.navigationController.navigationBar.tintColor 
  = [UIColor colorWithRed:0.27 green:0.34 blue:0.39 alpha:1.0];
  self.navigationController.toolbar.tintColor 
  = [UIColor colorWithHexString:@"353535"];
  self.selectedIndexPath = nil;
  viewHasAppeared = YES;
  if (![self.target isEqual:YMMessageTargetPrivate] 
      && ![self.target isEqual:YMMessageTargetFollowing])
    didGetFirstUpdate = NO;
  if (!messagePKs || ![messagePKs count]) {
    [self refreshMessagePKs];
    if (![messagePKs count] && !didGetFirstUpdate) {
//      if (HUD) [HUD release];
//      HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
//      [self.navigationController.view addSubview:HUD];
//      HUD.labelText = @"Loading";
//      [HUD show:YES];
    }
    [self.tableView reloadData];
  }   
  [self setHeaderTitle:self.title andSubtitle:self.network.name];
  [super viewWillAppear:animated];
  if (self.view) {
    if ([self.target isEqual:YMMessageTargetPrivate]) {
      self.navigationItem.rightBarButtonItem = 
      [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
                                                     target:self action:@selector(composePrivate:)]
       autorelease];
    }
  }
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
  isPushing = YES;
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
  isPushing = NO;
  if (currentlySelectedIndexPath) [currentlySelectedIndexPath release];
  currentlySelectedIndexPath = nil;
}

- (void)hudWasHidden
{
  [HUD removeFromSuperview];
  [HUD release];
  HUD = nil;
}

- (void)composePrivate:s
{
  YMContactsListViewController *c = [[[YMContactsListViewController alloc] init] autorelease];
  [c setUseSubtitleHeader:NO];
  UINavigationController *n = [[[UINavigationController alloc] initWithRootViewController:c] autorelease];
  c.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:
                                         UIBarButtonSystemItemCancel target:self.navigationController
                                         action:@selector(dismissModalViewControllerAnimated:)] autorelease];
  c.userAccount = self.userAccount;
  
  c.isPicker = YES;
  c.selected = [NSMutableArray array];
  c.onDone = callbackTS(self, contactPickerFinished:);
  c.canRemove = YES;
  [self.navigationController presentModalViewController:n animated:YES];
  c.navigationController.navigationBar.tintColor = self.navigationController.navigationBar.tintColor;
  c.title = @"Select Recipient";
}

- (void)contactPickerFinished:(YMContactsListViewController *)picker
{
  YMComposeViewController *c = [[[YMComposeViewController alloc]
                                 init] autorelease];
  c.userAccount = self.userAccount;
  c.network = self.network;
  c.delegate = self;
  c.sendAction = @selector(didSendMessage:);
  if ([self.target isEqual:YMMessageTargetInGroup]) {
    c.inGroup = (YMGroup *)[YMGroup findFirstByCriteria:
                            @"WHERE group_i_d=%i", intv(self.targetID)];
  }
  if ([self.target isEqual:YMMessageTargetInThread] && [messagePKs count]) {
    c.inThread = (YMMessage *)[YMMessage findByPK:intv([messagePKs objectAtIndex:0])];
    NSLog(@"c.inThread = %@", c.inThread);
  }
  c.isPrivate = [self.target isEqual:YMMessageTargetPrivate] || self.privateThread;
  //c.recipients = picker.selected;
  c.directTo = (YMContact *)[YMContact findByPK:intv([picker.selected objectAtIndex:0])];
  [self.navigationController dismissModalViewControllerAnimated:NO];
  [c showFromController:self animated:YES];
}

- (void)didSendMessage:(DKDeferred *)msgSend
{
  if (HUD) [HUD release];
  HUD = [[MBProgressHUD alloc] initWithView:self.tabBarController.view];
  HUD.labelText = @"Sending";
  [self.tabBarController.view addSubview:HUD];
  [HUD show:YES];
  [msgSend addBoth:callbackTS(self, _finishedSendMessage:)];
}

- (id)_finishedSendMessage:(id)r
{  
  NSLog(@"finished send message %@", r);
  if ([r isKindOfClass:[YMMessage class]]) {
    YMMessage *m = r;
    m.target = self.target;
    if (self.targetID) m.targetID = self.targetID;
    m.read = nsni(1);
    [m save];
    [self refreshMessagePKs];
    [self.tableView reloadData];
  }
  [HUD hide:YES];
  return r;
}

- (void) viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  
  self.olderThan = nil;
  if (![self.target isEqual:YMMessageTargetFollowing] 
      && ![self.target isEqual:YMMessageTargetPrivate]) 
    [self doReload:nil];
  [self.tableView reloadData];

  int fontSize = 13;
  id p = PREF_KEY(@"fontsize");
  if (p) fontSize = intv(p);
  if (fontSize != previousFontSize) {
    previousFontSize = fontSize;
    [YMFastMessageTableViewCell updateFontSize];
    [self.tableView reloadData];
  }
  [self performSelector:@selector(updateBadge) withObject:nil afterDelay:.1];
}

- (void)_updateReadLater
{
  NSLog(@"setting read %@", self.target);
  [[SQLiteInstanceManager sharedManager] executeUpdateSQL:
   [NSString stringWithFormat:
    @"UPDATE y_m_message SET read=1 WHERE network_p_k=%i AND target='%@'",
    self.network.pk, self.target]];
}

- (void)viewWillDisappear:(BOOL)animated
{
  viewHasAppeared = NO;
  if ([self.target isEqual:YMMessageTargetReceived] 
      || [self.target isEqual:YMMessageTargetFollowing]) {
    [self performSelector:@selector(_updateReadLater) withObject:nil afterDelay:.2];
  }
  [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
  [self updateBadge];
  [super viewDidDisappear:animated];
}

- (void)messagesDidUpdate:(id)note
{
  NSLog(@"MESSAGES DID UPDATE %@ got %@", self, note);
//  if (![self.target isEqual:YMMessageTargetFollowing] 
//      && ![self.target isEqual:YMMessageTargetReceived]) [self doReload:nil];
}

- (void)subscriptionsDidUpdate:(id)note
{
  NSLog(@"SUBSCRIPTIONS DID UPDATE %@ got %@", self, note);
//  [self refreshMessagePKs];
//  [self.tableView reloadData];
}

- (id)doReload:(id)arg
{
  NSMutableDictionary *opts = [NSMutableDictionary dictionary];
  
  if (self.olderThan)
    [opts setObject:[self.olderThan description] forKey:@"older_than"];
  
  [[[web getMessages:self.userAccount withTarget:target withID:self.targetID 
    params:opts fetchToID:self.newerThan unseenLeft:self.remainingUnseenItems]
    addCallback:callbackTS(self, _gotMessages:)] 
   addErrback:callbackTS(self, _failedGetMessages:)];
  if (loadingDeferred && loadingDeferred.fired == -1) 
    [loadingDeferred callback:nil];
  loadingDeferred = nil;
  loadingDeferred = [[DKDeferred deferred] retain];
  if (!self.reloading)
    [[StatusBarNotifier sharedNotifier] flashLoading:
     @"Loading Messages" deferred:loadingDeferred];
//  self.reloading = YES;
  moreButton.hidden = YES;
  [bottomLoadingView startAnimating];
  
  return arg;
}

- (id)_imagesLoaded:(id)arg
{
  NSLog(@"images loaded");
  loadedAvatars = YES;
  //[self doReload:nil];
  [self.tableView reloadData];
  return arg;
}

- (void)loadMore:(id)sender
{
  if (self.reloading || moreButton.hidden) return;
  if ([messagePKs count]) {
    int currentCount = [messagePKs count];
    limit += 50;
    if (self.lastLoadedMessageID == nil &&
        [YMMessage countByCriteria:@"%@ LIMIT %i", 
         [self listCriteria], limit] > currentCount) {
      [self refreshMessagePKs];
      [self.tableView reloadData];
      return;
    }
    
    if (self.lastLoadedMessageID == nil && self.lastSeenMessageID == nil) {
      YMMessage *last = (YMMessage *)[YMMessage findByPK:
                                      intv([messagePKs lastObject])];
      if (last) self.olderThan = last.messageID;
      else self.olderThan = nil;
      self.newerThan = nil;
    } else {
      self.olderThan = self.lastLoadedMessageID;
      self.newerThan = nil;
    }
  }
  [self doReload:nil];
}

- (void)reloadTableViewDataSource
{
  [self refreshFeed:nil];
}

- (void)refreshFeed:(id)sender
{
  if ([messagePKs count]) {
    YMMessage *first = (YMMessage *)[YMMessage findByPK:
                                     intv([messagePKs objectAtIndex:0])];
    if (first) self.newerThan = first.messageID;
    else self.newerThan = nil;
    [self markAllMessagesRead];
    [self updateBadge];
  }
  if (loadedIds) [loadedIds release];
  loadedIds = nil;
  self.olderThan = nil;
  [self doReload:nil];
}

- (void)composeNew:(id)sender
{
  YMComposeViewController *c = [[[YMComposeViewController alloc]
                                 init] autorelease];
  c.userAccount = self.userAccount;
  c.network = self.network;
  c.delegate = self;
  c.sendAction = @selector(didSendMessage:);
  if ([self.target isEqual:YMMessageTargetInGroup]) {
    c.inGroup = (YMGroup *)[YMGroup findFirstByCriteria:
                            @"WHERE group_i_d=%i", intv(self.targetID)];
  }
  if ([self.target isEqual:YMMessageTargetInThread] && [messagePKs count]) {
    c.inThread = (YMMessage *)[YMMessage findByPK:intv([messagePKs objectAtIndex:0])];
    NSLog(@"c.inThread = %@", c.inThread);
  }
  c.isPrivate = [self.target isEqual:YMMessageTargetPrivate] || self.privateThread;
  [c showFromController:self animated:YES];
}

- (id)_gotMessages:(id)results
{
//  NSLog(@"got messages %@", results);
  if (isDeferred(results)) 
    return [results addCallback:callbackTS(self, _gotMessages:)];
  
  self.selectedIndexPath = nil;
  self.tableView.tableFooterView.hidden = NO;
//  self.reloading = NO;
  shouldUpdateBadge = NO;
  int networkBadgeCount = 0;
  
  if ([results objectForKey:@"unseenItemsLeftToFetch"]) {
    self.remainingUnseenItems 
      = [results objectForKey:@"unseenItemsLeftToFetch"];
    self.lastSeenMessageID = [results objectForKey:@"lastSeenID"];
    int u = intv(self.remainingUnseenItems);
    networkBadgeCount = u > 0 ? u : 0;
    [moreButton setTitle:[NSString stringWithFormat:@"More (%i unread)", 
                          ((u > 0) ? u : 0)] forState:UIControlStateNormal];
    moreButton.hidden = NO;
    shouldUpdateBadge = NO;
  } else {
    shouldUpdateBadge = YES;
    
    self.lastSeenMessageID = nil;
    self.remainingUnseenItems = nil;

    [self updateBadge];
    [moreButton setTitle:@"More" forState:UIControlStateNormal];
  }
  if (!loadedIds) loadedIds = [NSMutableArray new];
  [loadedIds addObjectsFromArray:[results objectForKey:@"loadedMessageIDs"]];
  self.lastLoadedMessageID = [results objectForKey:@"lastFetchedID"];
  self.lastLoadedThreadID = [results objectForKey:@"lastFetchedThreadID"];
  
  moreButton.hidden = !boolv([results objectForKey:@"olderAvailable"]); 
  NSLog(@"more available %@", results);
  
  if (didGetFirstUpdate)
    didRefresh = YES;
  didGetFirstUpdate = YES;
  [self refreshMessagePKs];
  
  if (!shouldUpdateBadge && self.remainingUnseenItems != nil)
    self.tabBarItem.badgeValue 
      = [NSString stringWithFormat:@"%i", [messagePKs count] 
         + intv(self.remainingUnseenItems)];
  
  [lastUpdated release];
  lastUpdated = [[NSDate date] retain];

  ((YMRefreshView *)self.refreshHeaderView).lastUpdatedDate = lastUpdated;
  [self updateBadge];
  [self.tableView reloadData];
  if (loadingDeferred && loadingDeferred.fired == -1)
    [loadingDeferred callback:nil];
  loadingDeferred = nil;
  
  [self dataSourceDidFinishLoadingNewData];
  //if ([results objectForKey:
  //moreButton.hidden = NO;
  [bottomLoadingView stopAnimating];
  
  return results;
}

- (id)_failedGetMessages:(NSError *)error
{
  NSLog(@"_failedGetMessages: %@ %@", error, [error userInfo]);
//  self.reloading = NO;
  moreButton.hidden = NO;
  [bottomLoadingView stopAnimating];
  [self dataSourceDidFinishLoadingNewData];
  return error;
}

- (NSString *)listCriteria
{
//  YMMessage *lastLoaded = nil;
  BOOL useThreadId = [self.target isEqual:YMMessageTargetPrivate];
  id limitField    = useThreadId ? @"thread_i_d" : @"message_i_d";
//  id limiter       = useThreadId ? self.lastLoadedThreadID : self.lastLoadedMessageID;
  id andTarget     = self.targetID != nil 
                     ? [NSString stringWithFormat:@" AND target_i_d='%@'", self.targetID] : @"";
  
//  if (self.lastLoadedMessageID != nil)
//    lastLoaded = (YMMessage *)[YMMessage findFirstByCriteria:
//       @"WHERE %@=%@ AND target='%@'%@", limitField, limiter, self.target, andTarget];
//  NSString *andLimit = lastLoaded != nil
//    ? [NSString stringWithFormat:@" AND %@ >= %@", limitField, limiter] : @"";
  NSString *andLimit = self.lastLoadedMessageID != nil 
    ? [NSString stringWithFormat:@" AND %@ IN(%@)", limitField, 
       [loadedIds componentsJoinedByString:@","]] 
    : @"";
  
  return [NSString stringWithFormat:@"WHERE network_p_k=%i AND target='%@'%@%@", 
          self.network.pk, target, andTarget, andLimit];
}

- (void)refreshMessagePKs
{
  if (!viewHasAppeared) return;
  // this is optimized more for speed than clarity, 
  // also could be sped up with more mutability ...
  if (messagePKs) [messagePKs release];
  messagePKs = nil;
  if (titles) [titles release];
  titles = nil;
  if (mugshotURLs) [mugshotURLs release];
  mugshotURLs = nil;
  if (bodies) [bodies release];
  bodies = nil;
  if (reads) [reads release];
  reads = nil;
  if (hasattachments) [hasattachments release];
  hasattachments = nil;
  if (likeds) [likeds release];
  likeds = nil;
  if (followeds) [followeds release];
  followeds = nil;
  if (privates) [privates release];
  privates = nil;
  if (groups) [groups release];
  groups = nil;
  if (unseenThreadCounts) [unseenThreadCounts release];
  unseenThreadCounts = nil;
  if (messageInThreadCounts) [messageInThreadCounts release];
  messageInThreadCounts = nil;
  if (numberOfParticipantCounts) [numberOfParticipantCounts release];
  numberOfParticipantCounts = nil;
  if (newlyReadMessageIndexes) [newlyReadMessageIndexes release];
  newlyReadMessageIndexes = [[NSMutableIndexSet indexSet] retain];
  if (self.newerThan) self.newerThan = nil;
  NSString *extra = @"";
  if ([self.target isEqual:YMMessageTargetPrivate]) {
    extra = @", unseen_thread_count, number_of_participants, total_thread_count";
  }
  
  NSString *order = [self.target isEqual:YMMessageTargetPrivate] ? @"thread_last_updated": @"created_at";
  NSString *q = [NSString stringWithFormat:
     @"SELECT pk, sender_mugshot, sender_name, replied_to_sender_name, " 
     @"body_plain, %@, read, liked, has_attachments, sender_i_d, "
     @"direct_to_sender_name, group_name%@ FROM y_m_message %@ ORDER BY "
     @"%@ DESC LIMIT %i", order, extra, [self listCriteria], order, limit];
  NSLog(@"q %@", q);

  NSArray *a = [YMMessage pairedArraySelect:q fields:17];
  
  messagePKs = [[a objectAtIndex:0] retain];
  mugshotURLs = [[a objectAtIndex:1] retain];
  NSMutableArray *_titles = [NSMutableArray arrayWithCapacity:
                             [messagePKs count]];
  bodies = [[a objectAtIndex:4] retain];
  dates = [[a objectAtIndex:5] retain];
  reads = [[a objectAtIndex:6] retain];
  likeds = [[a objectAtIndex:7] retain];
  hasattachments = [[a objectAtIndex:8] retain];
  privates = [[a objectAtIndex:10] retain];
  groups = [[a objectAtIndex:11] retain];
  NSMutableArray *_senderIds = [a objectAtIndex:9];
  NSMutableArray *_following = [NSMutableArray arrayWithCapacity:
                                [messagePKs count]];
  NSArray *subscribedUserIds = [[self.network.userSubscriptionIds copy] autorelease];
  BOOL isPrivate = [self.target isEqual:YMMessageTargetPrivate];
  if (isPrivate) {
    NSMutableArray *th = [a objectAtIndex:12];
    NSMutableArray *yh = [NSMutableArray arrayWithCapacity:[th count]];
    totalUnseenThreads = 0;
    for (NSNumber *n in th) {
      if (![n isEqual:[NSNull null]]) {
        int y = [n intValue];
        if (y) totalUnseenThreads++;
        [yh addObject:nsni(y)];
      } else [yh addObject:nsni(0)];
    }
    unseenThreadCounts = [yh retain];
    numberOfParticipantCounts = [[a objectAtIndex:13] retain];
    messageInThreadCounts = [[a objectAtIndex:14] retain];
  }
  
  [self updateBadge];

  if ([messagePKs count] && didGetFirstUpdate) {
    if ([self.target isEqual:YMMessageTargetInThread] && self.privateThread) {
      YMMessage *first = (YMMessage *)[YMMessage findByPK:intv([messagePKs objectAtIndex:0])];
      [web resetSeenCountForThread:first forUserAccount:self.userAccount];
      DKDeferred *d = [web threadInfo:[first.threadID description] forAccount:self.userAccount];
      [d addCallback:callbackTS(self, _gotThreadInfo:)];
    }
  }

  id np, nc;
  for (int i = 0; i < [messagePKs count]; i++) {
    if (isPrivate) {
      np = [numberOfParticipantCounts objectAtIndex:i];
      nc = [messageInThreadCounts objectAtIndex:i];
      if ([np isEqual:[NSNull null]]) np = @"0";
      if ([nc isEqual:[NSNull null]]) nc = @"0"; 
      [(NSMutableArray *)numberOfParticipantCounts replaceObjectAtIndex:i withObject:nsni(intv(np))];
      [(NSMutableArray *)messageInThreadCounts replaceObjectAtIndex:i withObject:nsni(intv(nc))];
    }
    NSString *tit = [[a objectAtIndex:2] objectAtIndex:i];
    NSString *rtit = [[a objectAtIndex:3] objectAtIndex:i];
    NSString *ttit = [privates objectAtIndex:i];
    if ([rtit isEqual:[NSNull null]] && [ttit isEqual:[NSNull null]])
      [_titles addObject:tit];
    else if (![rtit isEqual:[NSNull null]])
      [_titles addObject:[tit stringByAppendingFormat:@" re: %@", rtit]];
    else
      [_titles addObject:[tit stringByAppendingFormat:@" to %@", ttit]];
    
    [_following addObject:([subscribedUserIds containsObject:
                            nsni(intv([_senderIds objectAtIndex:i]))] 
                           ? nsnb(YES) : nsnb(NO))];
    if (![[groups objectAtIndex:i] isEqual:[NSNull null]]) {
      if ([[groups objectAtIndex:i] hasSuffix:@"(private)"]) {
        [(NSMutableArray *)privates replaceObjectAtIndex:i withObject:@"ass"];
      }
    }
  }
  followeds = [_following retain];
  titles = [_titles retain];
  if ([messagePKs count])
    self.newerThan = [(YMMessage *)[YMMessage findByPK:
              intv([messagePKs objectAtIndex:0])] messageID];
  else newerThan = nil;
  
  id r = PREF_KEY(@"previouslylastloaded");
  NSMutableDictionary *d = [NSMutableDictionary dictionaryWithDictionary:
                            ((r == nil) ? [NSDictionary dictionary] : r)];
  NSString *k = [NSString stringWithFormat:@"%@:%@", 
                 network.networkID, self.target];
  if (self.newerThan && !self.remainingUnseenItems)
    [d setObject:self.newerThan forKey:k];
  else [d removeObjectForKey:k];
  NSLog(@"setting previouslylastloaded, %@", d);
  
  PREF_SET(@"previouslylastloaded", d);
  PREF_SYNCHRONIZE;
  if (currentlySelectedIndexPath) [currentlySelectedIndexPath release];
  currentlySelectedIndexPath = nil;
  
  if (HUD && [HUD superview]) {
    [HUD hide:YES];
  }
}

- (id)_gotThreadInfo:(id)r
{
  NSLog(@"%@ gotThreadInfo %@", self, r);
  if (threadInfo) [threadInfo release];
  threadInfo = [r retain];
  if (participants) [participants release];
  participants = [NSMutableArray new];
  for (NSDictionary *d in [threadInfo objectForKey:@"participants"]) {
    for (NSDictionary *p in [threadInfo objectForKey:@"references"]) {
      if ([[d objectForKey:@"type"] isEqual:@"user"] 
          && [[p objectForKey:@"id"] isEqual:[d objectForKey:@"id"]]) {
        [participants addObject:p];
        break;
      }
    }
  }
  [self.tableView reloadData];
  return r;
}

- (void)updateBadge
{
  if ([self.target isEqual:YMMessageTargetPrivate]) {
    int u = [web unseenThreadCountForNetwork:self.network];
    if (self.tabBarItem)
      self.tabBarItem.badgeValue = (u > 0) ? [NSString stringWithFormat:@"%i", u] : nil;
    return;
  }
  if (!shouldUpdateBadge) return;
  int t = 0;
  if (reads)
    for (id i in reads)
      if ([i isKindOfClass:[NSObject class]] && intv(i) == 0)
        t++;
  if (self.tabBarItem)
    self.tabBarItem.badgeValue = (t > 0) 
      ? [NSString stringWithFormat:@"%d", t] : nil;
}

- (void)markAllMessagesRead
{
  //if (!([messagePKs count] >= 1)) return;
  //if (newlyReadMessageIndexes) [newlyReadMessageIndexes release];
  //newlyReadMessageIndexes = [[NSMutableIndexSet indexSetWithIndexesInRange:
                             //NSMakeRange(0, [messagePKs count] - 1)] retain];
  //[self updateNewlyReadMessages];
}

- (void)updateNewlyReadMessages
{
  //if (self.lastLoadedMessageID != nil) return;
  
  //NSArray *pks = [messagePKs objectsAtIndexes:newlyReadMessageIndexes];
  //SQLiteInstanceManager *db = [SQLiteInstanceManager sharedManager];
  //NSString *q = [NSString stringWithFormat:
                 //@"UPDATE y_m_message SET read = 1 WHERE pk IN(%@);",
                 //[pks componentsJoinedByString:@","]];
  //[db executeUpdateSQL:q];
  //NSMutableArray *newReads = [NSMutableArray array];
  //NSMutableArray *indexPaths = [NSMutableArray array];
  //for (int i = 0; i < [newlyReadMessageIndexes count]; i++) {
    //[newReads addObject:nsni(1)];
    //[indexPaths addObject:[NSIndexPath indexPathForRow:
                           //[messagePKs indexOfObject:
                            //[pks objectAtIndex:i]] inSection:0]];
  //}
  //[reads replaceObjectsAtIndexes:newlyReadMessageIndexes withObjects:newReads];
  //[newlyReadMessageIndexes release];
  //newlyReadMessageIndexes = [[NSMutableIndexSet indexSet] retain];
  
  //[web subtractUnseenCount:[pks count] fromNetwork:self.network];
}

- (NSInteger)rowForIndexPath:(NSIndexPath *)indexPath
{
  int idx;
  if (!selectedIndexPath || indexPath.row <= selectedIndexPath.row) 
    idx = indexPath.row;
  else if (indexPath.row > selectedIndexPath.row) idx = indexPath.row - 1;
  else idx = 0;
  
  return idx;
}

- (CGFloat)expandedHeightOfRow:(NSInteger)idx
{
  CGFloat ret = 60;
  CGSize max = CGSizeMake(
  UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? 247 : 407 , 480);
  CGFloat sizeNeeded = ([[bodies objectAtIndex:idx] sizeWithFont:
                       [UIFont systemFontOfSize:previousFontSize] 
                       constrainedToSize:max lineBreakMode:
                       UILineBreakModeWordWrap].height 
                        + ([[groups objectAtIndex:idx] isEqual:[NSNull null]] 
                           ? 0 : ([[groups objectAtIndex:idx] sizeWithFont:
                                   [UIFont systemFontOfSize:
                                    previousFontSize-1]].height + 4)));
  if (sizeNeeded > 28.0)
    ret = sizeNeeded + 32.0;
  return ret;
}

// - (void) scrollViewDidEndDecelerating:(UIScrollView *)scrollView
// {
  // if (scrollView.decelerating || ![newlyReadMessageIndexes count]) return;
  // 
  // [self updateNewlyReadMessages];
  // [self updateBadge];
// }
// 
// - (void) scrollViewDidEndDragging:(UIScrollView *)scrollView
                   // willDecelerate:(BOOL)decelerate
// {
  // [super scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
  // if (!decelerate) {
    // [self updateNewlyReadMessages];
    // [self updateBadge];
  // }
// }

-(NSInteger) numberOfSectionsInTableView:(UITableView *)table
{
  if (privateThread && threadInfo) return 2;
  return 1;
}

- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)sec
{
  if (privateThread && sec == 1) return @"Participants";
  return nil;
}

- (CGFloat) tableView:(UITableView *)table
heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (![messagePKs count]) return 60;
  if (privateThread && indexPath.section == 1) return 44;
  if ([self.target isEqual:YMMessageTargetPrivate]) return 82;
  CGFloat ret;
  if (selectedIndexPath && selectedIndexPath.row + 1 == indexPath.row)
    ret = 60;
  else {
    int idx = [self rowForIndexPath:indexPath];
    CGFloat max 
      = self.interfaceOrientation == UIInterfaceOrientationPortrait ? 170 : 115;
    CGFloat h = [self expandedHeightOfRow:idx];
    if (h > max && (!selectedIndexPath || 
        !(selectedIndexPath.row == idx)))
      ret = max;
    else ret = h;
  }
  return ret;
}

- (NSInteger) tableView:(UITableView *)table
  numberOfRowsInSection:(NSInteger)section
{
  if (privateThread && threadInfo && section == 1) 
    return [[threadInfo objectForKey:@"participants"] count];
  return MAX(1, ([messagePKs count] + ((self.selectedIndexPath != nil) ? 1 : 0)));
}

- (UITableViewCell *) tableView:(UITableView *)table
cellForRowAtIndexPath:(NSIndexPath *)indexPath
{  
  if (indexPath.section == 1 && threadInfo && privateThread) {
    UITableViewCell *cell = [table dequeueReusableCellWithIdentifier:@"participant"];
    if (!cell) {
      //cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                  //reuseIdentifier:@"participant"] autorelease];
      //cell.textLabel.font = [UIFont systemFontOfSize:15];
      cell = [[[NSBundle mainBundle] loadNibNamed:@"YMParticipantTableViewCell"
                                            owner:nil options:nil] objectAtIndex:0];
    }
    NSDictionary *p = [participants objectAtIndex:indexPath.row];
    if (p) {
      //cell.textLabel.text = [p objectForKey:@"full_name"];
      [(UILabel *)[cell viewWithTag:709] setText:[p objectForKey:@"full_name"]];
      static NSString *photoRegex = @"no_photo_small\\.gif$";
      id imgURL = [p objectForKey:@"mugshot_url"];
      UIImage *img = [[DKDeferred cache] objectForKeyInMemory:imgURL];
      UIImageView *imageView = (UIImageView *)[cell viewWithTag:707];
      if (!img) {
        img = [UIImage imageNamed:@"user-70.png"];
        if (![imgURL isEqual:[NSNull null]] && ![imgURL isMatchedByRegex:photoRegex]) {
          [[web contactImageForURL:imgURL] addCallback:
           curryTS(self, @selector(_gotParticipantMugshot::), indexPath)];
        }
      }
      imageView.image = img;
    }
    return cell;


  }
  if (selectedIndexPath && indexPath.row == selectedIndexPath.row + 1) {
    YMMessageCompanionTableViewCell *cell = nil;
    for (id v in [[NSBundle mainBundle] loadNibNamed:
                  @"YMMessageCompanionTableViewCell" owner:nil options:nil]) {
      if (![v isKindOfClass:[YMMessageCompanionTableViewCell class]]) 
        continue;
      cell = v;
      break;
    }
    NSIndexPath *onActionIndex = [NSIndexPath indexPathForRow:
                                  indexPath.row - 1 inSection:0];
    YMMessage *m = (YMMessage *)[YMMessage findByPK:
                           intv([messagePKs objectAtIndex:indexPath.row - 1])];
    cell.liked = m.liked != nil ? boolv(m.liked) : NO;
    cell.onLike 
      = curryTS(self, @selector(gotoLikeIndexPath:sender:), indexPath);
    cell.onUser 
      = curryTS(self, @selector(gotoUserIndexPath:sender:), onActionIndex);
    cell.onMore 
      = curryTS(self, @selector(gotoMessageIndexPath:sender:), onActionIndex);
    cell.onThread 
      = curryTS(self, @selector(gotoThreadIndexPath:sender:), onActionIndex);
    cell.onReply 
      = curryTS(self, @selector(gotoReplyIndexPath:sender:), onActionIndex);
    return cell;
  }
  
  static NSString *ident = @"YMMessageCell1";
  
  YMFastMessageTableViewCell *cell = (YMFastMessageTableViewCell *)
    [table dequeueReusableCellWithIdentifier:ident];
  if (!cell) {
    cell = [[[YMFastMessageTableViewCell alloc] initWithFrame:
             CGRectMake(0, 0, 320, 72) reuseIdentifier:ident] autorelease];
//    cell.swipeTarget = self;
//    cell.swipeSelector = @selector(cellDidSwipe:);
  }
  if (![messagePKs count]) {
    if (didGetFirstUpdate) {
      cell.body = @"      No messages in this feed.";
    } else cell.body = @"           Loading Messages";
    cell.avatar = nil;
    cell.title= @"";
    cell.dm = NO;
    cell.numberOfParticipants = 0;
    cell.messagesInThread = 0;
    cell.unreadInThread = 0;
    cell.unread = NO;
    cell.isPrivate = NO;
    cell.group = @"";
    cell.liked = NO;
    cell.hasAttachments = NO;
    cell.date = @"";
    return cell;
  }
  
  int idx = [self rowForIndexPath:indexPath];
  if (idx >= [messagePKs count]) return nil;
  
  id read = [reads objectAtIndex:idx];
  if ([read isKindOfClass:[NSObject class]] && !intv(read)) {
    cell.unread = YES;
  } else {
    cell.unread = NO;
  }
  
  static NSString *photoRegex = @"no_photo_small\\.gif$";
  id imgURL = [mugshotURLs objectAtIndex:idx];
  UIImage *img = [[DKDeferred cache] objectForKeyInMemory:imgURL];
  if (!img) {
    img = [UIImage imageNamed:@"user-70.png"];
    if (![imgURL isEqual:[NSNull null]] && ![imgURL isMatchedByRegex:photoRegex]) {
      [[web contactImageForURL:imgURL] addCallback:
       curryTS(self, @selector(_gotMugshot::), [messagePKs objectAtIndex:idx])];
    }
  }
  
  cell.avatar = img;
  cell.body = [bodies objectAtIndex:idx];
  id _date = [dates objectAtIndex:idx];
  if ([_date isKindOfClass:[NSString class]]) {
    cell.date = [NSDate fastStringForDisplayFromDate:
                 [NSDate objectWithSqlColumnRepresentation:_date]];
  } else {
    cell.date = nil;
  }
  BOOL isPrivate = ([self.target isEqual:YMMessageTargetPrivate]);
  if (isPrivate) {
    cell.dm = YES;
    cell.numberOfParticipants = MAX(intv([numberOfParticipantCounts objectAtIndex:idx]), 1);
    cell.messagesInThread = MAX(intv([messageInThreadCounts objectAtIndex:idx]), 1);
    cell.unreadInThread = intv([unseenThreadCounts objectAtIndex:idx]);
    cell.unread = boolv([unseenThreadCounts objectAtIndex:idx]);
  }
  if (didGetFirstUpdate && !didRefresh && [self.target isEqual:YMMessageTargetInThread]) {
    cell.unread = idx < numberOfUnseenInThread;
  }
  cell.title = [titles objectAtIndex:idx];
  cell.liked = boolv([likeds objectAtIndex:idx]);
  cell.hasAttachments = boolv([hasattachments objectAtIndex:idx]);
  cell.isPrivate = privateThread || isPrivate || ![[privates objectAtIndex:idx] 
                     isEqual:[NSNull null]];
  if ([[groups objectAtIndex:idx] isEqual:[NSNull null]])
    cell.group = nil;
  else
    cell.group = [@"posted in " stringByAppendingString:
                  [groups objectAtIndex:idx]];
  
  currentRow = idx;
  return cell;
}

- (void) tableView:(UITableView *)tableView willDisplayCell:
(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (indexPath.section == 1) {
    NSLog(@"wut");
    cell.imageView.frame = CGRectMake(10, 1, 44, 44);
  }
}

- (void) tableView:(UITableView *)table
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (isPushing) return;
  if (privateThread && threadInfo && indexPath.section == 1) {
    YMContact *c = (YMContact *)[YMContact findFirstByCriteria:
                 @"WHERE user_i_d=%@", [[[threadInfo objectForKey:@"participants"] 
                                 objectAtIndex:indexPath.row] objectForKey:@"id"]];
    if (c) [self gotoContact:c];
    return;
  }
  if ([self.target isEqual:YMMessageTargetPrivate]) {
    [self gotoThreadIndexPath:indexPath sender:nil];
  } else {
    [self gotoMessageIndexPath:indexPath sender:nil];
  }
}

- (void)delayedGotoMessage:(NSIndexPath *)indexPath
{
  [self gotoMessageIndexPath:indexPath sender:nil];
}

- (void)cellDidSwipe:(UITableViewCell *)c
{
  NSIndexPath *p = nil;
  if ((p = [self.tableView indexPathForCell:c])) {
    p = [NSIndexPath indexPathForRow:[self rowForIndexPath:p] inSection:0];
    self.selectedIndexPath = p;
  }
}

- (NSIndexPath *)tableView:(UITableView *)table
willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (!messagePKs || ![messagePKs count] 
      || currentlySelectedIndexPath || isPushing) return nil;
  if (selectedIndexPath) {
    if (selectedIndexPath.row + 1 == indexPath.row) return nil;
    if (selectedIndexPath.row == indexPath.row) {
      [self.tableView deselectRowAtIndexPath:
       self.selectedIndexPath animated:YES];
      self.selectedIndexPath = nil;
      return nil;
    }
  }
  currentlySelectedIndexPath = [indexPath copy];
  NSArray *v = [self.tableView indexPathsForVisibleRows];
  int idx = [v indexOfObject:indexPath];
  if (idx != NSNotFound) {
    YMFastMessageTableViewCell *c = [[self.tableView visibleCells] objectAtIndex:idx];
    c.selected = YES;
  }
  [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0/30.0]];

  return indexPath;
}

- (void)setSelectedIndexPath:(NSIndexPath *)indexPath
{
  NSIndexPath *previousIndexPath = nil;
  NSIndexPath *previousCompanionIndexPath = nil;
  [self.tableView beginUpdates];
  if (selectedIndexPath) {
    previousIndexPath = [selectedIndexPath retain];
    previousCompanionIndexPath = [[NSIndexPath indexPathForRow:
                               previousIndexPath.row + 1 inSection:0] retain];
    [selectedIndexPath release];
    selectedIndexPath = nil;
    [self.tableView deleteRowsAtIndexPaths:array_(previousCompanionIndexPath)
                        withRowAnimation:UITableViewRowAnimationTop];
    [self.tableView reloadRowsAtIndexPaths:array_(previousIndexPath)
                        withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView deselectRowAtIndexPath:selectedIndexPath animated:NO];
  }
  selectedIndexPath = [indexPath retain];
  if (selectedIndexPath) {
    NSIndexPath *companionPath = [NSIndexPath indexPathForRow:
                                  selectedIndexPath.row+1 inSection:0];
      [self.tableView insertRowsAtIndexPaths:array_(companionPath)
                              withRowAnimation:UITableViewRowAnimationBottom];
    if (self.selectedIndexPath.row != previousIndexPath.row 
        && self.selectedIndexPath.row != previousCompanionIndexPath.row) {
      [self.tableView reloadRowsAtIndexPaths:array_(self.selectedIndexPath)
                          withRowAnimation:UITableViewRowAnimationNone];
    }
  }
  [self.tableView endUpdates];
  [previousIndexPath release];
  [previousCompanionIndexPath release];
  [self.tableView selectRowAtIndexPath:selectedIndexPath animated:YES 
                        scrollPosition:UITableViewScrollPositionNone];
}

- (id)_gotMugshot:(NSNumber *)messagePK :(id)result
{  
  if ([result isKindOfClass:[UIImage class]]) {
    int idx = [messagePKs indexOfObject:messagePK];
    if (idx != currentRow && idx != NSNotFound) {
      if (self.selectedIndexPath && self.selectedIndexPath.row < idx) idx++;
      NSIndexPath *path = [NSIndexPath indexPathForRow:idx inSection:0];
      int idx2 = [[self.tableView indexPathsForVisibleRows] indexOfObject:path];
      if (idx2 != NSNotFound) {
        YMFastMessageTableViewCell *cell = (YMFastMessageTableViewCell *)
          [[self.tableView visibleCells] objectAtIndex:idx2];
        cell.avatar = result;
      }
    }
  }
  return result;
}

- (id)_gotParticipantMugshot:(NSIndexPath *)indexPath :(id)r
{
  if ([r isKindOfClass:[UIImage class]]) {
    int idx2 = [[self.tableView indexPathsForVisibleRows] indexOfObject:indexPath];
    if (idx2 != NSNotFound) {
      UITableViewCell *cell = [[self.tableView visibleCells] objectAtIndex:idx2];
      [(UIImageView *)[cell viewWithTag:707] setImage:r];
    }
  }
  return r;
}

- (id)gotoUserIndexPath:(NSIndexPath *)indexPath sender:(id)s
{
  int idx = [self rowForIndexPath:indexPath];
  YMMessage *message = (YMMessage *)[YMMessage findByPK:
                                     intv([messagePKs objectAtIndex:idx])];
  YMContact *contact = (YMContact *)[YMContact findFirstByCriteria:
                               @"WHERE user_i_d=%i", intv(message.senderID)];
  [self gotoContact:contact];
  return nil;
}

- (void)gotoContact:(YMContact *)contact
{
  YMContactDetailViewController *c = [[[YMContactDetailViewController alloc] 
                                       init] autorelease];
  c.contact = contact;
  c.userAccount = self.userAccount;
  [self.navigationController pushViewController:c animated:YES];
}

- (id)gotoMessageIndexPath:(NSIndexPath *)indexPath sender:(id)s
{
  [[NSRunLoop currentRunLoop] runUntilDate:
   [NSDate dateWithTimeIntervalSinceNow:0.05]];
  
  int idx = [self rowForIndexPath:indexPath];
  YMMessage *m = (YMMessage *)[YMMessage findByPK:
                               intv([messagePKs objectAtIndex:idx])];
  YMMessageDetailViewController *c = [[[YMMessageDetailViewController alloc]
                                       initWithStyle:UITableViewStyleGrouped]
                                      autorelease];
  c.feedItems = messagePKs;
  c.message = m;
  c.isPrivate = [self.target isEqual:YMMessageTargetPrivate] || self.privateThread;
  NSLog(@"isPrivate %i", c.isPrivate);
  c.userAccount = self.userAccount;
  [self.navigationController pushViewController:c animated:YES];
  if (currentlySelectedIndexPath) [currentlySelectedIndexPath release];
  currentlySelectedIndexPath = nil;
  return nil;
}

- (id)gotoThreadIndexPath:(NSIndexPath *)indexPath sender:(id)s
{
  int idx = [self rowForIndexPath:indexPath];
  YMMessage *m = (YMMessage *)[YMMessage findByPK:
                               intv([messagePKs objectAtIndex:idx])];
  YMMessageListViewController *c = [[[YMMessageListViewController alloc] 
                                     init] autorelease];
  c.network = self.network;
  c.userAccount = self.userAccount;
  c.target = YMMessageTargetInThread;
  c.targetID = m.threadID;
  if (![m.unseenThreadCount isEqual:[NSNull null]])
    c.numberOfUnseenInThread = intv(m.unseenThreadCount);
  else c.numberOfUnseenInThread = 0;
  if ([self.target isEqual:YMMessageTargetPrivate]) {
//    NSString *k = [NSString stringWithFormat:@"%@%@-unseenthreads", self.network.userID, self.network.networkID];
//    int n = [web unseenThreadCountForNetwork:self.network];
//    n--;
//    if (n >= 0) {
//      PREF_SET(k, nsni(n));
//      PREF_SYNCHRONIZE;
//      if (self.tabBarItem)
//        self.tabBarItem.badgeValue = n ? [NSString stringWithFormat:@"%i", n] : nil;
//      self.network.unseenPrivateCount = nsni(n);
//      [self.network save];
//    }
    c.privateThread = YES; 
    [(NSMutableArray *)unseenThreadCounts replaceObjectAtIndex:idx withObject:nsni(0)];
  }

  [self.navigationController pushViewController:c animated:YES];
  c.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:
    UIBarButtonSystemItemCompose target:c action:@selector(composeNew:)] autorelease];
  c.title = @"Thread";
  if (currentlySelectedIndexPath) [currentlySelectedIndexPath release];
  currentlySelectedIndexPath = nil;
  return nil;
}

- (id)gotoReplyIndexPath:(NSIndexPath *)indexPath sender:(id)s
{
  YMComposeViewController *c = [[[YMComposeViewController alloc] 
                                 init] autorelease];
  c.userAccount = self.userAccount;
  c.network = (YMNetwork *)[YMNetwork findByPK:
                            intv(userAccount.activeNetworkPK)];
  c.inReplyTo = (YMMessage *)[YMMessage findByPK:
                              intv([messagePKs objectAtIndex:indexPath.row])];
  
  if ([self.target isEqual:YMMessageTargetPrivate]) c.isPrivate = YES;
  
  [c showFromController:self animated:YES];
  return nil;
}

- (id)gotoLikeIndexPath:(NSIndexPath *)companionIndexPath sender:(id)s
{
  int idx = [self rowForIndexPath:companionIndexPath];
  YMMessage *m = (YMMessage *)[YMMessage findByPK:
                               intv([messagePKs objectAtIndex:idx])];
  if (!boolv(m.liked)) {
    [[StatusBarNotifier sharedNotifier]
      flashLoading:@"Liking Message" deferred:
      [[web like:self.userAccount message:m]
     addCallback:curryTS(self, @selector(_updateMessageCompanion::), 
                         companionIndexPath)]];
  } else {
    [[StatusBarNotifier sharedNotifier]
      flashLoading:@"Unliking Message" deferred:
      [[web unlike:self.userAccount message:m]
     addCallback:curryTS(self, @selector(_updateMessageCompanion::), 
                         companionIndexPath)]];
  }
  return nil;
}

- (id)_updateMessageCompanion:(NSIndexPath *)companionIndexPath :(id)r
{
  [self.tableView reloadRowsAtIndexPaths:array_(companionIndexPath)
                        withRowAnimation:UITableViewRowAnimationNone];
  return r;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:
(UIInterfaceOrientation)interfaceOrientation
{
  return YES;
}

- (void)orientationDidChange:(NSNotification *)note
{
  [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter]
   removeObserver:self];
  [participants release];
  [bodies release];
  [threadInfo release];
  [unseenThreadCounts release];
  [messagePKs release];
  [mugshotURLs release];
  [dates release];
  [titles release];
  [hasattachments release];
  [privates release];
  [followeds release];
  [lastUpdated release];
  [reads release];  
  [lastUpdated release];
  self.target = nil;
  self.threaded = nil;
  self.newerThan = nil;
  self.userAccount = nil;
  self.olderThan = nil;
  self.lastSeenMessageID = nil;
  self.lastLoadedMessageID = nil;
  self.remainingUnseenItems = nil;
  self.targetID = nil;
  [selectedIndexPath release];
  self.tableView = nil;
  [super dealloc];
}

@end
 
