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
#import <AddressBook/AddressBook.h>
#import "SQLiteInstanceManager.h"

@interface YMNetworksViewController (PrivateParts)

- (NSArray *)_allAddressBookContacts;

@end


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
    [ops addObject:[[YMWebService sharedWebService] networksForUserAccount:acct]];
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
    networkPKs = nil;
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
//  if (!tabs) {
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
      [UIImage imageNamed:@"feeds.png"] tag:3] autorelease];
    
    NSMutableArray *a = [NSMutableArray array];
    for (UIViewController *c in array_(myMessagesController, receivedMessagesController,
                                       feedsController, directoryController)) {
      UINavigationController *nav = [[[UINavigationController alloc] 
                                      initWithRootViewController:c] autorelease];
      nav.navigationBar.tintColor = self.navigationController.navigationBar.tintColor;
      [a addObject:nav];
      
      //UIImageView *img = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"backbutton.png"]] autorelease];
      UIButton *back = [[[UIButton alloc] initWithFrame:CGRectMake(0, 0, 76, 30)] autorelease];
      back.showsTouchWhenHighlighted = YES;
      back.titleLabel.font = [UIFont boldSystemFontOfSize:12];
      [back setTitleEdgeInsets:UIEdgeInsetsMake(0, 4, 0, 0)];
      [back setBackgroundImage:[[UIImage imageNamed:@"backbutton.png"] stretchableImageWithLeftCapWidth:17 topCapHeight:15] forState:UIControlStateNormal];
      [back setBackgroundImage:[[UIImage imageNamed:@"backbutton-h.png"] stretchableImageWithLeftCapWidth:17 topCapHeight:15] forState:UIControlStateHighlighted];
      [back setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
      [back setTitle:@"Networks" forState:UIControlStateNormal];
      [back addTarget:self action:@selector(fuckOffYouDirtyHonkyNetwork:) forControlEvents:UIControlEventTouchUpInside];
      
      UIBarButtonItem *it = [[[UIBarButtonItem alloc] initWithCustomView:back] autorelease];
      
      c.navigationItem.leftBarButtonItem = it;
      
//      [[UIBarButtonItem alloc]
//       initWithTitle:@"Networks" style:UIBarButtonItemStyleBordered target:self
//       action:@selector(fuckOffYouDirtyHonkyNetwork)];
    }
    tabs.viewControllers = a;
//  }
  return tabs;
}

- (void)fuckOffYouDirtyHonkyNetwork:(id)s
{
  if (PREF_KEY(@"lastNetworkPK")) {
    YMNetwork *n = (YMNetwork *)[YMNetwork findByPK:
                                 intv(PREF_KEY(@"lastNetworkPK"))];
    if (n) {
      [[SQLiteInstanceManager sharedManager]
       executeUpdateSQL:
       [NSString stringWithFormat:
        @"UPDATE y_m_message SET read=1 WHERE network_p_k=%i", n.pk]];
    }
  }
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
  [self.navigationController dismissModalViewControllerAnimated:YES];
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
  
  if (PREF_KEY(@"lastNetworkPK")) {
    YMNetwork *n = (YMNetwork *)[YMNetwork findByPK:
                                 intv(PREF_KEY(@"lastNetworkPK"))];
    YMUserAccount *u = (YMUserAccount *)[YMUserAccount findByPK:intv(n.userAccountPK)];
    if (!u || !n) { // oh shit, something went very bad
      SQLiteInstanceManager *db = [SQLiteInstanceManager sharedManager];
      [db executeUpdateSQL:@"DELETE FROM y_m_user_account"];
      [db executeUpdateSQL:@"DELETE FROM y_m_network"];
      [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"lastNetworkPK"];
      [self.tableView reloadData];
      return;
    }
    waitForDeferred([[YMWebService sharedWebService] 
                     loadCachedContactImagesForUserAccount:u]);
    animateNetworkTransition = NO;
    [self gotoNetwork:n];
    animateNetworkTransition = YES;
    return;
  }
  
  if (![[self.web loggedInUsers] count])
    [self.navigationController pushViewController:
     [[[YMAccountsViewController alloc] init] autorelease] animated:NO];
  [web purgeCachedContactImages];
}

