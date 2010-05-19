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


@interface YMMessageListViewController (PrivateStuffs)

- (NSString *)listCriteria;
- (void)refreshMessagePKs;
- (id)doReload:(id)arg;
- (NSInteger)rowForIndexPath:(NSIndexPath *)indexPath;
- (CGFloat)expandedHeightOfRow:(NSInteger)idx;

@end


@implementation YMMessageListViewController

@synthesize target, targetID, olderThan, newerThan, threaded, userAccount, selectedIndexPath;

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
  UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:
                            UIBarButtonSystemItemFixedSpace target:nil action:nil];
  space.width = 10;
  self.toolbarItems = 
    array_([[UIBarButtonItem alloc]
            initWithImage:[UIImage imageNamed:@"104-index-cards.png"] style:UIBarButtonItemStylePlain 
            target:self action:@selector(gotoUsers:)],
           space,
           [[UIBarButtonItem alloc]
            initWithImage:[UIImage imageNamed:@"20-gear2.png"] style:UIBarButtonItemStylePlain
            target:self action:@selector(gotoSettings:)],
           [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace 
            target:nil action:nil],
           [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemCompose 
            target:self action:@selector(composeNew:)]);
  
  UIView *tf = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 76)] autorelease];
  tf.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  moreButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
  moreButton.frame = CGRectMake(0, 32, 320, 44);
  moreButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  [moreButton setTitleColor:[UIColor colorWithHexString:@"646464"] forState:UIControlStateNormal];
  [moreButton setTitle:@"Load More" forState:UIControlStateNormal];
  moreButton.titleLabel.font = [UIFont boldSystemFontOfSize:14];
  [moreButton setBackgroundColor:[UIColor colorWithHexString:@"f2f2f2"]];
  [moreButton addTarget:self action:@selector(loadMore:) forControlEvents:UIControlEventTouchUpInside];
  [tf addSubview:moreButton];
  
  totalLoadedLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 32)] retain];
  totalLoadedLabel.text = @"0 Messages Loaded";
  totalLoadedLabel.font = [UIFont boldSystemFontOfSize:13];
  totalLoadedLabel.textAlignment = UITextAlignmentCenter;
  totalLoadedLabel.backgroundColor = [UIColor whiteColor];
  [tf addSubview:totalLoadedLabel];
  
  self.tableView.tableFooterView = tf;
  
  refreshButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
  refreshButton.frame = CGRectMake(0, 0, 320, 44);
  [refreshButton setImage:[UIImage imageNamed:@"refresh.png"] forState:UIControlStateNormal];
  refreshButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  [refreshButton setImageEdgeInsets:UIEdgeInsetsMake(0, -20, 0, 0)];
  [refreshButton setTitleColor:[UIColor colorWithHexString:@"646464"] forState:UIControlStateNormal];
  refreshButton.titleLabel.font = [UIFont systemFontOfSize:13];
  [refreshButton setBackgroundColor:[UIColor colorWithHexString:@"f2f2f2"]];
  [refreshButton setTitle:@"Refresh" forState:UIControlStateNormal];
  [refreshButton addTarget:self action:@selector(refreshFeed:) forControlEvents:UIControlEventTouchUpInside];
  self.tableView.tableHeaderView = refreshButton;
  
  if (!web) web = [YMWebService sharedWebService];
}

- (void) viewWillAppear:(BOOL)animated
{
  self.selectedIndexPath = nil;
  [self refreshMessagePKs];
  if (!loadedAvatars)
    [[web loadCachedContactImagesForUserAccount:self.userAccount]
     addCallback:callbackTS(self, _imagesLoaded:)];
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
  if (shouldScrollToTop && [messagePKs count]) {
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] 
                          atScrollPosition:UITableViewScrollPositionTop animated:YES];
    shouldScrollToTop = NO;
  }
}

- (void)viewWillDisappear:(BOOL)animated
{
  [web writeCachedContactImages];
  [super viewWillDisappear:animated];
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
  
  if (olderThan)
    [opts setObject:[olderThan description] forKey:@"older_than"];
  if (newerThan)
    [opts setObject:[newerThan description] forKey:@"newer_than"];
  if (PREF_KEY(@"lastSeenMessageID"))
    [opts setObject:[PREF_KEY(@"lastSeenMessageID") description] 
             forKey:@"last_seen_message_id"];
  
  d = [web getMessages:self.userAccount withTarget:target withID:targetID 
                params:opts fetchToID:newerThan];
  [d addCallback:callbackTS(self, _gotMessages:)];
  [d addErrback:callbackTS(self, _failedGetMessages:)];
  [[StatusBarNotifier sharedNotifier] flashLoading:@"Refreshing Messages" deferred:d];
  
  return arg;
}

