    //
//  YMContactsListViewController.m
//  Yammer
//
//  Created by Samuel Sutch on 5/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "YMContactsListViewController.h"
#import "YMWebService.h"
#import "YMContactTableViewCell.h"
#import "YMContactDetailViewController.h"
#import "NSMutableArray-MultipleSort.h"
#import "UIColor+Extensions.h"
#import "StatusBarNotifier.h"

@interface YMContactsListViewController (PrivateStuffs)

- (void)refreshContactPKs;
- (NSInteger)indexForIndexPath:(NSIndexPath *)indexPath;
- (NSString *)searchQuery;
- (void)doSync:(id)r;

@end


@implementation YMContactsListViewController

@synthesize userAccount, filterText, rootNavController;

- (void)loadView
{
  self.tableView = [[UITableView alloc] initWithFrame:
                    CGRectMake(0, 0, 320, 460) style:UITableViewStylePlain];
  self.tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                     UIViewAutoresizingFlexibleHeight);
  self.tableView.delegate = self;
  self.tableView.dataSource = self;
  self.tableView.backgroundColor = [UIColor whiteColor];
  self.toolbarItems =
    array_([[UIBarButtonItem alloc] 
            initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
            target:nil action:nil],
           [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh 
            target:self action:@selector(doSync:)]);
  
  searchBar = [[UISearchBar alloc]
               initWithFrame:CGRectMake(0, 0, 320, 44)];
  searchBar.tintColor = [UIColor colorWithHexString:@"989898"];
  searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  searchBar.delegate = self;
  searchBar.showsCancelButton = NO;
  self.tableView.tableHeaderView = searchBar;
  
  self.title = @"Directory";
  
  shouldHideSectionIndex = NO;
  if (!web) web = [YMWebService sharedWebService];
}

- (void)viewWillAppear:(BOOL)animated 
{
  self.filterText = nil;
  [super viewWillAppear:animated];
  [self refreshContactPKs];
  [self.tableView reloadData];
  if ([contactPKs count])
    [self.tableView scrollToRowAtIndexPath:
      [NSIndexPath indexPathForRow:0 inSection:0] 
     atScrollPosition:UITableViewScrollPositionTop animated:NO];
  
  self.navigationItem.leftBarButtonItem =
  [[UIBarButtonItem alloc]
   initWithTitle:@"Networks" style:UIBarButtonItemStyleBordered target:
   self.parentViewController action:@selector(dismissModalViewControllerAnimated:)];
}

