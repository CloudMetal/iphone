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
  self.tableView = [[UITableView alloc] initWithFrame:
                    CGRectMake(0, 0, 320, 460) style:UITableViewStylePlain];
  self.tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                     UIViewAutoresizingFlexibleHeight);
  self.tableView.delegate = self;
  self.tableView.dataSource = self;
  self.tableView.backgroundColor = [UIColor whiteColor];
  self.title = @"Feeds";
  
  if (!web) web = [YMWebService sharedWebService];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [self refreshFeeds];
  [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  if (!didUpdateSubscriptions) 
    [[[StatusBarNotifier sharedNotifier]
      flashLoading:@"Refreshing Subscriptions" deferred:
      [web syncGroups:self.userAccount]]
     addCallback:callbackTS(self, updatedGroups:)];
}

-(void) refreshFeeds
{
  if (feeds) [feeds release];
  feeds = nil;
  feeds = [[[self builtinFeeds] arrayByAddingObjectsFromArray:
            [YMGroup findByCriteria:@"WHERE network_i_d=%i", 
             intv(network.networkID)]] retain];
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
                array_(YMMessageTargetSent, [NSNull null], @"Sent", @"page_edit.png"),
                array_(YMMessageTargetFavoritesOf, network.userID, @"Favorites", @"heart.png"));
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
  static NSString *ident = @"YMFeedCell1";
  UITableViewCell *cell = [table dequeueReusableCellWithIdentifier:ident];
  if (!cell) {
    cell = [[[UITableViewCell alloc]
              initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ident]
             autorelease];
    cell.textLabel.font = [UIFont systemFontOfSize:16];
  }
  if ([[feeds objectAtIndex:indexPath.row] isKindOfClass:[NSArray class]]) {
    cell.imageView.image = [UIImage imageNamed:[[feeds objectAtIndex:indexPath.row] objectAtIndex:3]];
    cell.textLabel.text = [[feeds objectAtIndex:indexPath.row] objectAtIndex:2];
  } else {
    cell.imageView.image = [UIImage imageNamed:@"group.png"];
    cell.textLabel.text = ((YMGroup *)[feeds objectAtIndex:indexPath.row]).fullName;
  }
  return cell;
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
(UIInterfaceOrientation)interfaceOrientation {
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