- (id)_imagesLoaded:(id)arg
{
  NSLog(@"images loaded");
  loadedAvatars = YES;
  [self doReload:nil];
  return arg;
}

- (void)loadMore:(id)sender
{
  if ([messagePKs count]) {
    YMMessage *last = (YMMessage *)[YMMessage findByPK:
                                    intv([messagePKs lastObject])];
    if (last)
      olderThan = [last.messageID retain];
    else
      olderThan = nil;
    if (newerThan)
      newerThan = nil;
  }
  [self doReload:nil];
}

- (void)refreshFeed:(id)sender
{
  if ([messagePKs count]) {
    YMMessage *first = (YMMessage *)[YMMessage findByPK:
                                     intv([messagePKs objectAtIndex:0])];
    if (first)
      newerThan = [first.messageID retain];
    else
      newerThan = nil;
    if (olderThan)
      olderThan = nil;
  }
  [self doReload:nil];
}

- (void)gotoUsers:(id)sender
{
  [[web loadCachedContactImagesForUserAccount:self.userAccount]
   addCallback:callbackTS(self, _gotoUsers:)];
}

- (id)_gotoUsers:(id)r
{
  YMContactsListViewController *c =
  [[[YMContactsListViewController alloc]
    initWithStyle:UITableViewStylePlain] autorelease];
  
  c.userAccount = self.userAccount;
  [self.navigationController pushViewController:c animated:YES];
  
  return r;
}

- (void)gotoSettings:(id)sender
{
}

- (void)composeNew:(id)sender
{
}

- (id)_gotMessages:(id)results
{
  shouldRearrangeWhenDeselecting = NO;
  self.selectedIndexPath = nil;
  shouldRearrangeWhenDeselecting = YES;
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
  // this is optimized more for speed than clarity...
  if (messagePKs) [messagePKs release];
  messagePKs = nil;
  if (titles) [titles release];
  titles = nil;
  if (mugshotURLs) [mugshotURLs release];
  mugshotURLs = nil;
  if (mugshots) [mugshots release];
  mugshots = nil;
  if (newerThan) [newerThan release];
  newerThan = nil;
  
  NSArray *a = [YMMessage pairedArraySelect:[NSString stringWithFormat:
                @"SELECT y_m_message.pk, y_m_contact.mugshot_u_r_l, y_m_contact.full_name, "
                @"(SELECT full_name FROM y_m_contact AS ymc WHERE " 
                @"y_m_message.replied_to_sender_i_d=ymc.user_i_d) "
                @"FROM y_m_message INNER JOIN y_m_contact ON y_m_message.sender_i_d " 
                @"= y_m_contact.user_i_d %@ ORDER BY y_m_message.created_at DESC ", 
                                             [self listCriteria]] fields:4];
  
  messagePKs = [[a objectAtIndex:0] retain];
  mugshotURLs = [[a objectAtIndex:1] retain];
  NSMutableArray *_titles = [NSMutableArray arrayWithCapacity:[messagePKs count]];
  mugshots = [[NSMutableArray arrayWithCapacity:[messagePKs count]] retain];
  
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
    newerThan = [[(YMMessage *)[YMMessage findByPK:
              intv([messagePKs objectAtIndex:0])] messageID] retain];
  else newerThan = nil;
  
  totalLoadedLabel.text = [NSString stringWithFormat:@"%i messages loaded",
                           [messagePKs count]];
}

- (NSInteger)rowForIndexPath:(NSIndexPath *)indexPath
{
  int idx;
  if (!selectedIndexPath || indexPath.row <= (selectedIndexPath.row - 1)
      || selectedIndexPath.row == indexPath.row) idx = indexPath.row;
  else if (indexPath.row > selectedIndexPath.row) idx = indexPath.row + 1;
  else idx = 0;
  
  return idx;
}

- (CGFloat)expandedHeightOfRow:(NSInteger)idx
{
  YMMessage *message = (YMMessage *)[YMMessage findByPK:
                       intv([messagePKs objectAtIndex:idx])];
  CGSize max = CGSizeMake(self.interfaceOrientation 
                          == UIInterfaceOrientationPortrait ? 247 : 407 , 480);
  CGSize sizeNeeded = [message.bodyPlain sizeWithFont:[UIFont systemFontOfSize:11] 
                       constrainedToSize:max lineBreakMode:UILineBreakModeWordWrap];
  if (sizeNeeded.height > 28.0)
    return sizeNeeded.height + 32.0;
  return 60.0;
}

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

