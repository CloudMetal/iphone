    //
//  YMNetworksViewController.m
//  Yammer
//
//  Created by Samuel Sutch on 4/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "YMNetworksViewController.h"
#import "YMWebService.h"
#import "YMAccountsViewController.h"
#import "UIColor+Extensions.h"
#import "YMNetworkTableViewCell.h"
#import "YMMessageListViewController.h"
#import "CFPrettyView.h"
#import "StatusBarNotifier.h"
#import "UIColor+Extensions.h"
#import "YMContactsListViewController.h"
#import "YMFeedListViewController.h"

#import "YammerAppDelegate.h"


@implementation YMNetworksViewController

@synthesize web;

- (IBAction)gotoAccounts:(UIControl *)sender
{
  [self.navigationController pushViewController:
   [[[YMAccountsViewController alloc] init] autorelease] animated:YES];
}

- (void)refreshNetworks
{
  [self.tableView reloadData];
  
  NSArray *accounts = [YMUserAccount allObjects];
  NSMutableArray *ops = [NSMutableArray array];
  for (YMUserAccount *acct in accounts) {
    [ops addObject:[web networksForUserAccount:acct]];
  }
  [[[StatusBarNotifier sharedNotifier] 
    flashLoading:@"Updating Networks..."
    deferred:[DKDeferred gatherResults:ops]]
   addCallback:callbackTS(self, doneUpdatingAccounts:)];
}

- (id)doneUpdatingAccounts:(id)r
{
  [self.tableView reloadData];
  return r;
}

- (id)init
{
  if ((self = [super init])) {
    self.title = @"Networks";
    animateNetworkTransition = YES;
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
  self.title = @"Networks";
  self.navigationItem.rightBarButtonItem = 
    [[[UIBarButtonItem alloc]
      initWithTitle:@"Accounts" style:UIBarButtonItemStylePlain 
      target:self action:@selector(gotoAccounts:)] autorelease];
  
  if (!web) web = [YMWebService sharedWebService];
}

- (UITabBarController *)tabs
{
  if (!tabs) {
    tabs = [[[UITabBarController alloc] init] retain];
    myMessagesController = [[[YMMessageListViewController alloc] init] retain];
    myMessagesController.tabBarItem = 
    [[[UITabBarItem alloc] initWithTitle:@"My Feed" image:
      [UIImage imageNamed:@"53-house.png"] tag:0] autorelease];
    myMessagesController.shouldUpdateBadge = YES;
    
    receivedMessagesController = [[[YMMessageListViewController alloc] init] retain];
    receivedMessagesController.tabBarItem = 
    [[[UITabBarItem alloc] initWithTitle:@"Received" image:
      [UIImage imageNamed:@"received.png"] tag:1] autorelease];
    receivedMessagesController.shouldUpdateBadge = YES;
    
    directoryController = [[[YMContactsListViewController alloc] init] retain];
    directoryController.tabBarItem =
    [[[UITabBarItem alloc] initWithTitle:@"Directory" image:
      [UIImage imageNamed:@"123-id-card.png"] tag:2] autorelease];
    
    feedsController = [[[YMFeedListViewController alloc] init] retain];
    feedsController.tabBarItem = 
    [[[UITabBarItem alloc] initWithTitle:@"Feeds" image:
      [UIImage imageNamed:@"144-feed.png"] tag:3] autorelease];
    
    NSMutableArray *a = [NSMutableArray array];
    for (UIViewController *c in array_(myMessagesController, receivedMessagesController,
                                       feedsController, directoryController)) {
      UINavigationController *nav = [[[UINavigationController alloc] 
                                      initWithRootViewController:c] autorelease];
      nav.navigationBar.tintColor = self.navigationController.navigationBar.tintColor;
      [a addObject:nav];
      
      c.navigationItem.leftBarButtonItem =
      [[UIBarButtonItem alloc]
       initWithTitle:@"Networks" style:UIBarButtonItemStyleBordered target:
       self.navigationController action:@selector(dismissModalViewControllerAnimated:)];
    }
    tabs.viewControllers = a;
  }
  return tabs;
}

- (void) viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  self.view; // haha..
  [[StatusBarNotifier sharedNotifier] setTopOffset:460];
  self.navigationController.navigationBar.tintColor 
  = [UIColor colorWithRed:0.27 green:0.34 blue:0.39 alpha:1.0];
  self.navigationController.toolbar.tintColor 
  = [UIColor colorWithHexString:@"353535"];
  if (![[self.web loggedInUsers] count])
    [self.navigationController pushViewController:
     [[[YMAccountsViewController alloc] init] autorelease] animated:NO];
  else
    [self refreshNetworks];
  [web purgeCachedContactImages];
  
  if (tabs) [tabs release];
  tabs = nil;
  if (myMessagesController) [myMessagesController release];
  myMessagesController = nil;
  if (receivedMessagesController) [receivedMessagesController release];
  receivedMessagesController = nil;
  if (directoryController) [directoryController release];
  directoryController = nil;
  if (feedsController) [feedsController release];
  feedsController = nil;
  
  if (PREF_KEY(@"lastNetworkPK")) {
    YMNetwork *n = (YMNetwork *)[YMNetwork findByPK:
                                 intv(PREF_KEY(@"lastNetworkPK"))];
    YMUserAccount *u = (YMUserAccount *)[YMUserAccount findByPK:intv(n.userAccountPK)];
    waitForDeferred([[YMWebService sharedWebService] 
                     loadCachedContactImagesForUserAccount:u]);
    animateNetworkTransition = NO;
    [self gotoNetwork:n];
    animateNetworkTransition = YES;
  }
}

