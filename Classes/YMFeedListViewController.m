    //
//  YMFeedListViewController.m
//  Yammer
//
//  Created by Samuel Sutch on 5/25/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "YMFeedListViewController.h"
#import "YMWebService.h"
#import "StatusBarNotifier.h"
#import "YMMessageListViewController.h"

@interface YMFeedListViewController (PrivateParts)

- (NSArray *)builtinFeeds;
- (void)refreshFeeds;

@end


@implementation YMFeedListViewController

@synthesize userAccount, network;

- (void)loadView
{
  self.actionTableViewHeaderClass = NULL;
//  self.useSubtitleHeader = YES;
  self.tableView = [[UITableView alloc] initWithFrame:
                    CGRectMake(0, 0, 320, 460) style:UITableViewStylePlain];
  self.tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                     UIViewAutoresizingFlexibleHeight);
  self.tableView.delegate = self;
  self.tableView.dataSource = self;
  self.tableView.backgroundColor = [UIColor whiteColor];
  self.title = @"Feeds";
  
  [[NSNotificationCenter defaultCenter]
   addObserver:self selector:@selector(subscriptionsDidUpdate:) 
   name:YMWebServiceDidUpdateSubscriptions object:nil];
  
  if (!web) web = [YMWebService sharedWebService];
}

