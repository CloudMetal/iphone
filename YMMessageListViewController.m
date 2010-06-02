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

@end


@implementation YMMessageListViewController

@synthesize target, targetID, olderThan, newerThan, threaded, loadedAvatars, 
            userAccount, selectedIndexPath, limit, rootNavController, shouldUpdateBadge;

- (id)init
{
  if ((self = [super init])) {
    self.title = @"Messages";
    
    self.target = YMMessageTargetAll;
    self.targetID = nil;
    self.olderThan = nil;
    self.newerThan = nil;
    self.threaded = nsnb(NO);
    loadedAvatars = NO;
    shouldRearrangeWhenDeselecting = YES;
    shouldScrollToTop = YES;
    limit = 50;
    shouldUpdateBadge = NO;
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(messagesDidUpdate:) 
     name:YMWebServiceDidUpdateMessages object:nil];
    web = [YMWebService sharedWebService];
  }
  return self;
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
  
  UIView *tf = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 73)] autorelease];
  tf.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  moreButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
  moreButton.frame = CGRectMake(0, 32, 320, 41);
  moreButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  [moreButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
  [moreButton setTitle:@"Show More Messages" forState:UIControlStateNormal];
  moreButton.titleLabel.font = [UIFont systemFontOfSize:13];
  [moreButton setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"inline-button-bg-blue.png"]]];
  [moreButton addTarget:self action:@selector(loadMore:) forControlEvents:UIControlEventTouchUpInside];
  [tf addSubview:moreButton];
  
  totalLoadedLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 32)] retain];
  totalLoadedLabel.text = @"0 Messages Loaded";
  totalLoadedLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  totalLoadedLabel.font = [UIFont boldSystemFontOfSize:13];
  totalLoadedLabel.textColor = [UIColor colorWithWhite:.2 alpha:1];
  totalLoadedLabel.textAlignment = UITextAlignmentCenter;
  totalLoadedLabel.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"inline-button-bg.png"]];
  [tf addSubview:totalLoadedLabel];
  
  self.tableView.tableFooterView = tf;
  
  refreshButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
  refreshButton.frame = CGRectMake(0, 0, 320, 41);
  [refreshButton setImage:[UIImage imageNamed:@"refresh-tiny.png"] forState:UIControlStateNormal];
  refreshButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  [refreshButton setImageEdgeInsets:UIEdgeInsetsMake(0, -20, 0, 0)];
  [refreshButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
  refreshButton.titleLabel.font = [UIFont systemFontOfSize:13];
  [refreshButton setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"inline-button-bg-blue.png"]]];
  [refreshButton setTitle:@"Refresh" forState:UIControlStateNormal];
  [refreshButton addTarget:self action:@selector(refreshFeed:) forControlEvents:UIControlEventTouchUpInside];

  self.tableView.tableFooterView.hidden = YES;
}

- (void) viewWillAppear:(BOOL)animated
{
  self.selectedIndexPath = nil;
  if (!messagePKs || ![messagePKs count]) {
    [self refreshMessagePKs];
    [self.tableView reloadData];
    if (shouldScrollToTop && [messagePKs count]) {
      [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] 
                            atScrollPosition:UITableViewScrollPositionTop animated:YES];
      shouldScrollToTop = NO;
    }
  }
  loadedAvatars = [web didLoadContactImagesForUserAccount:self.userAccount];
  if (!loadedAvatars)
    [[web loadCachedContactImagesForUserAccount:self.userAccount]
     addBoth:callbackTS(self, _imagesLoaded:)];
  viewHasAppeared = YES;
  [super viewWillAppear:animated];
}

- (void) viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  YMNetwork *network = (YMNetwork *)[YMNetwork findByPK:
                       intv(self.userAccount.activeNetworkPK)];
  if (![YMContact countByCriteria:@"WHERE network_i_d=%i",
        intv(network.networkID)]) {
    [[web syncUsers:self.userAccount] addCallback:
     callbackTS(self, doReload:)];
    UIImageView *v = [[UIImageView alloc] initWithImage:
                      [UIImage imageNamed:@"syncing.png"]];
    v.backgroundColor = [UIColor colorWithHexString:@"c2c2c2"];
    v.contentMode = UIViewContentModeCenter;
    v.autoresizingMask = (UIViewAutoresizingFlexibleHeight 
                          | UIViewAutoresizingFlexibleWidth);
    v.frame = self.view.frame;
    lastView = [self.view retain];
    self.view = v;
  } else {
    [self doReload:nil];
  }
}

