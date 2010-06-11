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
  self.hidesBottomBarWhenPushed = YES;
}

- (id)gotoUserFeed:(YMContact *)ct
{
  YMMessageListViewController *c = [[[YMMessageListViewController alloc] init] autorelease];
  c.userAccount = self.userAccount;
  c.network = (YMNetwork *)[YMNetwork findByPK:intv(self.userAccount.activeNetworkPK)];
  c.target = YMMessageTargetFromUser;
  c.targetID = ct.userID;   NSLog(@"ct %@ %@", ct, ct.userID);
  [self.navigationController pushViewController:c animated:YES];
  return ct;
}

- (void)viewWillAppear:(BOOL)animated
{ 
  [self updateUserInfo];
  [[StatusBarNotifier sharedNotifier] flashLoading:@"Updating User Info..." deferred:
   [[web updateUser:self.userAccount contact:self.contact]
   addCallback:callbackTS(self, _updatedUser:)]];
}

- (void)updateUserInfo
{
  YMContactDetailView *det = [YMContactDetailView contactDetailViewWithRect:
                              CGRectMake(0, 0, 320, 222)];
  det.contact = self.contact;
  det.onFeed = callbackTS(self, gotoUserFeed:);
  self.tableView.tableHeaderView = det;
  [self.tableView reloadData];
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
  UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:
                           UITableViewCellStyleValue2 reuseIdentifier:ident];
  
  if (indexPath.section == 0) {
    cell.detailTextLabel.text = [[self.contact.phoneNumbers objectAtIndex:indexPath.row]
                                 objectForKey:@"number"];
    cell.textLabel.text = [[self.contact.phoneNumbers objectAtIndex:indexPath.row]
                           objectForKey:@"type"];
  } else if (indexPath.section == 1) {
    cell.detailTextLabel.text = [[self.contact.emailAddresses objectAtIndex:indexPath.row]
                                 objectForKey:@"address"];
    cell.textLabel.text = [[self.contact.emailAddresses objectAtIndex:indexPath.row]
                           objectForKey:@"type"];
  } else if (indexPath.section == 2) {
    cell.detailTextLabel.text = [[self.contact.im objectAtIndex:indexPath.row]
                                 objectForKey:@"username"];
    cell.textLabel.text = [[self.contact.im objectAtIndex:indexPath.row]
                           objectForKey:@"provider"];
  }
  
  return cell;
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
