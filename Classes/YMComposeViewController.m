    //
//  YMComposeViewController.m
//  Yammer
//
//  Created by Samuel Sutch on 5/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "YMComposeViewController.h"
#import "YMComposeView.h"
#import "YMMessageTextView.h"
#import "YMWebService.h"
#import "StatusBarNotifier.h"


@interface YMComposeViewController (PrivateParts)

- (void)refreshData;

@end


@implementation YMComposeViewController

@synthesize userAccount, network, inReplyTo, inGroup, directTo;

- (id)init
{
  if ((self = [super init])) {
    self.hidesBottomBarWhenPushed = YES;
  }
  return self;
}

- (void)loadView
{
  for (id v in [[NSBundle mainBundle] 
                loadNibNamed:@"YMComposeView" owner:nil options:nil]) {
    if (![v isKindOfClass:[YMComposeView class]]) continue;
    self.view = v;
  }
  self.title = @"New Message";
  
  textView = ((YMComposeView *)self.view).messageTextView;
  textView.userDataSource = self;
  textView.hashDataSource = self;
  textView.font = [UIFont systemFontOfSize:13];
  [(id)self.view setOnUserInputsAt:callbackTS(self, userInputAt:)];
  [(id)self.view setOnUserInputsHash:callbackTS(self, userInputHash:)];
  [(id)self.view setOnPartialWillClose:callbackTS(self, textViewPartialWillClose:)];
  
  if (!web) web = [YMWebService sharedWebService];
}

- (void) viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  self.navigationItem.rightBarButtonItem = 
  [[UIBarButtonItem alloc] initWithTitle:@"Send" style:UIBarButtonItemStyleDone 
                                  target:self action:@selector(sendMessage:)];
  [textView becomeFirstResponder];
  if (!usernames)
    usernames = [[[YMContact pairedArraysForProperties:array_(@"username") 
                   withCriteria:@"WHERE network_i_d=%i", intv(network.networkID)]
                  objectAtIndex:1] retain];
  if (!hashes) hashes = [EMPTY_ARRAY retain];

  [self refreshData];
}

- (void)showFromController:(UIViewController *)controller animated:(BOOL)animated
{
  UINavigationController *c = [[[UINavigationController alloc]
                               initWithRootViewController:self] autorelease];
  self.navigationItem.leftBarButtonItem = 
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:
     UIBarButtonSystemItemCancel target:self action:@selector(cancelSend:)];
  
  if (controller.navigationController)
    c.navigationBar.tintColor 
      = controller.navigationController.navigationBar.tintColor;
  
  [controller presentModalViewController:c animated:YES];
}

- (void)sendMessage:(id)sender
{
  NSMutableDictionary *params = [NSMutableDictionary dictionary];
  if (self.inReplyTo) {
    [params setObject:[self.inReplyTo.messageID stringValue] forKey:YMReplyToIDKey];
    if (self.inReplyTo.groupID) [params setObject:[self.inReplyTo.groupID
                                                   stringValue] forKey:YMGroupIDKey];
    
  }
  if (self.inGroup)
    [params setObject:[self.inGroup.groupID stringValue] forKey:YMGroupIDKey];
  if (self.directTo)
    [params setObject:[self.directTo.userID stringValue] forKey:YMDirectToIDKey];
  NSLog(@"params %@", params);
  DKDeferred *d = [web postMessage:self.userAccount 
                   body:textView.text replyOpts:params 
                       attachments:EMPTY_DICT];
  [[StatusBarNotifier sharedNotifier]
   flashLoading:@"Sending Message..." deferred:d];
  
  self.navigationItem.leftBarButtonItem = nil;
  [self.navigationController.parentViewController
   dismissModalViewControllerAnimated:YES];
}

- (void)cancelSend:(id)sender
{
  self.navigationItem.leftBarButtonItem = nil;
  [self.navigationController.parentViewController 
   dismissModalViewControllerAnimated:YES];
}

- (void)setInReplyTo:(YMMessage *)m
{
  if (inReplyTo) [inReplyTo release];
  inReplyTo = [m retain];
  [self refreshData];
}

- (void)refreshData
{
  if (!inReplyTo) {
    if (self.directTo)
      [[(id)self.view toTargetLabel] setText:self.directTo.fullName];
    else if (!self.inGroup)
      [[(id)self.view toTargetLabel] setText:network.name];
    else
      [[(id)self.view toTargetLabel] setText:inGroup.fullName];
    [[(id)self.view toLabel] setText:@"To:"];
  } else {
    [[(id)self.view toTargetLabel] setText:
     [(YMContact *)[YMContact findFirstByCriteria:
                    @"WHERE user_i_d=%i", intv(inReplyTo.senderID)] fullName]];
    [[(id)self.view toLabel] setText:@"Re:"];
  }
}

- (id)textViewPartialWillClose:(id)sender
{
  [self.navigationController setNavigationBarHidden:NO animated:YES];
  gotPartialWillCloseMessage = YES;
  if (usernames) [usernames release];
  usernames = [[[YMContact pairedArraysForProperties:array_(@"username") 
                 withCriteria:@"WHERE network_i_d=%i", intv(network.networkID)]
                objectAtIndex:1] retain];
  return nil;
}