- (void)viewWillDisappear:(BOOL)animated
{
  [web writeCachedContactImages];
  [self updateNewlyReadMessages];
  [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
  [self updateBadge];
  [super viewDidDisappear:animated];
}

- (void)messagesDidUpdate:(id)note
{
  NSLog(@"%@ got %@", self, note);
  [self doReload:nil];
}

- (id)doReload:(id)arg
{
  if (![self.view isKindOfClass:[UITableView class]] && lastView) {
    self.view = lastView;
    [lastView release];
    lastView = nil;
  }

  [self.tableView reloadData];
  
  DKDeferred *d;
  NSMutableDictionary *opts = [NSMutableDictionary dictionary];
  
  if (self.olderThan)
    [opts setObject:[self.olderThan description] forKey:@"older_than"];
  if (self.newerThan)
    [opts setObject:[self.newerThan description] forKey:@"newer_than"];
  if (PREF_KEY(@"lastSeenMessageID") && [self.target isEqual:YMMessageTargetFollowing])
    [opts setObject:[PREF_KEY(@"lastSeenMessageID") description] 
             forKey:@"update_last_seen_message_id"];
  
  d = [web getMessages:self.userAccount withTarget:target withID:self.targetID 
                params:opts fetchToID:self.newerThan];
  d = [[StatusBarNotifier sharedNotifier] flashLoading:@"Refreshing Messages" deferred:d];
  
  [d addCallback:callbackTS(self, _gotMessages:)];
  [d addErrback:callbackTS(self, _failedGetMessages:)];
  
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
  if ([messagePKs count]) {
    int currentCount = [messagePKs count];
    limit += 100;
    if ([YMMessage countByCriteria:@"%@ LIMIT %i", 
         [self listCriteria], limit] > currentCount) {
      [self refreshMessagePKs];
      [self.tableView reloadData];
      return;
    }
    
    YMMessage *last = (YMMessage *)[YMMessage findByPK:
                              intv([messagePKs lastObject])];
    
    if (last) self.olderThan = last.messageID;
    else self.olderThan = nil;
    if (self.newerThan) self.newerThan = nil;
  }
  [self doReload:nil];
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
  YMComposeViewController *c = [[[YMComposeViewController alloc] init] autorelease];
  c.userAccount = self.userAccount;
  c.network = (YMNetwork *)[YMNetwork findByPK:intv(userAccount.activeNetworkPK)];
  if ([self.target isEqual:YMMessageTargetInGroup]) {
    c.inGroup = (YMGroup *)[YMGroup findFirstByCriteria:
                            @"WHERE group_i_d=%i", intv(self.targetID)];
  }
  [c showFromController:self animated:YES];
}

- (id)_gotMessages:(id)results
{
  NSLog(@"got messages %@", results);
  if (isDeferred(results)) return [results addCallback:callbackTS(self, _gotMessages:)];
  shouldRearrangeWhenDeselecting = NO;
  self.selectedIndexPath = nil;
  shouldRearrangeWhenDeselecting = YES;
  self.tableView.tableFooterView.hidden = NO;
  self.tableView.tableHeaderView = refreshButton;
  [self refreshMessagePKs];
  if ([messagePKs count]) {
    YMMessage *mostRecent = (YMMessage *)[YMMessage findByPK:
                                          intv([messagePKs objectAtIndex:0])];
    PREF_SET(@"lastSeenMessageID", mostRecent.messageID);
  }
  [lastUpdated release];
  lastUpdated = [[NSDate date] retain];
  [refreshButton setTitle:[NSString stringWithFormat:@"Refresh (last updated %@)",
                           [NSDate stringForDisplayFromDate:lastUpdated]] 
                 forState:UIControlStateNormal];
  [self updateBadge];
  [self.tableView reloadData];
  return results;
}

- (id)_failedGetMessages:(NSError *)error
{
  NSLog(@"_failedGetMessages: %@ %@", error, [error userInfo]);
  return error;
}

- (NSString *)listCriteria
{
  return [NSString stringWithFormat:@"WHERE network_p_k=%@ AND target='%@'%@", 
          self.userAccount.activeNetworkPK, target, 
          (targetID != nil ? [NSString stringWithFormat:
                              @" AND target_i_d='%@'", targetID] : @"")];
}

- (void)refreshMessagePKs
{
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
  if (newlyReadMessageIndexes) [newlyReadMessageIndexes release];
  newlyReadMessageIndexes = [[NSMutableIndexSet indexSet] retain];
  if (self.newerThan) self.newerThan = nil;
  
  NSArray *a = [YMMessage pairedArraySelect:[NSString stringWithFormat:
                @"SELECT y_m_message.pk, y_m_contact.mugshot_u_r_l, y_m_contact.full_name, "  
                @"(SELECT full_name FROM y_m_contact AS ymc WHERE " 
                @"y_m_message.replied_to_sender_i_d = ymc.user_i_d), y_m_message.body_plain, "
                @"y_m_message.created_at, y_m_message.read "
                @"FROM y_m_message INNER JOIN y_m_contact ON y_m_message.sender_i_d " 
                @"= y_m_contact.user_i_d %@ ORDER BY y_m_message.created_at DESC LIMIT %i", 
                                             [self listCriteria], limit] fields:7];
  
  messagePKs = [[a objectAtIndex:0] retain];
  mugshotURLs = [[a objectAtIndex:1] retain];
  NSMutableArray *_titles = [NSMutableArray arrayWithCapacity:[messagePKs count]];
  mugshots = [[NSMutableArray arrayWithCapacity:[messagePKs count]] retain];
  bodies = [[a objectAtIndex:4] retain];
  dates = [[a objectAtIndex:5] retain];
  reads = [[a objectAtIndex:6] retain];
  
  [self updateBadge];
  
  for (int i = 0; i < [messagePKs count]; i++) {
    UIImage *img = nil;
    NSString *mugshotUrl = [mugshotURLs objectAtIndex:i];
    if ([mugshotUrl isKindOfClass:
         [NSString class]] && [mugshotUrl length]) {
      img = [[web imageForURLInMemoryCache:mugshotUrl] retain];
    }

    [mugshots addObject:(img ? [img autorelease] : (id)[NSNull null])];
    NSString *tit = [[a objectAtIndex:2] objectAtIndex:i];
    NSString *rtit = [[a objectAtIndex:3] objectAtIndex:i];
    if ([rtit isEqual:[NSNull null]])
      [_titles addObject:tit];
    else 
      [_titles addObject:[tit stringByAppendingFormat:@" re: %@", rtit]];
  }
  titles = [_titles retain];
  if ([messagePKs count])
    self.newerThan = [(YMMessage *)[YMMessage findByPK:
              intv([messagePKs objectAtIndex:0])] messageID];
  else newerThan = nil;
  
  totalLoadedLabel.text = [NSString stringWithFormat:@"%i messages loaded",
                           [messagePKs count]];
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
  if (newlyReadMessageIndexes) [newlyReadMessageIndexes release];
  newlyReadMessageIndexes = [[NSMutableIndexSet indexSetWithIndexesInRange:
                             NSMakeRange(0, [messagePKs count] - 1)] retain];
  [self updateNewlyReadMessages];
}

- (void)updateNewlyReadMessages
{
  NSArray *pks = [messagePKs objectsAtIndexes:newlyReadMessageIndexes];
  SQLiteInstanceManager *db = [SQLiteInstanceManager sharedManager];
  NSString *q = [NSString stringWithFormat:@"UPDATE y_m_message SET read = 1 WHERE pk IN(%@);",
                 [pks componentsJoinedByString:@","]];
  [db executeUpdateSQL:q];
  NSMutableArray *newReads = [NSMutableArray array];
  NSMutableArray *indexPaths = [NSMutableArray array];
  for (int i = 0; i < [newlyReadMessageIndexes count]; i++) {
    [newReads addObject:nsni(1)];
    [indexPaths addObject:[NSIndexPath indexPathForRow:
                           [messagePKs indexOfObject:[pks objectAtIndex:i]] inSection:0]];
  }
  [reads replaceObjectsAtIndexes:newlyReadMessageIndexes withObjects:newReads];
  [newlyReadMessageIndexes release];
  newlyReadMessageIndexes = [[NSMutableIndexSet indexSet] retain];
  [self.tableView reloadRowsAtIndexPaths:indexPaths 
                        withRowAnimation:UITableViewRowAnimationFade];
}

- (NSInteger)rowForIndexPath:(NSIndexPath *)indexPath
{
  int idx;
  if (!selectedIndexPath || indexPath.row <= selectedIndexPath.row) idx = indexPath.row;
  else if (indexPath.row > selectedIndexPath.row) idx = indexPath.row - 1;
  else idx = 0;
  
  return idx;
}

- (CGFloat)expandedHeightOfRow:(NSInteger)idx
{
  CGSize max = CGSizeMake(self.interfaceOrientation 
                          == UIInterfaceOrientationPortrait ? 247 : 407 , 480);
  CGSize sizeNeeded = [[bodies objectAtIndex:idx] sizeWithFont:[UIFont systemFontOfSize:12] 
                       constrainedToSize:max lineBreakMode:UILineBreakModeWordWrap];
  if (sizeNeeded.height > 28.0)
    return sizeNeeded.height + 32.0;
  return 60;
}

- (void) scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
  if (scrollView.decelerating || ![newlyReadMessageIndexes count]) return;
  
  [self updateNewlyReadMessages];
  [self updateBadge];
}