- (void) viewDidAppear:(BOOL)animated
{
  NSLog(@"networks appeared");
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"lastNetworkPK"];
  [[StatusBarNotifier sharedNotifier] setTopOffset:460];
  [super viewDidAppear:animated];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)table
{
  return 1;
}

- (NSInteger) tableView:(UITableView *)table 
numberOfRowsInSection:(NSInteger)section
{
  if (![[self.web loggedInUsers] count]) return 0;
  return [YMNetwork count];
}

- (UITableViewCell *) tableView:(UITableView *)table
cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *ident = @"YMNetworkCell1";
  YMNetworkTableViewCell *cell;
  YMNetwork *network = [[YMNetwork findByCriteria:
                        @"ORDER BY name, pk ASC LIMIT %i,1", indexPath.row]
                        objectAtIndex:0];
  
  cell = (YMNetworkTableViewCell *)[table dequeueReusableCellWithIdentifier:ident];
  if (!cell)
    cell = [[[YMNetworkTableViewCell alloc]
             initWithStyle:UITableViewCellStyleDefault
             reuseIdentifier:ident] autorelease];
  
  [cell.unreadLabel setHidden:NO];
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  cell.textLabel.text = network.name;
  if (!intv(network.unseenMessageCount))
    [cell.unreadLabel setHidden:YES];
  else
    cell.unreadLabel.text = [network.unseenMessageCount description];
  
  return cell;
}

- (void) tableView:(UITableView *)table
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  YMNetwork *network = [[YMNetwork findByCriteria:
     @"ORDER BY name, pk ASC LIMIT %i,1", indexPath.row]
                        objectAtIndex:0];
  network.unseenMessageCount = nsni(0);
  [network save];
  PREF_SET(@"lastNetworkPK", nsni(network.pk));
  
  [web updateUIApplicationBadge];
  
  [table deselectRowAtIndexPath:indexPath animated:YES];
//  [table reloadRowsAtIndexPaths:array_(indexPath) 
//               withRowAnimation:UITableViewRowAnimationNone];
  
  [self gotoNetwork:network];
}

- (void)gotoNetwork:(YMNetwork *)network
{
  YMUserAccount *acct = (YMUserAccount *)[YMUserAccount findByPK:
                                          intv(network.userAccountPK)];
  acct.activeNetworkPK = nsni(network.pk);
  [acct save];
  [web syncSubscriptions:acct];
  
  [web loadCachedContactImagesForUserAccount:acct];
  
  UITabBarController *c = [self tabs];
  
  myMessagesController.userAccount = acct;
  myMessagesController.target = YMMessageTargetFollowing;
  receivedMessagesController.userAccount = acct;
  receivedMessagesController.target = YMMessageTargetReceived;
  directoryController.userAccount = acct;
  feedsController.userAccount = acct;
  feedsController.network = network;
  
  c.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
  [self.navigationController presentModalViewController:c animated:animateNetworkTransition];
  
  myMessagesController.navigationItem.rightBarButtonItem = 
  [[UIBarButtonItem alloc]
   initWithBarButtonSystemItem:UIBarButtonSystemItemCompose 
   target:myMessagesController action:@selector(composeNew:)];
  
  [receivedMessagesController doReload:nil];
  
  [[StatusBarNotifier sharedNotifier] setTopOffset:411];
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
  self.tableView = nil;
  [super viewDidUnload];
}


- (void)dealloc
{
  [super dealloc];
}


@end