- (void) viewDidAppear:(BOOL)animated
{
  NSLog(@"networks appeared");
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"lastNetworkPK"];
  [[StatusBarNotifier sharedNotifier] setTopOffset:460];
  [self.tableView reloadData];
  [self refreshNetworks];
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
  NSMutableArray *ar = [NSMutableArray array];
  for (YMUserAccount *acct in [web loggedInUsers]) {
    NSArray *pks = [YMNetwork pairedArraysForProperties:EMPTY_ARRAY 
                              withCriteria:@"WHERE user_account_p_k=%i", acct.pk];
    [ar addObjectsFromArray:[pks objectAtIndex:0]];
  }
  [networkPKs release];
  networkPKs = [ar retain];
  return [networkPKs count];
}

- (UITableViewCell *) tableView:(UITableView *)table
cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *ident = @"YMNetworkCell1";
  YMNetworkTableViewCell *cell;
  YMNetwork *network = (YMNetwork *)[YMNetwork findByPK:
                       intv([networkPKs objectAtIndex:indexPath.row])];
  
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
  YMNetwork *network = (YMNetwork *)[YMNetwork findByPK:
                       intv([networkPKs objectAtIndex:indexPath.row])];
//  [network save];
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
  
  [self doContactScrape:acct network:network];
  
  network.unseenMessageCount = nsni(0);
  [network save];
  [web updateUIApplicationBadge];
  
  [web loadCachedContactImagesForUserAccount:acct];
  
  UITabBarController *c = [self tabs];
  
  myMessagesController.userAccount = acct;
  myMessagesController.network = network;
  myMessagesController.target = YMMessageTargetFollowing;
  myMessagesController.title = @"My Feed";
  receivedMessagesController.userAccount = acct;
  receivedMessagesController.target = YMMessageTargetReceived;
  receivedMessagesController.network = network;
  receivedMessagesController.title = @"Received";
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
  [myMessagesController doReload:nil];
  
  [[StatusBarNotifier sharedNotifier] setTopOffset:411];
}

- (void)doContactScrape:(YMUserAccount *)_acct network:(YMNetwork *)_network
{
  scrape_network = _network;
  scrape_acct = _acct;
  if (scrape_network.lastScrapedLocalContacts == nil && 
      !PREF_KEY(([NSString stringWithFormat:@"dontlookatmycontacts:%@", _network.networkID])) && 
      !intv(_network.community)) {
    [[[[UIAlertView alloc] initWithTitle:@"Yammer" message:
     @"Yammer would like permission to look in your address book to suggest coworkers to follow. Is this okay?" 
                                delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil] autorelease] show];
  }
}

- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  if (buttonIndex == 0) PREF_SET(([NSString stringWithFormat:@"dontlookatmycontacts:%@", scrape_network.networkID]), nsnb(YES));
  else {
    scrape_network.lastScrapedLocalContacts = [NSDate date];
    [scrape_network save];
    [web suggestions:scrape_acct fromContacts:[self _allAddressBookContacts]];
    scrape_network = nil;
    scrape_acct = nil;
  }
}

- (NSArray *)_allAddressBookContacts
{
  NSMutableArray *ret = [NSMutableArray array];
  ABAddressBookRef addressBook = ABAddressBookCreate();
  CFArrayRef people = ABAddressBookCopyArrayOfAllPeople(addressBook);
  
  CFStringRef fn, ln;
  CFArrayRef emails;
  ABRecordRef ref;
  ABMultiValueRef ems;
  NSString *name;
  
  for (int i = 0; i < CFArrayGetCount(people); i++) {
    ref = CFArrayGetValueAtIndex(people, i);
    
    fn = ABRecordCopyValue(ref, kABPersonFirstNameProperty);
    ln = ABRecordCopyValue(ref, kABPersonLastNameProperty);
    if (!ln) ln = CFSTR("");
    if (!fn) fn = CFSTR("");
    
    ems = ABRecordCopyValue(ref, kABPersonEmailProperty);
    emails = ABMultiValueCopyArrayOfAllValues(ems);
    if (!emails) emails = CFArrayCreate(NULL, NULL, 0, NULL);
    
    name = [NSString stringWithFormat:@"%@ %@", (id)fn, (id)ln];
    
    if ([name length] && CFArrayGetCount(emails))
      [ret addObject:
       dict_(name, @"name", 
             [NSArray arrayWithArray:(id)emails], @"addresses")];
    
    CFRelease(fn); 
    CFRelease(ln); 
    CFRelease(ems); 
    CFRelease(emails);
  }
  
  CFRelease(addressBook);
  CFRelease(people);
  
  return ret; 
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