- (void) scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
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
  if (selectedIndexPath && selectedIndexPath.row + 1 == indexPath.row)
    return 60;
  int idx = [self rowForIndexPath:indexPath];
  CGFloat max = self.interfaceOrientation == UIInterfaceOrientationPortrait ? 170 : 115;
  CGFloat h = [self expandedHeightOfRow:idx];
  if (h > max && (!selectedIndexPath || 
      !(selectedIndexPath.row == idx)))
    return max;
  return h;
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
    YMMessageCompanionTableViewCell *cell;
    for (id v in [[NSBundle mainBundle] loadNibNamed:
                  @"YMMessageCompanionTableViewCell" owner:nil options:nil]) {
      if (![v isKindOfClass:[YMMessageCompanionTableViewCell class]]) 
        continue;
      cell = v;
      break;
    }
    NSIndexPath *onActionIndex = [NSIndexPath indexPathForRow:indexPath.row - 1 inSection:0];
    cell.onUser = curryTS(self, @selector(gotoUserIndexPath:sender:), onActionIndex);
    cell.onMore = curryTS(self, @selector(gotoMessageIndexPath:sender:), onActionIndex);
    cell.onThread = curryTS(self, @selector(gotoThreadIndexPath:sender:), onActionIndex);
    cell.onReply = curryTS(self, @selector(gotoReplyIndexPath:sender:), onActionIndex);
    return cell;
  }
  
  int idx = [self rowForIndexPath:indexPath];
  if (idx >= [messagePKs count]) return nil;
  
  static NSString *ident = @"YMMessageCell1";
  
  YMFastMessageTableViewCell *cell = (YMFastMessageTableViewCell *)
    [table dequeueReusableCellWithIdentifier:ident];
  if (!cell) cell = [[[YMFastMessageTableViewCell alloc] initWithFrame:
                      CGRectMake(0, 0, 320, 72) reuseIdentifier:ident] autorelease];
  
  id read = [reads objectAtIndex:idx];
  if ([read isKindOfClass:[NSObject class]] && !intv(read)) {
    [newlyReadMessageIndexes addIndex:idx];
    cell.unread = YES;
  } else {
    cell.unread = NO;
  }
  
  id img = [mugshots objectAtIndex:idx];
  if (![img isKindOfClass:[UIImage class]]) {
    img = [UIImage imageNamed:@"user-70.png"];
    NSString *ms = [mugshotURLs objectAtIndex:idx];
    if (!loadedAvatars) { // do nothing if we haven't yet loaded
    } else if ([ms isKindOfClass:[NSString class]] && [ms length]) {
      [[web contactImageForURL:ms]
       addCallback:curryTS(self, @selector(_gotMugshot::), indexPath)];
    }
  }

  cell.avatar = img;
  cell.body = [bodies objectAtIndex:idx];
  cell.date = [NSDate fastStringForDisplayFromDate:
               [NSDate objectWithSqlColumnRepresentation:[dates objectAtIndex:idx]]];
  cell.title = [titles objectAtIndex:idx];
  
  return cell;
}

