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
  composeView = (YMComposeView *)self.view;
  
//  UIButton *cancel = [(id)self.view cancel], *send = [(id)self.view send];
//  UIToolbar *actionBar = [(id)self.view actionBar];
  
//  [composeView.cancel setBackgroundImage:
//   [[UIImage imageNamed:@"toolbarbutton.png"] stretchableImageWithLeftCapWidth:
//    10 topCapHeight:10] forState:UIControlStateNormal];
//  [composeView.send setBackgroundImage:
//   [[UIImage imageNamed:@"toolbarbutton.png"] stretchableImageWithLeftCapWidth:
//    10 topCapHeight:10] forState:UIControlStateNormal];
  CGRect f = composeView.actionBar.frame;
  f.size.height = 27;
  composeView.actionBar.frame = f;
  
  textView = ((YMComposeView *)self.view).messageTextView;
//  textView.userDataSource = self;
//  textView.hashDataSource = self;
  
  textView.font = [UIFont systemFontOfSize:13];
//  [(id)self.view setOnUserInputsAt:callbackTS(self, userInputAt:)];
//  [(id)self.view setOnUserInputsHash:callbackTS(self, userInputHash:)];
//  [(id)self.view setOnPartialWillClose:callbackTS(self, textViewPartialWillClose:)];
  composeView.onUserInputsAt = callbackTS(self, userInputAt:);
  composeView.onUserInputsHash = callbackTS(self, userInputHash:);
  composeView.onPartialWillClose = callbackTS(self, textViewPartialWillClose:);
  composeView.onUserPhoto = callbackTS(self, onPhoto:);
  
  if (!web) web = [YMWebService sharedWebService];
  
  if (attachments) [attachments release];
  attachments = nil;
  attachments = [[NSMutableArray array] retain];
}

- (void) viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  self.navigationItem.rightBarButtonItem = 
  [[UIBarButtonItem alloc] initWithTitle:@"Send" style:UIBarButtonItemStyleDone 
                                  target:self action:@selector(sendMessage:)];
  if (!composeView.onPhoto)
    [textView becomeFirstResponder];
  
  if (!usernames)
    usernames = [[[YMContact pairedArraysForProperties:array_(@"username") 
                   withCriteria:@"WHERE network_i_d=%i", intv(network.networkID)]
                  objectAtIndex:1] retain];
  if (!hashes) hashes = [EMPTY_ARRAY retain];
  
  if(UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
    [composeView.actionBar setHidden:YES];
  }

  [self refreshData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  if (composeView.onPartial || composeView.onUser || composeView.onHash || composeView.onPhoto) return NO;
  if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) [composeView.actionBar setHidden:YES];
  else [composeView.actionBar setHidden:NO];
  return YES;
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
  NSMutableDictionary *attaches = [NSMutableDictionary dictionary];
  if ([attachments count]) {
    for (int i = 0; i < [attachments count]; i++) {
      [attaches setObject:[attachments objectAtIndex:i] forKey:[NSString stringWithFormat:@"photo-%i.jpg", i + 1]];
    }
  }
  //NSLog(@"params %@", params);
  DKDeferred *d = [web postMessage:self.userAccount 
                   body:textView.text replyOpts:params 
                       attachments:attaches];
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

- (id)onPhoto:(id)s
{
  [textView resignFirstResponder];
  onPhoto = YES;
  UIView *v = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, composeView.tableView.frame.size.width, 52)] autorelease];
  if (!([attachments count] > 8)) {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.frame = CGRectMake(4, 4, composeView.tableView.frame.size.width - 8, 44);
    [button setTitle:@"Add Attachment" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(addAttachment:) forControlEvents:UIControlEventTouchUpInside];
    [v addSubview:button];
  } else {
    UILabel *l = [[[UILabel alloc] initWithFrame:CGRectMake(10, 10, 150, 35)] autorelease];
    l.text = @"Maximum attachments reached";
    l.font = [UIFont boldSystemFontOfSize:16];
    [v addSubview:l];
  }
  composeView.tableView.delegate = self;
  composeView.tableView.dataSource = self;
  composeView.tableView.tableHeaderView = v;
  [composeView.tableView reloadData];
  return nil;
}

- (void)addAttachment:(id)s
{
  UIActionSheet *a = [[[UIActionSheet alloc] initWithTitle:@"Choose Source" delegate:self 
                                        cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil 
                                         otherButtonTitles:@"Camera", @"Existing Photo", nil] autorelease];
  [a showInView:self.view];
}

-(void) actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  NSLog(@"button index %i %@", buttonIndex, composeView.imagePicker);
  composeView.imagePicker.delegate = self;
  if (buttonIndex == 0) {
    composeView.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
  } else if (buttonIndex == 1) {
    composeView.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
  }
  if (buttonIndex < 2) [self presentModalViewController:composeView.imagePicker animated:YES]; //[self.navigationController pushViewController:composeView.imagePicker animated:YES];
}

-(void) imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo
{
  [attachments addObject:image];
  NSLog(@"attachments %@", attachments);
  [composeView.tableView reloadData];
  [self dismissModalViewControllerAnimated:YES];
}

- (id)textViewPartialWillClose:(id)sender
{
//  [self.navigationController setNavigationBarHidden:NO animated:YES];
//  gotPartialWillCloseMessage = YES;
  if (usernames) [usernames release];
  usernames = [[[YMContact pairedArraysForProperties:array_(@"username") 
                 withCriteria:@"WHERE network_i_d=%i", intv(network.networkID)]
                objectAtIndex:1] retain];
  [composeView hidePartial];
  return nil;
}

