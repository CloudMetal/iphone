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
          userAccount, selectedIndexPath, limit, shouldUpdateBadge, 
          remainingUnseenItems, lastLoadedMessageID, lastSeenMessageID, network;

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
    self.actionTableViewHeaderClass = [YMRefreshView class];
    
    wasInactive = NO;
    loadedAvatars = NO;
    shouldScrollToTop = YES;
    limit = 50;
    shouldUpdateBadge = NO;
    loadedAvatars = YES;

    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(messagesDidUpdate:) 
     name:YMWebServiceDidUpdateMessages object:nil];
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(orientationDidChange:) name:
     UIDeviceOrientationDidChangeNotification object:nil];

    web = [YMWebService sharedWebService];
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
  if (wasInactive) {
    wasInactive = NO;
    [self reloadTableViewDataSource];
  }
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
//  [moreButton setBackgroundColor:[UIColor colorWithPatternImage:
//                            [UIImage imageNamed:@"inline-button-bg-blue.png"]]];
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
  self.navigationController.navigationBar.tintColor 
  = [UIColor colorWithRed:0.27 green:0.34 blue:0.39 alpha:1.0];
  self.navigationController.toolbar.tintColor 
  = [UIColor colorWithHexString:@"353535"];
  self.selectedIndexPath = nil;
  viewHasAppeared = YES;
  if (!messagePKs || ![messagePKs count]) {
    [self refreshMessagePKs];
    [self.tableView reloadData];
  }   
  [self setHeaderTitle:self.title andSubtitle:self.network.name];
  [super viewWillAppear:animated];
}

- (void) viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  
  self.olderThan = nil;
  if (![self.target isEqual:YMMessageTargetFollowing] 
      && ![self.target isEqual:YMMessageTargetReceived]) [self doReload:nil];
  if (&UIApplicationWillEnterForegroundNotification != NULL) {
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(didBackground:) name:
     UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(didBecomeActive:) name:
     UIApplicationDidBecomeActiveNotification object:nil];
  }
  int fontSize = 13;
  id p = PREF_KEY(@"fontsize");
  if (p) fontSize = intv(p);
  if (fontSize != previousFontSize) {
    previousFontSize = fontSize;
    [YMFastMessageTableViewCell updateFontSize];
    [self.tableView reloadData];
  }
}

- (void)viewWillDisappear:(BOOL)animated
{
  viewHasAppeared = NO;
  if ([self.target isEqual:YMMessageTargetReceived] 
      || [self.target isEqual:YMMessageTargetFollowing]) {
    NSLog(@"setting read %@", self.target);
    [[SQLiteInstanceManager sharedManager] executeUpdateSQL:
     [NSString stringWithFormat:
      @"UPDATE y_m_message SET read=1 WHERE network_p_k=%i AND target='%@'",
      self.network.pk, self.target]];
  }
  [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
  if (&UIApplicationWillEnterForegroundNotification != NULL) {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:
     UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:
     UIApplicationDidEnterBackgroundNotification object:nil];
  }
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
    limit += 100;
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
  self.olderThan = nil;
  [self doReload:nil];
}