- (void) tableView:(UITableView *)table
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  self.selectedIndexPath = [NSIndexPath indexPathForRow:
                            [self rowForIndexPath:indexPath] inSection:0];
}

- (NSIndexPath *)tableView:(UITableView *)table
willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (selectedIndexPath) {
    if (selectedIndexPath.row + 1 == indexPath.row) return nil;
    if (selectedIndexPath.row == indexPath.row) {
      [self.tableView deselectRowAtIndexPath:self.selectedIndexPath animated:YES];
      self.selectedIndexPath = nil;
      return nil;
    }
  }
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
//    if (shouldRearrangeWhenDeselecting) {
        [self.tableView deleteRowsAtIndexPaths:array_(previousCompanionIndexPath)
                            withRowAnimation:UITableViewRowAnimationTop];
        [self.tableView reloadRowsAtIndexPaths:array_(previousIndexPath)
                            withRowAnimation:UITableViewRowAnimationNone];
//    }
  }
  selectedIndexPath = [indexPath retain];
  if (selectedIndexPath) {
    NSIndexPath *companionPath = [NSIndexPath indexPathForRow:selectedIndexPath.row+1 inSection:0];
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
}

- (id)_gotMugshot:(NSIndexPath *)indexPath :(id)result
{  
  if ([result isKindOfClass:[UIImage class]]) {
    int idx = [self rowForIndexPath:indexPath];
    loadedAvatars = YES;
    [mugshots replaceObjectAtIndex:idx withObject:result];
    YMFastMessageTableViewCell *cell = (YMFastMessageTableViewCell *)
    [self.tableView cellForRowAtIndexPath:
     [NSIndexPath indexPathForRow:idx inSection:0]];
    if (cell) cell.avatar = result;
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
                                       initWithStyle:UITableViewStyleGrouped]
                                      autorelease];
  c.contact = contact;
  c.userAccount = self.userAccount;
  [self.navigationController pushViewController:c animated:YES];
  return nil;
}

