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


@implementation YMContactDetailViewController

@synthesize userAccount, contact;

- (void)loadView
{
  self.tableView = [[UITableView alloc] initWithFrame:
                    CGRectMake(0, 0, 320, 460) style:UITableViewStyleGrouped];
  self.tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                     UIViewAutoresizingFlexibleHeight);
  self.tableView.delegate = self;
  self.tableView.dataSource = self;
//  self.tableView.backgroundColor = [UIColor whiteColor];
  
  self.title = @"Contact";
  self.hidesBottomBarWhenPushed = YES;
  
  if (!web) web = [YMWebService sharedWebService];
}

- (id)gotoUserFeed:(YMContact *)ct
{
  YMMessageListViewController *c = [[[YMMessageListViewController alloc] init] autorelease];
  c.userAccount = self.userAccount;
  c.target = YMMessageTargetFromUser;
  c.targetID = ct.userID; NSLog(@"ct %@ %@", ct, ct.userID);
  [self.navigationController pushViewController:c animated:YES];
  return ct;
}

- (void)viewWillAppear:(BOOL)animated
{
  YMContactDetailView *det = [YMContactDetailView contactDetailViewWithRect:
                              CGRectMake(0, 0, 320, 222)];
  det.contact = self.contact;
  det.onFeed = callbackTS(self, gotoUserFeed:);
  self.tableView.tableHeaderView = det;
  [self.tableView reloadData];
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
