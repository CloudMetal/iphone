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
                    CGRectMake(0, 0, 320, 460) style:UITableViewStyleGrouped];
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
  UITableViewCell *cell;
  YMNetwork *network = [[YMNetwork findByCriteria:
                        @"ORDER BY name, pk ASC LIMIT 1 OFFSET %i", indexPath.row]
                        objectAtIndex:0];
  
  cell = [table dequeueReusableCellWithIdentifier:ident];
  if (!cell)
    cell = [[[UITableViewCell alloc]
             initWithStyle:UITableViewCellStyleDefault
             reuseIdentifier:ident] autorelease];
  
  cell.textLabel.text = network.name;
  
  return cell;
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