- (id)gotoMessageIndexPath:(NSIndexPath *)indexPath sender:(id)s
{
  int idx = [self rowForIndexPath:indexPath];
  YMMessage *m = (YMMessage *)[YMMessage findByPK:intv([messagePKs objectAtIndex:idx])];
  YMMessageDetailViewController *c = [[[YMMessageDetailViewController alloc]
                                       initWithStyle:UITableViewStyleGrouped]
                                      autorelease];
  c.message = m;
  c.userAccount = self.userAccount;
  [self.navigationController pushViewController:c animated:YES];
  return nil;
}

- (id)gotoThreadIndexPath:(NSIndexPath *)indexPath sender:(id)s
{
  int idx = [self rowForIndexPath:indexPath];
  YMMessage *m = (YMMessage *)[YMMessage findByPK:intv([messagePKs objectAtIndex:idx])];
  YMMessageListViewController *c = [[[YMMessageListViewController alloc] init] autorelease];
  c.userAccount = self.userAccount;
  c.target = YMMessageTargetInThread;
  c.targetID = m.threadID;
  [self.navigationController pushViewController:c animated:YES];
  c.title = @"Thread";
  return nil;
}

- (id)gotoReplyIndexPath:(NSIndexPath *)indexPath sender:(id)s
{
  YMComposeViewController *c = [[[YMComposeViewController alloc] init] autorelease];
  c.userAccount = self.userAccount;
  c.network = (YMNetwork *)[YMNetwork findByPK:intv(userAccount.activeNetworkPK)];
  c.inReplyTo = (YMMessage *)[YMMessage findByPK:intv([messagePKs objectAtIndex:indexPath.row])];
  
  [c showFromController:self animated:YES];
  return nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:
(UIInterfaceOrientation)interfaceOrientation
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
  [bodies release];
  [messagePKs release];
  [mugshots release];
  [dates release];
  [titles release];
  [[NSNotificationCenter defaultCenter]
   removeObserver:self];
  self.target = nil;
  self.threaded = nil;
  self.newerThan = nil;
  self.userAccount = nil;
  self.olderThan = nil;
  self.targetID = nil;
  [selectedIndexPath release];
  self.tableView = nil;
  [super dealloc];
}

@end