- (void)composeNew:(id)sender
{
  YMComposeViewController *c = [[[YMComposeViewController alloc]
                                 init] autorelease];
  c.userAccount = self.userAccount;
  c.network = self.network;
  if ([self.target isEqual:YMMessageTargetInGroup]) {
    c.inGroup = (YMGroup *)[YMGroup findFirstByCriteria:
                            @"WHERE group_i_d=%i", intv(self.targetID)];
  }
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
  
  if ([results objectForKey:@"unseenItemsLeftToFetch"]) {
    self.remainingUnseenItems 
      = [results objectForKey:@"unseenItemsLeftToFetch"];
    self.lastLoadedMessageID = [results objectForKey:@"lastFetchedID"];
    self.lastSeenMessageID = [results objectForKey:@"lastSeenID"];
    int u = intv(self.remainingUnseenItems);
    [moreButton setTitle:[NSString stringWithFormat:@"More (%i unread)", 
                          ((u > 0) ? u : 0)] forState:UIControlStateNormal];
    moreButton.hidden = NO;
    shouldUpdateBadge = NO;
  } else {
    shouldUpdateBadge = YES;
    [self updateBadge];
    self.lastSeenMessageID = nil;
    self.lastLoadedMessageID = nil;
    self.remainingUnseenItems = nil;
    [moreButton setTitle:@"More" forState:UIControlStateNormal];
  }
  if ([results objectForKey:@"olderAvailable"] && 
      [YMMessage countByCriteria:@"WHERE message_i_d=%@", 
        [results objectForKey:@"lastFetchedID"]]) {
    moreButton.hidden = NO;
    self.lastLoadedMessageID = [results objectForKey:@"lastFetchedID"];
  } else moreButton.hidden = YES;
  
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
  moreButton.hidden = NO;
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
  return [NSString stringWithFormat:@"WHERE network_p_k=%i AND target='%@'%@%@", 
          self.network.pk, target, 
          (self.targetID != nil ? [NSString stringWithFormat:
                              @" AND target_i_d='%@'", self.targetID] : @""),
          (self.lastLoadedMessageID != nil 
           ? [NSString stringWithFormat:@" AND message_i_d >= %@", 
              self.lastLoadedMessageID] : @"")];
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
  if (mugshots) [mugshots release];
  mugshots = nil;
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
  if (newlyReadMessageIndexes) [newlyReadMessageIndexes release];
  newlyReadMessageIndexes = [[NSMutableIndexSet indexSet] retain];
  if (self.newerThan) self.newerThan = nil;
  
  NSString *q = [NSString stringWithFormat:
     @"SELECT pk, sender_mugshot, sender_name, replied_to_sender_name, " 
     @"body_plain, created_at, read, liked, has_attachments, sender_i_d, "
     @"direct_to_sender_name, group_name FROM y_m_message %@ ORDER BY "
     @"created_at DESC LIMIT %i", [self listCriteria], limit];

  NSArray *a = [YMMessage pairedArraySelect:q fields:12];
  
  messagePKs = [[a objectAtIndex:0] retain];
  mugshotURLs = [[a objectAtIndex:1] retain];
  NSMutableArray *_titles = [NSMutableArray arrayWithCapacity:
                             [messagePKs count]];
  mugshots = [[NSMutableArray arrayWithCapacity:[messagePKs count]] retain];
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
  
  [self updateBadge];
  
  for (int i = 0; i < [messagePKs count]; i++) {
    UIImage *img = nil;
    NSString *mugshotUrl = [mugshotURLs objectAtIndex:i];
    if ([mugshotUrl isKindOfClass:
         [NSString class]] && [mugshotUrl length])
      img = [[web imageForURLInMemoryCache:mugshotUrl] retain];
    [mugshots addObject:(img ? [img autorelease] : (id)[NSNull null])];
    
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
}

- (void)updateBadge
{
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
  if (!([messagePKs count] >= 1)) return;
  if (newlyReadMessageIndexes) [newlyReadMessageIndexes release];
  newlyReadMessageIndexes = [[NSMutableIndexSet indexSetWithIndexesInRange:
                             NSMakeRange(0, [messagePKs count] - 1)] retain];
  [self updateNewlyReadMessages];
}

- (void)updateNewlyReadMessages
{
  if (self.lastLoadedMessageID != nil) return;
  
  NSArray *pks = [messagePKs objectsAtIndexes:newlyReadMessageIndexes];
  SQLiteInstanceManager *db = [SQLiteInstanceManager sharedManager];
  NSString *q = [NSString stringWithFormat:
                 @"UPDATE y_m_message SET read = 1 WHERE pk IN(%@);",
                 [pks componentsJoinedByString:@","]];
  [db executeUpdateSQL:q];
  NSMutableArray *newReads = [NSMutableArray array];
  NSMutableArray *indexPaths = [NSMutableArray array];
  for (int i = 0; i < [newlyReadMessageIndexes count]; i++) {
    [newReads addObject:nsni(1)];
    [indexPaths addObject:[NSIndexPath indexPathForRow:
                           [messagePKs indexOfObject:
                            [pks objectAtIndex:i]] inSection:0]];
  }
  [reads replaceObjectsAtIndexes:newlyReadMessageIndexes withObjects:newReads];
  [newlyReadMessageIndexes release];
  newlyReadMessageIndexes = [[NSMutableIndexSet indexSet] retain];
  
  [web subtractUnseenCount:[pks count] fromNetwork:self.network];
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

- (void) scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
  if (scrollView.decelerating || ![newlyReadMessageIndexes count]) return;
  
  [self updateNewlyReadMessages];
  [self updateBadge];
}

- (void) scrollViewDidEndDragging:(UIScrollView *)scrollView
                   willDecelerate:(BOOL)decelerate
{
  [super scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
  if (!decelerate) {
    [self updateNewlyReadMessages];
    [self updateBadge];
  }
}

-(NSInteger) numberOfSectionsInTableView:(UITableView *)table
{
  return 1;
}

- (CGFloat) tableView:(UITableView *)table
heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
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
  return [messagePKs count] + ((self.selectedIndexPath != nil) ? 1 : 0);
}

- (UITableViewCell *) tableView:(UITableView *)table
cellForRowAtIndexPath:(NSIndexPath *)indexPath
{  
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
  
  int idx = [self rowForIndexPath:indexPath];
  if (idx >= [messagePKs count]) return nil;
  
  static NSString *ident = @"YMMessageCell1";
  
  YMFastMessageTableViewCell *cell = (YMFastMessageTableViewCell *)
    [table dequeueReusableCellWithIdentifier:ident];
  if (!cell) {
    cell = [[[YMFastMessageTableViewCell alloc] initWithFrame:
             CGRectMake(0, 0, 320, 72) reuseIdentifier:ident] autorelease];
    cell.swipeTarget = self;
    cell.swipeSelector = @selector(cellDidSwipe:);
  }
  
  id read = [reads objectAtIndex:idx];
  if ([read isKindOfClass:[NSObject class]] && !intv(read)) {
//    [newlyReadMessageIndexes addIndex:idx];
    cell.unread = YES;
  } else {
    cell.unread = NO;
  }
  
  id img = [mugshots objectAtIndex:idx];
  if (![img isKindOfClass:[UIImage class]]) {
    img = [UIImage imageNamed:@"user-70.png"];
    NSString *ms = [mugshotURLs objectAtIndex:idx];
    if (!loadedAvatars) { // do nothing if we haven't yet loaded
    } else if ([ms isKindOfClass:[NSString class]] && [ms length] &&
               !(img = [web imageForURLInMemoryCache:ms])) {
      img = [UIImage imageNamed:@"user-70.png"];
      [[web contactImageForURL:ms]
       addCallback:curryTS(self, @selector(_gotMugshot::), 
                           [messagePKs objectAtIndex:idx])];
    }
  }

  cell.avatar = img;
  cell.body = [bodies objectAtIndex:idx];
  cell.date = [NSDate fastStringForDisplayFromDate:
               [NSDate objectWithSqlColumnRepresentation:
                [dates objectAtIndex:idx]]];
  cell.title = [titles objectAtIndex:idx];
  cell.liked = boolv([likeds objectAtIndex:idx]);
  cell.hasAttachments = boolv([hasattachments objectAtIndex:idx]);
  cell.isPrivate = ![[privates objectAtIndex:idx] 
                     isEqual:[NSNull null]];
  if ([[groups objectAtIndex:idx] isEqual:[NSNull null]])
    cell.group = nil;
  else
    cell.group = [@"posted in " stringByAppendingString:
                  [groups objectAtIndex:idx]];
  
  return cell;
}

- (void) tableView:(UITableView *)table
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [self gotoMessageIndexPath:indexPath sender:nil];
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
  if (selectedIndexPath) {
    if (selectedIndexPath.row + 1 == indexPath.row) return nil;
    if (selectedIndexPath.row == indexPath.row) {
      [self.tableView deselectRowAtIndexPath:
       self.selectedIndexPath animated:YES];
      self.selectedIndexPath = nil;
      return nil;
    }
  }
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
    if (idx != NSNotFound) {
      loadedAvatars = YES;
      [mugshots replaceObjectAtIndex:idx withObject:result];
      if (self.selectedIndexPath && self.selectedIndexPath.row < idx) idx++;
      NSIndexPath *path = [NSIndexPath indexPathForRow:idx inSection:0];
      int idx2 = [[self.tableView indexPathsForVisibleRows] indexOfObject:path];
      if (idx2 != NSNotFound) {
        YMFastMessageTableViewCell *cell = (YMFastMessageTableViewCell *)[[self.tableView visibleCells] objectAtIndex:idx2];
        cell.avatar = result;
//      YMFastMessageTableViewCell *cell = (YMFastMessageTableViewCell *)      
//        [self.tableView cellForRowAtIndexPath:path];      
//      if (cell) cell.avatar = result;
      }
    }
  }
  return result;
}

- (id)gotoUserIndexPath:(NSIndexPath *)indexPath sender:(id)s
{
  int idx = [self rowForIndexPath:indexPath];
  YMMessage *message = (YMMessage *)[YMMessage findByPK:
                                     intv([messagePKs objectAtIndex:idx])];
  YMContact *contact = (YMContact *)[YMContact findFirstByCriteria:
                               @"WHERE user_i_d=%i", intv(message.senderID)];
  YMContactDetailViewController *c = [[[YMContactDetailViewController alloc] 
                                       init] autorelease];
  c.contact = contact;
  c.userAccount = self.userAccount;
  [self.navigationController pushViewController:c animated:YES];
  return nil;
}

- (id)gotoMessageIndexPath:(NSIndexPath *)indexPath sender:(id)s
{
//  [self.tableView selectRowAtIndexPath:indexPath animated:
//   YES scrollPosition:UITableViewScrollPositionNone];
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
  c.userAccount = self.userAccount;
  [self.navigationController pushViewController:c animated:YES];
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
  [self.navigationController pushViewController:c animated:YES];
  c.title = @"Thread";
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
  [bodies release];
  [messagePKs release];
  [mugshots release];
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
 