- (void)subscriptionsDidUpdate:(NSNotification *)note
{
  [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [self refreshFeeds];
  [self.tableView reloadData];
  [self setHeaderTitle:self.title andSubtitle:self.network.name];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  if (!didUpdateSubscriptions) 
    [[[StatusBarNotifier sharedNotifier]
      flashLoading:@"Refreshing Subscriptions" deferred:
      [web syncSubscriptions:self.userAccount]]
     addCallback:callbackTS(self, updatedGroups:)];
}

-(void)refreshFeeds
{
  if (feeds) [feeds release];
  feeds = nil;
  if (mugshots) [mugshots release];
  mugshots = nil;
  
  NSMutableArray *_feeds = [NSMutableArray array];
  NSArray *memberships = self.network.groupSubscriptionIds;
  NSMutableArray *_mugshots = [NSMutableArray array];
  
  for (YMGroup *g in [[YMGroup findByCriteria:@"WHERE network_i_d=%i", 
                      intv(network.networkID)] reverseObjectEnumerator]) {
    if ([memberships containsObject:g.groupID]) {
      [_feeds insertObject:g atIndex:0];
    } else {
      [_feeds addObject:g];
    }
  }
  
  feeds = [[[self builtinFeeds] arrayByAddingObjectsFromArray:_feeds] retain];
  
  for (id obj in feeds) {
    id img = [NSNull null];
    if ([obj isKindOfClass:[YMGroup class]] && [obj mugshotURL] &&
        !(img = [web imageForURLInMemoryCache:[obj mugshotURL]])) {
      if (![obj mugshotURL] || [[obj mugshotURL] isMatchedByRegex:
                                @"group_profile_small\\.gif$"])
        img = @"__ni__";
      if (!img) img = [NSNull null];
    }
    [_mugshots addObject:img];
  }
  mugshots = [_mugshots retain];
}

- (id)updatedGroups:(id)r
{
  didUpdateSubscriptions = YES;
  [self refreshFeeds];
  [self.tableView reloadData];
  return r;
}

- (NSArray *) builtinFeeds 
{
  return array_(
    array_(YMMessageTargetAll, [NSNull null], @"All", @"world.png"),
    array_(YMMessageTargetSent, [NSNull null], @"Sent", @"envelope.png"),
    array_(YMMessageTargetFavoritesOf, network.userID, @"Bookmarks", @"heart.png"));
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

- (NSInteger) tableView:(UITableView *)table 
numberOfRowsInSection:(NSInteger)section
{
  return [feeds count];
}

- (UITableViewCell *) tableView:(UITableView *)table
cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *aident = @"YMFeedCell1";
  static NSString *bident = @"YMBuildinFeedCell1";
  BOOL builtin = [[feeds objectAtIndex:indexPath.row] isKindOfClass:[NSArray class]];
  NSString *ident = builtin ? bident : aident;
  UITableViewCell *cell = [table dequeueReusableCellWithIdentifier:ident];
  if (!cell) {
    cell = [[[UITableViewCell alloc]
              initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ident]
             autorelease];
    cell.textLabel.font = [UIFont systemFontOfSize:16];
//    if (!builtin) {
//      UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
//      b.frame = CGRectMake(250, 6, 60, 32);
//      b.autoresizingMask = UIViewAutoresizingFlexibleWidth;
//      b.tag = 1010;
//      [b setBackgroundImage:[[UIImage imageNamed:@"blue-button-bg.png"] 
//                             stretchableImageWithLeftCapWidth:5 topCapHeight:5]
//                   forState:UIControlStateNormal];
//      b.titleLabel.font = [UIFont systemFontOfSize:15];
//      [b setTitleShadowColor:[UIColor colorWithWhite:.1 alpha:.9] 
//                    forState:UIControlStateNormal];
//      b.showsTouchWhenHighlighted = YES;
//      [cell addSubview:b];
//    }
  }
  if (builtin) {
    cell.imageView.image = [UIImage imageNamed:[[feeds objectAtIndex:indexPath.row] objectAtIndex:3]];
    cell.textLabel.text = [[feeds objectAtIndex:indexPath.row] objectAtIndex:2];
  } else {
    YMGroup *group = [feeds objectAtIndex:indexPath.row];
    id img = [mugshots objectAtIndex:indexPath.row];
    if ([img isEqual:[NSNull null]] || [img isEqual:@"__ni__"]) {
      if ([img isEqual:[NSNull null]])
        [[web contactImageForURL:group.mugshotURL]
         addCallback:curryTS(self, @selector(_gotMugshot::), indexPath)];
      img = [UIImage imageNamed:@"group.png"];
    }
    cell.imageView.image = img;
    cell.textLabel.text = group.fullName;
    
//    UIButton *b = (UIButton *)[cell viewWithTag:1010];
//    if ([self.network.groupSubscriptionIds containsObject:group.groupID]) {
//      [b addTarget:[curryTS(self, @selector(_unjoin::), group) retain]
//            action:@selector(:) forControlEvents:UIControlEventTouchUpInside];
//      [b setTitle:@"Leave" forState:UIControlStateNormal];
//    } else {
//      [b addTarget:[curryTS(self, @selector(_join::), group) retain]
//            action:@selector(:) forControlEvents:UIControlEventTouchUpInside];
//      [b setTitle:@"Join" forState:UIControlStateNormal];
//    }
  }
  return cell;
}

- _unjoin:(YMGroup *)group :(id)sender
{
  [[[StatusBarNotifier sharedNotifier] flashLoading:@"Leaving Group" deferred:
    [web joinGroup:self.userAccount withId:intv(group.groupID)]]
   addCallback:curryTS(self, @selector(_didUnjoinGroup::), group)];
  return nil;
}

- _didUnjoinGroup:(YMGroup *)group :(id)r
{
  NSMutableArray *ar = [self.network.groupSubscriptionIds mutableCopy];
  [ar removeObject:group.groupID];
  self.network.groupSubscriptionIds = ar;
  [self.network save];
  [self.tableView reloadData];
  return r;
}

- _join:(YMGroup *)group :(id)sender
{
  [[[StatusBarNotifier sharedNotifier] flashLoading:@"Joining Group" deferred:
    [web joinGroup:self.userAccount withId:intv(group.groupID)]]
   addCallback:curryTS(self, @selector(_didJoinGroup::), group)];
  return nil;
}

- _didJoinGroup:(YMGroup *)group :(id)r
{
  NSMutableArray *ar = [self.network.groupSubscriptionIds mutableCopy];
  [ar addObject:group.groupID];
  self.network.groupSubscriptionIds = ar;
  [self.network save];
  [self.tableView reloadData];
  return r;
}

- (id)_gotMugshot:(NSIndexPath *)indexPath :(UIImage *)img
{
  if ([img isKindOfClass:[UIImage class]]) {
    [mugshots replaceObjectAtIndex:indexPath.row withObject:img];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (cell) cell.imageView.image = img;
  }
  return img;
}

- (void) tableView:(UITableView *)table
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  YMMessageListViewController *c = [[[YMMessageListViewController alloc] init] autorelease];
  BOOL showCompose = NO;
  NSString *t = @"Messages";
  
  if ([[feeds objectAtIndex:indexPath.row] isKindOfClass:[NSArray class]]) {
    c.target = [[feeds objectAtIndex:indexPath.row] objectAtIndex:0];
    if (![[[feeds objectAtIndex:indexPath.row] objectAtIndex:1] isEqual:[NSNull null]])
      c.targetID = [[feeds objectAtIndex:indexPath.row] objectAtIndex:1];
    else
      c.targetID = nil;
    t = [[feeds objectAtIndex:indexPath.row] objectAtIndex:2];
  } else {
    showCompose = YES;
    YMGroup *group = (YMGroup *)[feeds objectAtIndex:indexPath.row];
    c.target = YMMessageTargetInGroup;
    c.targetID = group.groupID;
    t = group.fullName;
  }
  if ([c.target isEqual:YMMessageTargetAll])
    showCompose = YES;
  c.userAccount = self.userAccount;
  c.network = self.network;
  c.title = t;
  
  [self.navigationController pushViewController:c animated:YES];

  if (showCompose)
    c.navigationItem.rightBarButtonItem = 
      [[UIBarButtonItem alloc]
       initWithBarButtonSystemItem:UIBarButtonSystemItemCompose 
       target:c action:@selector(composeNew:)];
  [table deselectRowAtIndexPath:indexPath animated:YES];
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