- (CGFloat) tableView:(UITableView *)table
heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (selectedIndexPath && selectedIndexPath.row == indexPath.row)
    return [self expandedHeightOfRow:indexPath.row];
  return 60;
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
    return cell;
  }
  
  int idx = [self rowForIndexPath:indexPath];
  if (idx >= [messagePKs count]) return nil;
  
  static NSString *ident = @"YMMessageCell1";
  YMMessage *message = (YMMessage *)[YMMessage findByPK:
         intv([messagePKs objectAtIndex:idx])]; // TODO: sometimes this crashes
  
  YMFastMessageTableViewCell *cell = (YMFastMessageTableViewCell *)
    [table dequeueReusableCellWithIdentifier:ident];
  if (!cell) cell = [[[YMFastMessageTableViewCell alloc] initWithFrame:
                      CGRectMake(0, 0, 320, 60) reuseIdentifier:ident] autorelease];
  
  cell.avatar = [UIImage imageNamed:@"user-70.png"];
  id img = [mugshots objectAtIndex:idx];
  NSString *ms = [mugshotURLs objectAtIndex:idx];
  if ([img isEqual:[NSNull null]]) {
    if (!loadedAvatars) { // do nothing if we haven't yet loaded
    } else if ([ms isKindOfClass:[NSString class]] && [ms length]) {
      [[web contactImageForURL:ms]
       addCallback:curryTS(self, @selector(_gotMugshot::), indexPath)];
    } else {
      [mugshots replaceObjectAtIndex:idx withObject:[UIImage imageNamed:@"user-70.png"]];
    }
  } else {
    cell.avatar = img;
  }

  cell.body = message.bodyPlain;
  cell.date = [NSDate stringForDisplayFromDate:message.createdAt];
  cell.title = [titles objectAtIndex:idx];
  
  return cell;
}

- (void) tableView:(UITableView *)table
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  self.selectedIndexPath = indexPath;
  [self.tableView reloadRowsAtIndexPaths:array_(self.selectedIndexPath)
                        withRowAnimation:UITableViewRowAnimationNone];
}

- (NSIndexPath *)tableView:(UITableView *)table
willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (selectedIndexPath) {
//    int idx = [self rowForIndexPath:indexPath];
//    if (selectedIndexPath.row + 1 == idx) return nil;
    if (selectedIndexPath.row + 1 == indexPath.row) return nil;
    self.selectedIndexPath = nil;
    return nil;
  }
  return indexPath;
}

- (void)setSelectedIndexPath:(NSIndexPath *)indexPath
{
  if (selectedIndexPath) {
    NSIndexPath *previousIndexPath = [selectedIndexPath retain];
    [selectedIndexPath release];
    selectedIndexPath = nil;
    if (shouldRearrangeWhenDeselecting) {
//      [self.tableView scr
      [self.tableView deleteRowsAtIndexPaths:
       array_([NSIndexPath indexPathForRow:previousIndexPath.row+1 inSection:0])
                            withRowAnimation:UITableViewRowAnimationNone];
      [self.tableView reloadRowsAtIndexPaths:array_(previousIndexPath)
                            withRowAnimation:UITableViewRowAnimationNone];
    }
    [previousIndexPath release];
  }
  selectedIndexPath = [indexPath retain];
  if (selectedIndexPath) {
    [self.tableView insertRowsAtIndexPaths:
     array_([NSIndexPath indexPathForRow:indexPath.row+1 inSection:0])
                          withRowAnimation:UITableViewRowAnimationBottom];
  }
}

- (id)_gotMugshot:(NSIndexPath *)indexPath :(id)result
{
  int idx = [self rowForIndexPath:indexPath];
  if ([result isKindOfClass:[UIImage class]]) {
    [mugshots replaceObjectAtIndex:idx withObject:result];
    YMFastMessageTableViewCell *cell = (YMFastMessageTableViewCell *)
    [self.tableView cellForRowAtIndexPath:
     [NSIndexPath indexPathForRow:idx inSection:0]];
    if (cell) cell.avatar = result;
  }
  return nil;
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
  self.tableView = nil;
  [super dealloc];
}

@end
