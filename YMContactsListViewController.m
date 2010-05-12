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
#import "NSMutableArray-MultipleSort.h"

@interface YMContactsListViewController (PrivateStuffs)

- (void)refreshContactPKs;
- (NSInteger)indexForIndexPath:(NSIndexPath *)indexPath;
- (NSString *)searchQuery;

@end


@implementation YMContactsListViewController

@synthesize userAccount, filterText;

- (void)loadView
{
  self.tableView = [[UITableView alloc] initWithFrame:
                    CGRectMake(0, 0, 320, 460) style:UITableViewStylePlain];
  self.tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                     UIViewAutoresizingFlexibleHeight);
  self.tableView.delegate = self;
  self.tableView.dataSource = self;
  self.tableView.backgroundColor = [UIColor whiteColor];
  
  UISearchBar *searchBar = [[UISearchBar alloc]
                            initWithFrame:CGRectMake(0, 0, 320, 44)];
  searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  searchBar.delegate = self;
  searchBar.showsCancelButton = YES;
  self.tableView.tableHeaderView = searchBar;
  
  self.title = @"Contacts";
  
  if (!web) web = [YMWebService sharedWebService];
}

- (void)viewWillAppear:(BOOL)animated 
{
  self.filterText = nil;
  [super viewWillAppear:animated];
  [self refreshContactPKs];
  [self.tableView reloadData];
}

- (void) viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  [[web syncUsers:self.userAccount]
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
  if (self.filterText) return @"";
  return [NSString stringWithFormat:
          @" AND full_name LIKE '%%%%%@%%%%'",
          self.filterText];
}

- (id)_usersUpdated:(id)r
{
  [self refreshContactPKs];
  [self.tableView reloadData];
  if (isDeferred(r))
    return [r addCallback:callbackTS(self, _usersUpdated:)];
  return r;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)table
{
  return [alphabet count];
}

- (NSArray *) sectionIndexTitlesForTableView:(UITableView *)table
{
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

- (BOOL) searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
  [self.navigationController setNavigationBarHidden:YES animated:YES];
  return YES;
}

- (void) searchBar:(UISearchBar *)searchBar
textDidChange:(NSString *)searchText
{
  self.filterText = searchText;
  [self refreshContactPKs];
  [self.tableView reloadData];
}

- (BOOL) searchBarShouldEndEditing:(UISearchBar *)searchBar
{
  [self.tableView setSectionIndexMinimumDisplayRowCount:1000000];
  [self.navigationController setNavigationBarHidden:NO animated:YES];
  return YES;
}

- (void) searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
  self.filterText = nil;
  [self.tableView setSectionIndexMinimumDisplayRowCount:10];
  [self.navigationController setNavigationBarHidden:NO animated:YES];
  [searchBar resignFirstResponder];
}

- (void) searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
  [self.tableView setSectionIndexMinimumDisplayRowCount:10];
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
  [super viewDidUnload];
}


- (void)dealloc
{
  self.tableView = nil;
  [super dealloc];
}


@end
