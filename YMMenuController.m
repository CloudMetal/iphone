//
//  YMMenuController.m
//  Yammer
//
//  Created by Samuel Sutch on 8/18/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "YMMenuController.h"
#import "YMNetworksViewController.h"
#import "YMWebService.h"
#import "YMMessageListViewController.h"
#import "YMContactsListViewController.h"
#import "UIColor+Extensions.h"
#import "SQLiteInstanceManager.h"
#import "YMAccountsViewController.h"


@interface YMMenuController (PrivateParts)

- (id)_didChooseNetwork:(YMNetwork *)n;
- (void)showMessagesPane;
- (id)showMyFeed:(id)s;

@end


@implementation YMMenuController

@synthesize network, userAccount, networksNavController;

- (id)initWithStyle:(UITableViewStyle)style
{
  if (!(self = [super initWithStyle:style])) return self;
  
  builtins = [array_(
     array_(@"feed-iPad.png", @"My Feed", callbackTS(self, showMyFeed:)),
     array_(@"all-iPad.png", @"Company Feed", callbackTS(self, showCompanyFeed:)),
     array_(@"received-iPad.png", @"Received", callbackTS(self, showReceivedFeed:)),
     array_(@"dm-iPad.png", @"Direct Messages", callbackTS(self, showDMFeed:)),
     array_(@"sent-iPad.png", @"Sent", callbackTS(self, showSentFeed:)),
     array_(@"liked-iPad.png", @"Liked", callbackTS(self, showLikedFeed:)),
     array_(@"bookmarked-iPad.png", @"Bookmarked", callbackTS(self, showBookmarkFeed:)),
     array_(@"rss-iPad.png", @"RSS", callbackTS(self, showBotFeed:))) retain];
  self.title = @"Yammer";
  feeds = [[NSMutableArray alloc] init];
  network = nil;
  userAccount = nil;
  web = [YMWebService sharedWebService];
  networksController = [[YMNetworksViewController alloc] initWithStyle:UITableViewStyleGrouped];
  networksController.onChooseNetwork = callbackTS(self, _didChooseNetwork:);
  networksNavController = [[UINavigationController alloc] initWithRootViewController:networksController];
  Class c = NSClassFromString(@"UIPopoverController");
  if (c) {
    networksPopController = [[c alloc] initWithContentViewController:networksNavController];
    [networksPopController setDelegate:self];
  } else networksPopController = nil;
  messagesController = [[YMMessageListViewController alloc] init];
  messagesNavController = [[UINavigationController alloc] initWithRootViewController:
                           messagesController];
  contactsController = [[YMContactsListViewController alloc] init];
  contactsNavController = [[UINavigationController alloc] initWithRootViewController:contactsController];
  NSLog(@"lastNetworkPK %@", PREF_KEY(@"lastNetworkPK"));
  if (PREF_KEY(@"lastNetworkPK")) {
    YMNetwork *n = (YMNetwork *)[YMNetwork findByPK:intv(PREF_KEY(@"lastNetworkPK"))];
    YMUserAccount *u = (YMUserAccount *)[YMUserAccount findByPK:intv(n.userAccountPK)];
    if (n && u) {
      [self _didChooseNetwork:n];
    } else {
      SQLiteInstanceManager *db = [SQLiteInstanceManager sharedManager];
      [db executeUpdateSQL:@"DELETE FROM y_m_user_account"];
      [db executeUpdateSQL:@"DELETE FROM y_m_network"];
      [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"lastNetworkPK"];
    }
  }
  return self;
}

- (UIViewController *)viewControllerForSecondPane
{
  if (network) {
    return messagesNavController;
  }
  return [[[UINavigationController alloc] initWithRootViewController:
           [[[UITableViewController alloc] initWithStyle:UITableViewStyleGrouped]
            autorelease]] autorelease];
}

- (void)refreshFeeds
{
}

- (void)showMessagesPane
{
  self.splitViewController.viewControllers = array_(self.navigationController, messagesNavController);
  [messagesController refreshMessagePKs];
  [messagesController.tableView reloadData];
  [messagesController doReload:nil];
}

- (id)showMyFeed:(id)s
{ 
  messagesController.target = YMMessageTargetFollowing;
  messagesController.title = @"My Feed";
  [self showMessagesPane];
  return nil;
}

- (id)showCompanyFeed:(id)s
{ 
  messagesController.target = YMMessageTargetAll;
  messagesController.title = @"All Messages";
  [self showMessagesPane];
  return nil;
}

- (id)showReceivedFeed:(id)s
{ 
  messagesController.target = YMMessageTargetReceived;
  messagesController.title = @"Received";
  [self showMessagesPane];
  return nil;
}

- (id)showDMFeed:(id)s
{ 
  messagesController.target = YMMessageTargetReceived;
  messagesController.title = @"Direct Messages";
  [self showMessagesPane];
  return nil;
}

- (id)showSentFeed:(id)s 
{ 
  messagesController.target = YMMessageTargetSent;
  messagesController.title = @"Sent";
  [self showMessagesPane];
  return nil;
}

- (id)showLikedFeed:(id)s 
{ 
  messagesController.target = YMMessageTargetFavoritesOf;
  messagesController.title = @"Liked";
  messagesController.targetID = network.userID;
  [self showMessagesPane];
  return nil;
}