- (void) viewDidAppear:(BOOL)animated
{
  YMNetwork *network = (YMNetwork *)[YMNetwork findByPK:
                       intv(self.userAccount.activeNetworkPK)];
  id k = [NSString stringWithFormat:@"YMGotFullContactsFor%@", network.networkID];
  if (!PREF_KEY(k)) {
    [self doSync:nil];
    UIImageView *v = [[UIImageView alloc] initWithImage:
                      [UIImage imageNamed:@"syncing.png"]];
    v.backgroundColor = [UIColor colorWithHexString:@"c2c2c2"];
    v.contentMode = UIViewContentModeCenter;
    v.autoresizingMask = (UIViewAutoresizingFlexibleHeight 
                          | UIViewAutoresizingFlexibleWidth);
    v.frame = self.view.frame;
    lastView = [self.view retain];
    self.view = v;
  }
  [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [web writeCachedContactImages];
  [super viewWillDisappear:animated];
}

- (void)doSync:(id)sender
{
  [[[StatusBarNotifier sharedNotifier]
    flashLoading:@"Syncing Contacts" deferred:
    [web syncUsers:self.userAccount]]
   addCallback:callbackTS(self, _usersUpdated:)];
}

- (void)refreshContactPKs
{
  if (contactPKs) [contactPKs release];
  contactPKs = nil;
  if (mugshots) [mugshots release];
  mugshots = nil;
  if (alphabetGroups) [alphabetGroups release];
  alphabetGroups = nil;
  
  if (!alphabet) alphabet = [[@"a b c d e f g h i j k l m n o p q r s t u v w x y z"
                              componentsSeparatedByString:@" "] retain];
  
  alphabetGroups = [[NSMutableArray arrayWithCapacity:[alphabet count]] retain];
  for (int i = 0; i < [alphabet count]; i++) 
    [alphabetGroups addObject:[NSMutableArray array]];
  
  YMNetwork *curNetwork = (YMNetwork *)[YMNetwork findByPK:
                           intv(self.userAccount.activeNetworkPK)];
  NSArray *contacts = [YMContact pairedArraysForProperties:
                  array_(@"fullName", @"mugshotURL") withCriteria:@"WHERE network_i_d=%i%@", 
                       intv(curNetwork.networkID), [self searchQuery]];

  // sort by full name
  NSMutableArray *cpks = [[[contacts objectAtIndex:0] retain] autorelease];
  NSMutableArray *omgwtfs = [[[contacts objectAtIndex:1] retain] autorelease];
  NSMutableArray *mgs = [[[contacts objectAtIndex:2] retain] autorelease];
  [omgwtfs sortArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)
          withPairedMutableArrays:cpks, mgs, nil];
  contactPKs = [cpks retain];
  mugshots = [[NSMutableArray arrayWithCapacity:[contactPKs count]] retain];
  UIImage *ms;
  for (int i = 0; i < [contactPKs count]; i++) {
    [mugshots addObject:(((ms = [web imageForURLInMemoryCache:[mgs objectAtIndex:i]])
                          == nil) ? (id)[NSNull null] : ms)];
    
    NSString *fn = [omgwtfs objectAtIndex:i];
    NSString *firstLetter = @"z";
    int idx = [alphabet indexOfObject:firstLetter];
    if (![fn isEqual:[NSNull null]] && [fn length])
      firstLetter = [[fn substringToIndex:1] lowercaseString];
    if ([alphabet indexOfObject:firstLetter] != NSNotFound) {
      idx = [alphabet indexOfObject:firstLetter];
    }
    [[alphabetGroups objectAtIndex:idx]
     addObject:nsni(i)];
  }
}

- (NSInteger) indexForIndexPath:(NSIndexPath *)indexPath
{
  return intv([[alphabetGroups objectAtIndex:indexPath.section] 
               objectAtIndex:indexPath.row]);
}

- (NSString *)searchQuery
{
  if (!self.filterText || 
      ![[self.filterText stringByTrimmingCharactersInSet:
         [NSCharacterSet whitespaceCharacterSet]] length])
    return @"";
  
  return [NSString stringWithFormat:
          @" AND full_name LIKE '%%%%%@%%%%'",
          self.filterText];
}

- (id)_usersUpdated:(id)r
{
  if (![self.view isKindOfClass:[UITableView class]]) {
    self.view = lastView;
    [lastView release];
    lastView = nil;
  }

  YMNetwork *network = (YMNetwork *)[YMNetwork findByPK:
                                     intv(self.userAccount.activeNetworkPK)];
  id k = [NSString stringWithFormat:@"YMGotFullContactsFor%@", network.networkID];
  PREF_SET(k, nsnb(YES));
  
  [self refreshContactPKs];
  [self.tableView reloadData];
  if (isDeferred(r))
    [r addCallback:callbackTS(self, _usersUpdated:)];
  return r;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)table
{
  return [alphabet count];
}

- (NSArray *) sectionIndexTitlesForTableView:(UITableView *)table
{
  if (shouldHideSectionIndex) return nil;
  NSMutableArray *ret = [NSMutableArray arrayWithCapacity:[alphabet count]];
  for (NSString *el in alphabet) [ret addObject:[el uppercaseString]];
  return ret;
}

- (NSInteger) tableView:(UITableView *)table
sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
  return [alphabet indexOfObject:[title lowercaseString]];
}

- (CGFloat) tableView:(UITableView *)table
heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  return 44;
}

- (NSInteger) tableView:(UITableView *)table 
numberOfRowsInSection:(NSInteger)section
{
  if (!contactPKs) return 0;
  return [[alphabetGroups objectAtIndex:section] count];
}

- (NSString *) tableView:(UITableView *)table
 titleForHeaderInSection:(NSInteger)section
{
  if ([[alphabetGroups objectAtIndex:section] count])
    return [[alphabet objectAtIndex:section] uppercaseString];
  return nil;
}

