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

- (void) viewDidAppear:(BOOL)animated
{
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
  
  [web updateUIApplicationBadge];
  
  [table deselectRowAtIndexPath:indexPath animated:YES];
  [table reloadRowsAtIndexPaths:array_(indexPath) 
               withRowAnimation:UITableViewRowAnimationNone];
  
  YMUserAccount *acct = (YMUserAccount *)[YMUserAccount findByPK:
                                          intv(network.userAccountPK)];
  acct.activeNetworkPK = nsni(network.pk);
  [acct save];
  
  YMMessageListViewController *controller = [[[YMMessageListViewController alloc] init] autorelease];
  controller.userAccount = acct;
  
  [self.navigationController pushViewController:controller animated:YES];
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