- (id)showBookmarkFeed:(id)s
{ 
  [[[[UIAlertView alloc] initWithTitle:@"DOH" message:
     @"DOH - there doesn't seem to be an API method for bookmarks. :(" 
     delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] 
    autorelease] show];
  return nil;
}

- (id)showBotFeed:(id)s 
{ 
  [[[[UIAlertView alloc] initWithTitle:@"DOH" message:
     @"DOH - there doesn't seem to be an API method for followed bots. :(" 
     delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] 
    autorelease] show];
  return nil;
}

- (id)_didChooseNetwork:(YMNetwork *)n
{
  if (network) [network release];
  if (userAccount) [userAccount release];
  network = nil;
  userAccount = nil;
  
  YMUserAccount *u = (YMUserAccount *)[YMUserAccount findByPK:intv(n.userAccountPK)];
  u.activeNetworkPK = nsni(n.pk);
  [u performSelector:@selector(save) withObject:nil afterDelay:5.0];
  [web performSelector:@selector(syncSubscriptions:) withObject:u afterDelay:10.0];
  
  n.unseenMessageCount = nsni(0);
  [n performSelector:@selector(save) withObject:nil afterDelay:5.0];
  
  [web loadCachedContactImagesForUserAccount:u];
  
  messagesController.userAccount = u;
  messagesController.title = @"My Feed";
  messagesController.target = YMMessageTargetFollowing;
  messagesController.network = n;
  network = [n retain];
  userAccount = [u retain];
  
  [networksPopController dismissPopoverAnimated:YES];
  
  self.title = network.name;
  [self.tableView selectRowAtIndexPath:
   [NSIndexPath indexPathForRow:0 inSection:0] animated:
   NO scrollPosition:UITableViewScrollPositionNone];
  [self showMyFeed:nil];
  
  return nil;
}
  

- (void)presentNetworks:(id)s
{
  [networksPopController presentPopoverFromBarButtonItem:
   [self.toolbarItems lastObject] permittedArrowDirections:
   UIPopoverArrowDirectionAny animated:YES];
  [networksPopController setPopoverContentSize:CGSizeMake(320, 400) animated:YES];
}

- (BOOL)popoverControllerShouldDismissPopover:(id)popoverController
{
  return !!network;
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  if (network)
    self.title = self.network.name;
  
  self.navigationController.navigationBar.tintColor 
  = [UIColor colorWithRed:0.27 green:0.34 blue:0.39 alpha:1.0];
  self.navigationController.toolbar.tintColor 
  = [UIColor colorWithHexString:@"353535"];
  self.navigationController.toolbarHidden = NO;
  self.toolbarItems 
  = array_([[[UIBarButtonItem alloc] initWithBarButtonSystemItem:
             UIBarButtonSystemItemFlexibleSpace target:nil action:NULL] autorelease], 
           [[[UIBarButtonItem alloc] initWithTitle:@"Networks" style:
             UIBarButtonItemStyleBordered target:self action:@selector(presentNetworks:)] autorelease]);
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  if (!network) {
    if (![[web loggedInUsers] count]) { // show login right away when no accounts
      YMAccountsViewController *accounts = [[[YMAccountsViewController alloc] init] autorelease];
      UINavigationController *anav = [[[UINavigationController alloc] 
                                       initWithRootViewController:accounts] autorelease];
      anav.modalPresentationStyle = UIModalPresentationFormSheet;
      [self.splitViewController presentModalViewController:anav animated:YES];
      anav.navigationBar.tintColor= [UIColor colorWithRed:0.27 green:0.34 blue:0.39 alpha:1.0];
    } else {
      [self presentNetworks:nil];
    }
  }
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
  return 3;
}

- (NSInteger) tableView:(UITableView *)table 
  numberOfRowsInSection:(NSInteger)section
{
  if (section == 0) return [builtins count];
  if (section == 1) return 1;
  if (section == 2) return [feeds count];
  return 0;
}

- (UITableViewCell *) tableView:(UITableView *)tableView 
          cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *ident = @"YMMenuItem1";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ident];
  if (!cell)
    cell = [[UITableViewCell alloc] initWithStyle:
            UITableViewStylePlain reuseIdentifier:ident];
  cell.imageView.contentMode = UIViewContentModeCenter;
  if (indexPath.section == 0) {
    cell.imageView.image = [UIImage imageNamed:
                     [[builtins objectAtIndex:indexPath.row] objectAtIndex:0]];
    cell.textLabel.text = [[builtins objectAtIndex:indexPath.row] objectAtIndex:1];
  } else if (indexPath.section == 1) {
    cell.imageView.image = [UIImage imageNamed:@"contacts-iPad.png"];
    cell.textLabel.text = @"Contacts";
  }
  return cell;
}

- (void)tableView:(UITableView *)tableView 
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (activeFeed) [activeFeed release];
  activeFeed = [indexPath retain];
  if (indexPath.section == 0) {
    [[[builtins objectAtIndex:indexPath.row] objectAtIndex:2] :nil];
  } else if (indexPath.section == 1) {
    contactsController.userAccount = self.userAccount;
    self.splitViewController.viewControllers 
      = array_(self.navigationController, contactsNavController);
  }
}
  

@end