- (UITableViewCell *) tableView:(UITableView *)table
cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *ident = @"YMContactCell1";
  YMContactTableViewCell *cell = (YMContactTableViewCell *)
    [table dequeueReusableCellWithIdentifier:ident];

  if (!cell) cell = [[[YMContactTableViewCell alloc]
   initWithFrame:CGRectMake(0, 0, 320, 44) reuseIdentifier:ident] autorelease];
  cell.opaque = YES;
  
  int idx = [self indexForIndexPath:indexPath];
  YMContact *contact = (YMContact *)[YMContact findByPK:
                        intv([contactPKs objectAtIndex:idx])];
  
  cell.imageView.image = [UIImage imageNamed:@"user-70.png"];
  id img = [mugshots objectAtIndex:idx];
  if ([img isEqual:[NSNull null]]) {
    if (contact.mugshotURL && [contact.mugshotURL length]) {
      [[web contactImageForURL:contact.mugshotURL]
       addCallback:curryTS(self, @selector(_gotMugshot::), indexPath)];
    } else {
      [mugshots replaceObjectAtIndex:idx
                withObject:[UIImage imageNamed:@"user-70.png"]];
    }
  } else {
    cell.imageView.image = img;
  }
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  cell.textLabel.text = ([contact.fullName length] 
                         ? contact.fullName : contact.username);
  return cell;
}

- (void) tableView:(UITableView *)table
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  int idx = [self indexForIndexPath:indexPath];
  YMContact *contact = (YMContact *)[YMContact findByPK:
                        intv([contactPKs objectAtIndex:idx])];
  YMContactDetailViewController *c = [[[YMContactDetailViewController alloc] init] autorelease];
  c.userAccount = self.userAccount;
  c.contact = contact;
  [self.navigationController pushViewController:c animated:YES];
  if ([searchBar isFirstResponder]) [searchBar resignFirstResponder];
  [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (id)_gotMugshot:(NSIndexPath *)indexPath :(id)result
{
  int idx = [self indexForIndexPath:indexPath];
  if ([result isKindOfClass:[UIImage class]]) {
    [mugshots replaceObjectAtIndex:idx withObject:result];
    YMContactTableViewCell *cell = (YMContactTableViewCell *)
      [self.tableView cellForRowAtIndexPath:indexPath];
    if (cell) cell.imageView.image = result;
  }
  return nil;
}

- (BOOL) searchBarShouldBeginEditing:(UISearchBar *)bar
{
  shouldHideSectionIndex = YES;
  [self.tableView reloadData];
  [self.navigationController setNavigationBarHidden:YES animated:YES];
  [searchBar setShowsCancelButton:YES animated:YES];
  return YES;
}

- (void) searchBar:(UISearchBar *)bar
textDidChange:(NSString *)searchText
{
  self.filterText = searchText;
  [self refreshContactPKs];
  [self.tableView reloadData];
}

- (BOOL) searchBarShouldEndEditing:(UISearchBar *)bar
{
  if (shouldHideSectionIndex) {
    shouldHideSectionIndex = NO;
    [self refreshContactPKs];
    [self.tableView reloadData];
  }
  [searchBar setShowsCancelButton:NO animated:YES];
  [self.navigationController setNavigationBarHidden:NO animated:YES];
  return YES;
}

- (void) searchBarCancelButtonClicked:(UISearchBar *)bar
{
  self.filterText = nil;
  [searchBar setShowsCancelButton:NO animated:YES];
  [self.navigationController setNavigationBarHidden:NO animated:YES];
  [searchBar resignFirstResponder];
}

- (void) searchBarSearchButtonClicked:(UISearchBar *)bar
{
  [self.navigationController setNavigationBarHidden:NO animated:YES];
  [searchBar resignFirstResponder];
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
  [mugshots release];
  mugshots = nil;
  [contactPKs release];
  contactPKs = nil;
  [alphabet release];
  alphabet = nil;
  [alphabetGroups release];
  alphabetGroups = nil;
  [super viewDidUnload];
}


- (void)dealloc
{
  self.tableView = nil;
  self.userAccount = nil;
  self.filterText = nil;
  [super dealloc];
}


@end
