    //
//  YMMessageListViewController.m
//  Yammer
//
//  Created by Samuel Sutch on 5/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "YMMessageListViewController.h"
#import "YMWebService.h"
#import "YMContactsListViewController.h"

@interface YMMessageListViewController (PrivateStuffs)

- (NSString *)listCriteria;
- (void)refreshMessagePKs;

@end


@implementation YMMessageListViewController

@synthesize target, targetID, olderThan, newerThan, threaded, userAccount;

- (void)loadView
{
  self.tableView = [[UITableView alloc] initWithFrame:
                    CGRectMake(0, 0, 320, 460) style:UITableViewStylePlain];
  self.tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                     UIViewAutoresizingFlexibleHeight);
  self.tableView.delegate = self;
  self.tableView.dataSource = self;
  self.tableView.backgroundColor = [UIColor whiteColor];
  UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:
                            UIBarButtonSystemItemFixedSpace target:nil action:nil];
  space.width = 10;
  self.toolbarItems = 
    array_([[UIBarButtonItem alloc]
            initWithImage:[UIImage imageNamed:@"104-index-cards.png"] style:UIBarButtonItemStylePlain 
            target:self action:@selector(gotoUsers:)],
           space,
           [[UIBarButtonItem alloc]
            initWithImage:[UIImage imageNamed:@"20-gear2.png"] style:UIBarButtonItemStylePlain
            target:self action:@selector(gotoSettings:)],
           [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace 
            target:nil action:nil],
           [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemCompose 
            target:self action:@selector(composeNew:)]);
  
  self.title = @"Messages";
  
  self.target = YMMessageTargetAll;
  self.targetID = nil;
  self.olderThan = nil;
  self.newerThan = nil;
  self.threaded = nsnb(NO);
  
  if (!web) web = [YMWebService sharedWebService];
}

- (void) viewWillAppear:(BOOL)animated
{
  [self refreshMessagePKs];
}

- (void) viewDidAppear:(BOOL)animated
{
  [self.tableView reloadData];
  [super viewDidAppear:animated];
  [[[web getMessages:self.userAccount params:EMPTY_DICT]
    addCallback:curryTS(self, @selector(_gotMessages::::), 
                        self.userAccount, self.target, 
                        (self.targetID == nil ? (id)[NSNull null] : self.targetID))]
   addErrback:callbackTS(self, _failedGetMessages:)];
}

- (void)gotoUsers:(id)sender
{
  [[web loadCachedContactImagesForUserAccount:self.userAccount]
   addCallback:callbackTS(self, _gotoUsers:)];
}

- (id)_gotoUsers:(id)r
{
  YMContactsListViewController *c =
  [[[YMContactsListViewController alloc]
    initWithStyle:UITableViewStylePlain] autorelease];
  
  c.userAccount = self.userAccount;
  [self.navigationController pushViewController:c animated:YES];
  
  return r;
}

- (void)gotoSettings:(id)sender
{
}

- (void)composeNew:(id)sender
{
}

- (id)_gotMessages:(YMUserAccount *)acct :(id)_target :(id)_targetID :(id)results 
{
  [self refreshMessagePKs];
  [self.tableView reloadData];
  return results;
}

- (id)_failedGetMessages:(NSError *)error
{
  NSLog(@"_failedGetMessages: %@ %@", error, [error userInfo]);
  return error;
}

- (NSString *)listCriteria
{
  return [NSString stringWithFormat:@"WHERE network_p_k=%@ AND target='%@'%@", 
          self.userAccount.activeNetworkPK, target, 
          (targetID != nil ? [NSString stringWithFormat:
                              @" AND target_i_d='%@'", targetID] : @"")];
}

- (void)refreshMessagePKs
{
  if (messagePKs) [messagePKs release];
  messagePKs = nil;
  messagePKs = [[[YMMessage pairedArraysForProperties:
                  EMPTY_ARRAY withCriteria:[self listCriteria]] 
                 objectAtIndex:0] retain];
}

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

- (NSInteger) tableView:(UITableView *)table
  numberOfRowsInSection:(NSInteger)section
{
  return [messagePKs count];
}

- (UITableViewCell *) tableView:(UITableView *)table
cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *ident = @"YMMessageCell1";
  YMMessage *message = (YMMessage *)[YMMessage findByPK:
         intv([messagePKs objectAtIndex:indexPath.row])];
  
  UITableViewCell *c = [[UITableViewCell alloc] initWithStyle:
                        UITableViewCellStyleDefault reuseIdentifier:ident];
  c.textLabel.text = message.bodyPlain;
  return c;
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
  [super dealloc];
}

@end