- (id)userInputAt:(NSString *)username
{
  NSLog(@"username %@", username);
  if (!composeView.onPartial) {
    if (usernames) [usernames release];
    usernames = nil;
    if (fullNames) [fullNames release];
    fullNames = nil;
  }
//  gotPartialWillCloseMessage = NO;
  [[web autocomplete:self.userAccount string:username]
   addBoth:callbackTS(self, _gotAutocompleteUsers:)];
  composeView.tableView.tableHeaderView = nil;
  [composeView.activity startAnimating];
  return nil;
}

- (id)_gotAutocompleteUsers:(id)results
{
//  NSLog(@"autocomplete? %@", results);
//  if (gotPartialWillCloseMessage) return results;
  if (![results isKindOfClass:[NSDictionary class]]) return results;
  
  if (usernames) [usernames release];
  usernames = nil;
  if (fullNames) [fullNames release];
  fullNames = nil;
  NSMutableArray *newUsernames = [NSMutableArray array];
  NSMutableArray *newFullnames = [NSMutableArray array];
  for (NSDictionary *u in [results objectForKey:@"users"]) {
    NSLog(@"u %@", u);
    [newUsernames addObject:[u objectForKey:@"name"]];
    [newFullnames addObject:[u objectForKey:@"full_name"]];
  }
  usernames = [newUsernames retain];
  fullNames = [newFullnames retain];
  
  composeView.tableView.delegate = self;
  composeView.tableView.dataSource = self;
  [composeView.tableView reloadData];
  
  [composeView.activity stopAnimating];
  
  if (composeView.onPartial) [composeView revealPartial];
//  else [composeView hidePartial];
  
//  [self.navigationController setNavigationBarHidden:YES animated:YES];
//  [textView revealPartialAt:nil];
  return results;
}

- (id)userInputHash:(NSString *)hash
{
//  NSLog(@"hash %@", hash);
//  gotPartialWillCloseMessage = NO;
  if (!composeView.onPartial) {
    if (hashes) [hashes release];
    hashes = nil;
  }
  [[web autocomplete:self.userAccount string:hash]
   addBoth:callbackTS(self, _gotAutocompleteHashes:)];
  [composeView.activity startAnimating];
  composeView.tableView.tableHeaderView = nil;
  return nil;
}

- (id)_gotAutocompleteHashes:(id)results
{
//  NSLog(@"_gotAutocompleteHashes %@", results);
//  if (gotPartialWillCloseMessage) return results;
  if (![results isKindOfClass:[NSDictionary class]]) return results;
  
  if (hashes) [hashes release];
  hashes = nil;
  NSMutableArray *newHashes = [NSMutableArray array];
  for (NSDictionary *h in [results objectForKey:@"tags"]) {
    [newHashes addObject:[h objectForKey:@"name"]];
  }
  hashes = [newHashes retain];
  
  composeView.tableView.delegate = self;
  composeView.tableView.dataSource = self;
  [composeView.tableView reloadData];
  
  [composeView.activity stopAnimating];
  
  if (composeView.onPartial) [composeView revealPartial];
  
//  [self.navigationController setNavigationBarHidden:YES animated:YES];
//  [textView revealPartialHash:nil];
  
  return results;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)table
{
  return 1;
}

- (NSInteger) tableView:(UITableView *)table
numberOfRowsInSection:(NSInteger)section
{
  if (composeView.onPhoto) return [attachments count];
  if (composeView.onUser) {
    return [usernames count];
  } else if (composeView.onHash) {
    return [hashes count];
  }
  return 0;
}

- (CGFloat) tableView:(UITableView *)table
heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (composeView.onPhoto) return 44;
  return 35;
}

- (UITableViewCell *) tableView:(UITableView *)table
cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *pident = @"YMAttachmentCell2";
  if (composeView.onPhoto) {
    UITableViewCell *c = [table dequeueReusableCellWithIdentifier:pident];
    if (!c) c = [[[UITableViewCell alloc] initWithStyle:
                  UITableViewCellStyleDefault reuseIdentifier:pident] autorelease];
    c.imageView.image = [attachments objectAtIndex:indexPath.row];
    c.textLabel.text = [NSString stringWithFormat:@"photo-%i.jpg", indexPath.row + 1];
    return c;
  }
  
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
  NSLog(@"composeview.onUser %i", composeView.onUser);
  if (composeView.onUser) {
//    YMContact *contact = (YMContact *)[YMContact findFirstByCriteria:
//               @"WHERE network_i_d=%i AND username='%@'", 
//               intv(network.networkID), [usernames objectAtIndex:indexPath.row]];
//    if (!contact) return c;
//    UIImage *img = [web imageForURLInMemoryCache:contact.mugshotURL];
//    if (!img || [img isEqual:[NSNull null]])
//      img = [UIImage imageNamed:@"user-70.png"];
//    c.imageView.image = img;
    NSString *s = [NSString stringWithFormat:@"@%@ (%@)", 
                   [usernames objectAtIndex:indexPath.row], [fullNames objectAtIndex:indexPath.row]];
    NSLog(@"s %@", s);
    c.textLabel.text = s;
  } else if (composeView.onHash) {
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
  if (composeView.onUser) {
    [composeView performAutocomplete:[@"@" stringByAppendingString:
                                        [usernames objectAtIndex:indexPath.row]]
                           isAppending:!composeView.onPartial];
  } else if (composeView.onHash) {
    [composeView performAutocomplete:[@"#" stringByAppendingString:
                                        [hashes objectAtIndex:indexPath.row]]
                           isAppending:!composeView.onPartial];
  }
  [composeView hidePartial];
  [table deselectRowAtIndexPath:indexPath animated:YES];
  //[textView doKeyboard:nil];
}

//- (BOOL)shouldAutorotateToInterfaceOrientation:
//(UIInterfaceOrientation)interfaceOrientation
//{
// return YES;
//}

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
