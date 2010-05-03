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
#import "LocalStorage.h"
#import "APIGateway.h"
#import "YammerAppDelegate.h"
#import "CFPrettyView.h"


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
//  self.tableView.backgroundColor = [UIColor colorWithHexString:@"044ebd"];
//  self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
//  self.tableView.separatorColor = [UIColor colorWithHexString:@"044ebd"];
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
                   callbackTS(self, _legacyEnterAppWithNetwork:) withObject:network];
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

- (id)_legacyEnterAppWithNetwork:(YMNetwork *)network
{  
  YMUserAccount *acct = (YMUserAccount *)[YMUserAccount findByPK:intv(network.userAccountPK)];
  
  NSString *pushSettingsJSON = [LocalStorage getFile:[APIGateway push_file_with_id:intv(network.networkID)]];
  
  [LocalStorage saveAccessToken:
   [NSString stringWithFormat:@"oauth_token=%@&oauth_token_secret=%@",
    acct.wrapToken, acct.wrapSecret]];
  
  [APIGateway usersCurrent:@"silent"];
  [APIGateway networksCurrent:@"silent"];
  
  YammerAppDelegate *del = (YammerAppDelegate *)[[UIApplication sharedApplication] delegate];
  del.network_id = network.networkID;
  del.dateOfSelection = [[NSDate date] description];
  del.network_name = network.name;
  [LocalStorage saveAccessToken:[NSString stringWithFormat:
                                 @"oauth_token=%@&oauth_token_secret=%@",
                                 network.token, network.secret]];
  [LocalStorage saveSetting:@"current_network_id" value:network.networkID];
  [LocalStorage saveSetting:@"last_in" value:@"network"];
  
  if (del.pushToken && [APIGateway sendPushToken:del.pushToken] && pushSettingsJSON != nil) {
    NSMutableDictionary *pushSettings = [pushSettingsJSON JSONValue];
    NSMutableDictionary *existingPushSettings = [APIGateway pushSettings:@"silent"];
    if (existingPushSettings) {
      [APIGateway updatePushSettingsInBulk:[existingPushSettings objectForKey:@"id"] pushSettings:pushSettings];
    }
    [LocalStorage removeFile:[APIGateway push_file]];
  }
  
  return network;
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
