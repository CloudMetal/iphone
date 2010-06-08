    //
//  YMMessageDetailViewController.m
//  Yammer
//
//  Created by Samuel Sutch on 5/14/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "YMMessageDetailViewController.h"
#import "YMWebService.h"
#import "YMContactDetailViewController.h"
#import "YMMessageListViewController.h"
#import "YMComposeViewController.h"

@implementation YMMessageDetailViewController

@synthesize message, userAccount;

- (void)loadView
{
  self.tableView = [[UITableView alloc] initWithFrame:
                    CGRectMake(0, 0, 320, 460) style:UITableViewStylePlain];
  self.tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                     UIViewAutoresizingFlexibleHeight);
  self.tableView.delegate = self;
  self.tableView.dataSource = self;
  self.tableView.backgroundColor = [UIColor whiteColor];
  self.title = @"Message";
  
  for (id v in [[NSBundle mainBundle] loadNibNamed:
                @"YMMessageDetailView" owner:nil options:nil]) {
    if (![v isKindOfClass:[YMMessageDetailView class]]) continue;
    detailView = [v retain];
    break;
  }
  
  if (!web) web = [YMWebService sharedWebService];
}

- (void)setMessage:(YMMessage *)m
{
  [message release];
  message = [m retain];
}

- (id)showUser:(id)contact
{
  if (![contact isKindOfClass:[YMContact class]]) {
    YMContactDetailViewController *c = [[[YMContactDetailViewController alloc] init] autorelease];
    c.contact = (YMContact *)[YMContact findFirstByCriteria:@"WHERE user_i_d=%i",
                              intv(self.message.senderID)];
    c.userAccount = self.userAccount;
    [self.navigationController pushViewController:c animated:YES];
    return nil;
  }
  
  YMContactDetailViewController *c = [[[YMContactDetailViewController alloc] init] autorelease];
  c.contact = contact;
  c.userAccount = self.userAccount;
  
  [self.navigationController pushViewController:c animated:YES];
  return contact;
}

- (id)showTag:(NSString *)tag
{
  YMMessageListViewController *c = [[[YMMessageListViewController alloc] init] autorelease];
  c.userAccount = self.userAccount;
  c.target = YMMessageTargetTaggedWith;
  c.targetID = nsni(intv(tag));
  [self.navigationController pushViewController:c animated:YES];
  return tag;
}

- (id)showThread:(NSString *)sender
{
  YMMessageListViewController *c = [[[YMMessageListViewController alloc] init] autorelease];
  c.userAccount = self.userAccount;
  c.target = YMMessageTargetInThread;
  c.targetID = self.message.threadID;
  [self.navigationController pushViewController:c animated:YES];
  return nil;
}

- (id)showReply:(id)sender
{
  YMComposeViewController *c = [[[YMComposeViewController alloc] init] autorelease];
  c.userAccount = self.userAccount;
  c.network = (YMNetwork *)[YMNetwork findByPK:intv(self.userAccount.activeNetworkPK)];
  c.inReplyTo = self.message;
  [c showFromController:self animated:YES];
  return nil;
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  detailView.message = message;
  detailView.parentViewController = self;
  detailView.onUser = callbackTS(self, showUser:);
  detailView.onTag = callbackTS(self, showTag:);
  detailView.onReply = callbackTS(self, showReply:);
  detailView.onThread = callbackTS(self, showThread:);
  self.tableView.tableHeaderView = detailView;
}

//- (void)viewWillDisappear:(BOOL)animated
//{
////  [self.navigationController setToolbarHidden:NO animated:YES];
//}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)table
{
  return 1;
}

- (NSInteger) tableView:(UITableView *)table
numberOfRowsInSection:(NSInteger)section
{
  return 0;
}

- (UITableViewCell *) tableView:(UITableView *)table
cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  return nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)o
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
  [message release];
  self.tableView = nil;
  [super dealloc];
}


@end