- (id)userInputAt:(NSString *)username
{
  NSLog(@"username %@", username);
  gotPartialWillCloseMessage = NO;
  [[web autocomplete:self.userAccount string:username]
   addBoth:callbackTS(self, _gotAutocompleteUsers:)];
  return nil;
}

- (id)_gotAutocompleteUsers:(id)results
{
  NSLog(@"autocomplete? %@", results);
  if (gotPartialWillCloseMessage) return results;
  if (![results isKindOfClass:[NSDictionary class]]) return results;
  
  if (usernames) [usernames release];
  usernames = nil;
  NSMutableArray *newUsernames = [NSMutableArray array];
  for (NSDictionary *u in [results objectForKey:@"users"]) {
    [newUsernames addObject:[u objectForKey:@"name"]];
  }
  usernames = [newUsernames retain];
  
  [self.navigationController setNavigationBarHidden:YES animated:YES];
  [textView revealPartialAt:nil];
  return results;
}

- (id)userInputHash:(NSString *)hash
{
  NSLog(@"hash %@", hash);
  gotPartialWillCloseMessage = NO;
  [[web autocomplete:self.userAccount string:hash]
   addBoth:callbackTS(self, _gotAutocompleteHashes:)];
  return nil;
}

- (id)_gotAutocompleteHashes:(id)results
{
  NSLog(@"_gotAutocompleteHashes %@", results);
  if (gotPartialWillCloseMessage) return results;
  if (![results isKindOfClass:[NSDictionary class]]) return results;
  
  if (hashes) [hashes release];
  hashes = nil;
  NSMutableArray *newHashes = [NSMutableArray array];
  for (NSDictionary *h in [results objectForKey:@"tags"]) {
    [newHashes addObject:[h objectForKey:@"name"]];
  }
  hashes = [newHashes retain];
  
  [self.navigationController setNavigationBarHidden:YES animated:YES];
  [textView revealPartialHash:nil];
  
  return results;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)table
{
  return 1;
}

- (NSInteger) tableView:(UITableView *)table
numberOfRowsInSection:(NSInteger)section
{
  if (table == textView.userTableView) {
    return [usernames count];
  } else if (table == textView.hashTableView) {
    return [hashes count];
  }
  return 0;
}

- (CGFloat) tableView:(UITableView *)table
heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  return 35;
}

- (UITableViewCell *) tableView:(UITableView *)table
cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *uident = @"YMSmallContactCell";
  UITableViewCell *c = [table dequeueReusableCellWithIdentifier:uident];
  if (!c) {
    c = [[[UITableViewCell alloc]
          initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:uident] 
         autorelease];
    c.frame = CGRectMake(0, 0, 320, 35);
    c.backgroundView = [[UIView alloc] initWithFrame:c.frame];
    c.backgroundView.backgroundColor = [UIColor colorWithPatternImage:
                                        [UIImage imageNamed:@"user-bg-small.png"]];
    c.textLabel.textColor = [UIColor whiteColor];
    c.detailTextLabel.textColor = [UIColor colorWithWhite:.8 alpha:1];
    c.textLabel.font = [UIFont systemFontOfSize:15];
  }
  
  if (table == textView.userTableView) {
    YMContact *contact = (YMContact *)[YMContact findFirstByCriteria:
               @"WHERE network_i_d=%i AND username='%@'", 
               intv(network.networkID), [usernames objectAtIndex:indexPath.row]];
    if (!contact) return c;
    UIImage *img = [web imageForURLInMemoryCache:contact.mugshotURL];
    if (!img || [img isEqual:[NSNull null]])
      img = [UIImage imageNamed:@"user-70.png"];
    c.imageView.image = img;
    c.textLabel.text = [NSString stringWithFormat:@"%@ (%@)", 
                        [usernames objectAtIndex:indexPath.row], contact.fullName];
  } else if (table == textView.hashTableView) {
    c.imageView.image = nil;
    c.detailTextLabel.text = @"";
    c.textLabel.text = [hashes objectAtIndex:indexPath.row];
  }
  return c;
}

- (void) tableView:(UITableView *)table
willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
  cell.textLabel.backgroundColor = [UIColor clearColor];
  cell.detailTextLabel.backgroundColor = [UIColor clearColor];
}

- (void) tableView:(UITableView *)table
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (table == textView.userTableView) {
    [(id)self.view performAutocomplete:[@"@" stringByAppendingString:
                                        [usernames objectAtIndex:indexPath.row]]
                           isAppending:!textView.onPartial];
  } else if (table == textView.hashTableView) {
    [(id)self.view performAutocomplete:[@"#" stringByAppendingString:
                                        [hashes objectAtIndex:indexPath.row]]
                           isAppending:!textView.onPartial];
  }
  [table deselectRowAtIndexPath:indexPath animated:YES];
  [textView doKeyboard:nil];
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
  [super dealloc];
}


@end
