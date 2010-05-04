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
#import "CFPrettyView.h"

#import "YMLegacyShim.h"
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
}

- (void)loadView
{
  self.tableView = [[UITableView alloc] initWithFrame:
                    CGRectMake(0, 0, 320, 460) style:UITableViewStylePlain];
  self.tableView.delegate = self;
  self.tableView.dataSource = self;
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
  if (![[self.web loggedInUsers] count])
    [self.navigationController pushViewController:
     [[[YMAccountsViewController alloc] init] autorelease] animated:YES];
  else
    [self refreshNetworks];
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
                        @"ORDER BY name, pk ASC LIMIT 1 OFFSET %i", indexPath.row]
                        objectAtIndex:0];
  
  cell = (YMNetworkTableViewCell *)[table dequeueReusableCellWithIdentifier:ident];
  if (!cell)
    cell = [[[YMNetworkTableViewCell alloc]
             initWithStyle:UITableViewCellStyleDefault
             reuseIdentifier:ident] autorelease];
  
  cell.textLabel.text = network.name;
  cell.unreadLabel.text = [network.unseenMessageCount description];
  
  return cell;
}

- (void) tableView:(UITableView *)table
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  YMNetwork *network = [[YMNetwork findByCriteria:
     @"ORDER BY name, pk ASC LIMIT 1 OFFSET %i", indexPath.row]
                        objectAtIndex:0];
  
  DKDeferred *d = [DKDeferred deferInThread:
                   callbackTS([YMLegacyShim sharedShim], 
                              _legacyEnterAppWithNetwork:) withObject:network];
  [d addCallback:callbackTS(self, _legacyBootstrapDone:)];
  
  CFPrettyView *hud = [[[CFPrettyView alloc] initWithFrame:CGRectZero] autorelease];
  [hud showAsLoadingHUDWithDeferred:d inView:
   [[UIApplication sharedApplication] keyWindow]];
}

- (id)_legacyBootstrapDone:(id)r
{
  [(id)[[UIApplication sharedApplication] delegate] enterAppWithAccess];
  return r;
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
