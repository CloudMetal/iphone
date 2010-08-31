    //
//  YMContactDetailViewController.m
//  Yammer
//
//  Created by Samuel Sutch on 5/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "YMContactDetailViewController.h"
#import "YMWebService.h"
#import "YMContactDetailView.h"
#import "YMMessageListViewController.h"
#import "StatusBarNotifier.h"
#import "YMComposeViewController.h"


@interface YMContactDetailViewController (PrivateParts)

- (void)updateUserInfo;

@end



@implementation YMContactDetailViewController

@synthesize userAccount, contact;

- (id)init
{
  if ((self = [super init])) {
    web = [YMWebService sharedWebService];
  }
  return self;
}

- (void)loadView
{
  self.tableView = [[UITableView alloc] initWithFrame:
                    CGRectMake(0, 0, 320, 460) style:UITableViewStyleGrouped];
  self.tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                     UIViewAutoresizingFlexibleHeight);
  self.tableView.delegate = self;
  self.tableView.dataSource = self;

  self.title = @"Contact";
}

- (id)gotoUserFeed:(YMContact *)ct
{
  YMMessageListViewController *c = [[[YMMessageListViewController alloc]
                                     init] autorelease];
  c.userAccount = self.userAccount;
  c.network = (YMNetwork *)[YMNetwork findByPK:
                            intv(self.userAccount.activeNetworkPK)];
  if ([ct.type isEqual:@"user"]) 
    c.target = YMMessageTargetFromUser;
  else 
    c.target = YMMessageTargetFromBot;
  c.targetID = ct.userID; 
  c.title = ct.fullName;
  c.hidesBottomBarWhenPushed = NO;
  [self.navigationController pushViewController:c animated:YES];
  return ct;
}

- (void)viewWillAppear:(BOOL)animated
{ 
  [self updateUserInfo];
  if (contact && [contact.type isEqual:@"user"])
    [[StatusBarNotifier sharedNotifier] flashLoading:@"Updating User Info..." 
    deferred:[[web updateUser:self.userAccount contact:self.contact]
     addCallback:callbackTS(self, _updatedUser:)]];
}

- (void)updateUserInfo
{
  [network release];
  network = nil;
  network = [(id)[YMNetwork findByPK:
                  intv(self.userAccount.activeNetworkPK)] retain];
  
  YMContactDetailView *det = [YMContactDetailView contactDetailViewWithRect:
                              CGRectMake(0, 0, 320, 239)];
  det.contact = self.contact;
  det.onFeed = callbackTS(self, gotoUserFeed:);
  det.onFollow = callbackTS(self, doFollow:);
  det.onMessage = callbackTS(self, sendMessage:);
  if ([network.userSubscriptionIds containsObject:self.contact.userID]) {
    [det.followButton setTitle:@"Unfollow" forState:UIControlStateNormal];
  } else {
    [det.followButton setTitle:@"Follow" forState:UIControlStateNormal];
  }
  if ([network.userID isEqual:self.contact.userID])
    [det hideFollowAndPM];
  self.tableView.tableHeaderView = det;
  [self.tableView reloadData];
}

- (id)sendMessage:(YMContact *)ct
{
  YMComposeViewController *c = [[[YMComposeViewController alloc]
                                 init] autorelease];
  c.directTo = self.contact;
  c.userAccount = self.userAccount;
  c.network = network;
  [c showFromController:self animated:YES];
  return nil;
}

- (id)doFollow:(YMContact *)ct
{
  if ([network.userSubscriptionIds containsObject:self.contact.userID]) {
    [[[StatusBarNotifier sharedNotifier] flashLoading:
      [NSString stringWithFormat:@"Unfollowing %@", 
       self.contact.username] deferred:
      [web unsubscribe:self.userAccount to:@"user" withID:
       intv(self.contact.userID)]]
     addCallback:callbackTS(self, _unfollowSuccess:)];
  } else {
    [[[StatusBarNotifier sharedNotifier] flashLoading:
      [NSString stringWithFormat:@"Following %@", self.contact.username] 
       deferred:[web subscribe:self.userAccount to:@"user" 
                        withID:intv(self.contact.userID)]]
     addCallback:callbackTS(self, _followSuccess:)];
  }
  return nil;
}

