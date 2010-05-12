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

@interface YMMessageListViewController (PrivateStuffs)

- (NSString *)listCriteria;
- (void)refreshMessagePKs;
- (id)doReload:(id)arg;

@end


@implementation YMMessageListViewController

@synthesize target, targetID, olderThan, newerThan, threaded, userAccount;

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
  
  self.title = @"Messages";
  
  self.target = YMMessageTargetAll;
  self.targetID = nil;
  self.olderThan = nil;
  self.newerThan = nil;
  self.threaded = nsnb(NO);
  loadedAvatars = NO;
  
  if (!web) web = [YMWebService sharedWebService];
}

- (void) viewWillAppear:(BOOL)animated
{
  [self refreshMessagePKs];
}

- (void) viewDidAppear:(BOOL)animated
{
  loadedAvatars = NO;
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

- (id)doReload:(id)arg
{
  if (![self.view isKindOfClass:[UITableView class]] && lastView) {
    self.view = lastView;
    [lastView release];
    lastView = nil;
  }
  if (!loadedAvatars)
    return [[web loadCachedContactImagesForUserAccount:self.userAccount]
            addCallback:callbackTS(self, _imagesLoaded:)];
  [self.tableView reloadData];
  [[StatusBarNotifier sharedNotifier] flashLoading:@"Refreshing Messages" 
     deferred:[[[web getMessages:self.userAccount params:EMPTY_DICT]
    addCallback:curryTS(self, @selector(_gotMessages::::), 
                        self.userAccount, self.target, 
                        (self.targetID == nil ? (id)[NSNull null] : self.targetID))]
   addErrback:callbackTS(self, _failedGetMessages:)]];
  
  return arg;
}

- (id)_imagesLoaded:(id)arg
{
  loadedAvatars = YES;
  [self doReload:nil];
  return arg;
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

- (id)_gotMessages:(YMUserAccount *)acct :(id)_target :(id)_targetID :(id)results 
{
  [self refreshMessagePKs];
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
  if (messagePKs) [messagePKs release];
  messagePKs = nil;
  messagePKs = [[[YMMessage pairedArraysForProperties:
                  EMPTY_ARRAY withCriteria:[self listCriteria]] 
                 objectAtIndex:0] retain];
  if (mugshots) [mugshots release];
  mugshots = nil;
  mugshots = [[NSMutableArray arrayWithCapacity:[messagePKs count]] retain];
  for (int i = 0; i < [messagePKs count]; i++)
    [mugshots addObject:[NSNull null]];
}

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

- (CGFloat) tableView:(UITableView *)table
heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  return 60;
}

- (NSInteger) tableView:(UITableView *)table
  numberOfRowsInSection:(NSInteger)section
{
  return [messagePKs count];
}

- (UITableViewCell *) tableView:(UITableView *)table
cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *ident = @"YMMessageCell1";
  YMMessage *message = (YMMessage *)[YMMessage findByPK:
         intv([messagePKs objectAtIndex:indexPath.row])];
  YMContact *c = (YMContact *)[YMContact findFirstByCriteria:
                                     @"WHERE user_i_d=%i", intv(message.senderID)];
  
  YMMessageTableViewCell *cell = (YMMessageTableViewCell *)
    [table dequeueReusableCellWithIdentifier:ident];
  if (!cell) {
    for (UIView *v in [[NSBundle mainBundle] loadNibNamed:
                       @"YMMessageTableViewCell" owner:nil options:nil]) {
      if (![v isMemberOfClass:
            [YMMessageTableViewCell class]]) continue;
      cell = (YMMessageTableViewCell *)v;
      break;
    }
  }
  
  UIImage *img;
  if (!c.mugshotURL || [c.mugshotURL isEqual:[NSNull null]] 
      || ![c.mugshotURL length] 
      || !(img = [[YMWebService sharedWebService]
                  imageForURLInMemoryCache:c.mugshotURL])
      || (![[mugshots objectAtIndex:indexPath.row] isEqual:[NSNull null]] 
          && (img = [mugshots objectAtIndex:indexPath.row]))
      || (![[web contactImageForURL:c.mugshotURL] 
           addCallback:curryTS(self, @selector(_gotMugshot::), indexPath)]))
    img = [UIImage imageNamed:@"user-70.png"];
  
  cell.avatarImageView.image = img;
  cell.bodyLabel.text = message.bodyPlain;
  cell.titleLabel.text = (c.fullName ? c.fullName : c.username);
  cell.dateLabel.text = [message.createdAt stringDaysAgo];
  
  return cell;
}

- (id)_gotMugshot:(NSIndexPath *)indexPath :(id)result
{
  if ([result isKindOfClass:[UIImage class]]) {
    [mugshots replaceObjectAtIndex:indexPath.row withObject:result];
    YMMessageTableViewCell *cell = (YMMessageTableViewCell *)
    [self.tableView cellForRowAtIndexPath:indexPath];
    if (cell) cell.avatarImageView.image = result;
  }
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