- _unfollowSuccess:(id)r
{
  NSMutableArray *ar = [[network.userSubscriptionIds mutableCopy] autorelease];
  [ar removeObject:self.contact.userID];
  YMContactDetailView *det 
    = (YMContactDetailView *)self.tableView.tableHeaderView;
  [det.followButton setTitle:@"Follow" forState:UIControlStateNormal];
  det.followersLabel.text = [NSString stringWithFormat:@"%i", 
                             intv(det.followersLabel.text) - 1];
  network.userSubscriptionIds = ar;
  [network save];
  return r;
}

- _followSuccess:(id)r
{
  NSMutableArray *ar = [[network.userSubscriptionIds mutableCopy] autorelease];
  [ar addObject:self.contact.userID];
  network.userSubscriptionIds = ar;
  [network save];
  YMContactDetailView *det 
    = (YMContactDetailView *)self.tableView.tableHeaderView;
  [det.followButton setTitle:@"Unfollow" forState:UIControlStateNormal];
  det.followersLabel.text = [NSString stringWithFormat:@"%i", 
                             intv(det.followersLabel.text) + 1];
  return r;
}

- (id)_updatedUser:(YMContact *)c
{
  self.contact = c;
  [self updateUserInfo];
  return c;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)table
{
  return 3;
}

- (NSInteger) tableView:(UITableView *)table 
numberOfRowsInSection:(NSInteger)section
{
  if (section == 0)
    return [self.contact.phoneNumbers count];
  if (section == 1)
    return [self.contact.emailAddresses count];
  if (section == 2)
    return [self.contact.im count];
  return 0;
}

- (UITableViewCell *) tableView:(UITableView *)table
cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *ident = @"YMContactBitCell1";
  UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:
                           UITableViewCellStyleValue2 reuseIdentifier:ident] autorelease];
  
  if (indexPath.section == 0) {
    cell.detailTextLabel.text = [[self.contact.phoneNumbers 
                                  objectAtIndex:indexPath.row]
                                 objectForKey:@"number"];
    cell.textLabel.text = [[self.contact.phoneNumbers 
                            objectAtIndex:indexPath.row] objectForKey:@"type"];
  } else if (indexPath.section == 1) {
    NSString *typ = @"Personal Email";
    if ([[[self.contact.emailAddresses objectAtIndex:indexPath.row] 
          objectForKey:@"type"] isEqual:@"primary"])
      typ = @"Work Email";
    cell.detailTextLabel.text = [[self.contact.emailAddresses 
                        objectAtIndex:indexPath.row] objectForKey:@"address"];
    cell.textLabel.text = typ;
  } else if (indexPath.section == 2) {
    cell.detailTextLabel.text = [[self.contact.im objectAtIndex:indexPath.row]
                                 objectForKey:@"username"];
    cell.textLabel.text = [[self.contact.im objectAtIndex:indexPath.row]
                           objectForKey:@"provider"];
  }
  
  return cell;
}

- (void)tableView:(UITableView *)table
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [table deselectRowAtIndexPath:indexPath animated:YES];
  if (indexPath.section == 0)
    [[UIApplication sharedApplication] openURL:
     [NSURL URLWithString:[@"tel://" stringByAppendingString:
                           [[self.contact.phoneNumbers objectAtIndex:
                             indexPath.row] objectForKey:@"number"]]]];
  else if (indexPath.section == 1) {
    if (![MFMailComposeViewController canSendMail]) {
      [(UIAlertView *)[[[UIAlertView alloc]
        initWithTitle:@"Not Configured" message:
        @"Your device is not configured to send mail." delegate:nil
        cancelButtonTitle:@"Dismiss" otherButtonTitles:nil]
        autorelease]
       show];
    } else {
      MFMailComposeViewController *c 
        = [[[MFMailComposeViewController alloc] init] autorelease];
      c.navigationBar.tintColor 
        = self.navigationController.navigationBar.tintColor;
      c.mailComposeDelegate = self;
      [c setToRecipients:array_([[self.contact.emailAddresses 
                      objectAtIndex:indexPath.row] objectForKey:@"address"])];
      [self.navigationController presentModalViewController:c animated:YES];
    }
  }
}

- (NSIndexPath *)tableView:(UITableView *)table
willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (indexPath.section == 2) return nil;
  return indexPath;
}

- (void)mailComposeController:(MFMailComposeViewController *)controller 
didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
  [self.navigationController dismissModalViewControllerAnimated:YES];
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
  self.contact = nil;
  self.userAccount = nil;
  [super dealloc];
}


@end
