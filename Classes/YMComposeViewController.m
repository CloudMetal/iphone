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
#import "NSMutableArray-MultipleSort.h"
#import "UIImage+Resize.h"
#import "MBProgressHUD.h"

static UIImagePickerController *__imagePicker = nil;

@interface YMComposeViewController (PrivateParts)

- (void)refreshData;

@end


@implementation YMComposeViewController

@synthesize userAccount, network, inReplyTo, inGroup, directTo, onCompleteSend, draft;

- (id)init
{
  if ((self = [super init])) {
    self.hidesBottomBarWhenPushed = YES;
    attachments = [[NSMutableArray alloc] init];
  }
  return self;
}

- (UIImagePickerController *)imagePicker
{
  if (__imagePicker == nil)
    __imagePicker = [[UIImagePickerController alloc] init];
  return __imagePicker;
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
  
  CGRect f = composeView.actionBar.frame;
  f.size.height = 31;
  composeView.actionBar.frame = f;
 
  textView = composeView.messageTextView;
  
  textView.font = [UIFont systemFontOfSize:13];
  composeView.onUserInputsAt = callbackTS(self, userInputAt:);
  composeView.onUserInputsHash = callbackTS(self, userInputHash:);
  composeView.onPartialWillClose = callbackTS(self, textViewPartialWillClose:);
  composeView.onUserPhoto = callbackTS(self, onPhoto:);
  composeView.onUserDrafts = callbackTS(self, onDrafts:);
  composeView.onTextChange = callbackTS(self, onTextChange:);
  
  if (!web) web = [YMWebService sharedWebService];
  
  if (text) textView.text = text;
  
//  if (attachments) [attachments release];
//  attachments = nil;
//  attachments = [[NSMutableArray array] retain];
}

- (void) viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  self.navigationItem.rightBarButtonItem = 
  [[UIBarButtonItem alloc] initWithTitle:@"Send" style:UIBarButtonItemStyleDone 
                                  target:self action:@selector(sendMessage:)];
  if (!composeView.onPhoto && !HUD)
    [textView becomeFirstResponder];
  
  if (!usernames)
    usernames = [[[YMContact pairedArraysForProperties:array_(@"username") 
                   withCriteria:@"WHERE network_i_d=%i", 
                   intv(network.networkID)] objectAtIndex:1] retain];
  if (!hashes) hashes = [EMPTY_ARRAY retain];
  
  composeView.interfaceOrientation = self.interfaceOrientation;
  if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
    NSLog(@"will rotate to landscape");
    composeView.tableView.frame = CGRectMake(0, 106, 480, 162);
    composeView.actionBar.frame = CGRectMake(0, 75, 480, 31);
  } else {
    composeView.tableView.frame = CGRectMake(0, 200, 320, 216);
    composeView.actionBar.frame = CGRectMake(0, 169, 320, 31);
  }

  [self refreshData];
}

////- (void)viewDidAppear:(BOOL)animated
////{
  ////[super viewDidAppear:animated];
////}

- (BOOL)shouldAutorotateToInterfaceOrientation:
(UIInterfaceOrientation)interfaceOrientation
{
//  if (composeView.onPartial || composeView.onUser 
//      || composeView.onHash || composeView.onPhoto) return NO;
//  if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
//    composeView.tableView.frame = CGRectMake(0, 160, 480, 160);
//    composeView.actionBar.frame = CGRectMake(0, 129, 480, 31);
//    [composeView.tableView setHidden:YES];
//    [composeView.actionBar setHidden:YES];
//  } else {
//    composeView.tableView.frame = CGRectMake(0, 200, 320, 216);
//    composeView.actionBar.frame = CGRectMake(0, 169, 320, 31);
//    [composeView.tableView setHidden:NO];
//    [composeView.actionBar setHidden:NO];
//  }
  return YES;
}

-(void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
  [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
  composeView.interfaceOrientation = toInterfaceOrientation;
  if (composeView.onPartial) [composeView hidePartial];
  if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
    NSLog(@"will rotate to landscape");
    composeView.tableView.frame = CGRectMake(0, 106, 480, 162);
    composeView.actionBar.frame = CGRectMake(0, 75, 480, 31);
  } else {
    composeView.tableView.frame = CGRectMake(0, 200, 320, 216);
    composeView.actionBar.frame = CGRectMake(0, 169, 320, 31);
  }
}

- (void)showFromController:(UIViewController *)controller 
                  animated:(BOOL)animated
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

- (id)onTextChange:(NSString *)theText
{
  if (text) [text release];
  text = [theText copy];
  return nil;
}

- (void)sendMessage:(id)sender
{
  if (![textView.text length]) {
    [[[[UIAlertView alloc]
      initWithTitle:@"Unable To Send" message:@"The message body is empty."
       delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil]
      autorelease] show];
    return;
  }
  NSMutableDictionary *params = [NSMutableDictionary dictionary];
  if (self.inReplyTo) {
    [params setObject:[self.inReplyTo.messageID stringValue] 
               forKey:YMReplyToIDKey];
    if (self.inReplyTo.groupID) [params setObject:
                                 [self.inReplyTo.groupID stringValue]
                                           forKey:YMGroupIDKey];
  }
  if (self.inGroup)
    [params setObject:[self.inGroup.groupID stringValue] forKey:YMGroupIDKey];
  if (self.directTo)
    [params setObject:[self.directTo.userID stringValue] 
               forKey:YMDirectToIDKey];
  NSMutableDictionary *attaches = [NSMutableDictionary dictionary];
  if ([attachments count]) {
    for (int i = 0; i < [attachments count]; i++) {
      [attaches setObject:[attachments objectAtIndex:i] forKey:
       [NSString stringWithFormat:@"photo-%i.jpg", i + 1]];
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
//  if ([textView.text length]) {
//    UIActionSheet *a = [[[UIActionSheet alloc] initWithTitle:
//                         @"Would you like to save this message as a draft?" delegate:
//                         self cancelButtonTitle:@"No" destructiveButtonTitle:
//                         nil otherButtonTitles:@"Yes", nil] autorelease];
//    a.tag = 101;
//    [a showInView:self.view];
//    return;
//  }
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
  [[StatusBarNotifier sharedNotifier] setHidden:YES];
  onPhoto = YES;
  onDrafts = NO;
  UIView *v = [[[UIView alloc] initWithFrame:
                CGRectMake(0, 0, composeView.tableView.frame.size.width, 44)]
               autorelease];
  if (!([attachments count] > 8)) {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button setBackgroundImage:[[UIImage imageNamed:@"blue-button-bg.png"] 
                                stretchableImageWithLeftCapWidth:8 topCapHeight:8] 
                      forState:UIControlStateNormal];
    button.frame 
      = CGRectMake(6, 6, composeView.tableView.frame.size.width - 12, 32);
    [button setTitle:@"Add Attachment" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(addAttachment:) forControlEvents:
     UIControlEventTouchUpInside];
    [v addSubview:button];
  } else {
    UILabel *l = [[[UILabel alloc] initWithFrame:
                   CGRectMake(10, 10, 150, 35)] autorelease];
    l.text = @"Maximum attachments reached";
    l.font = [UIFont boldSystemFontOfSize:16];
    [v addSubview:l];
  }
  if (![attachments count]) {
    [self addAttachment:nil];
  }

  composeView.tableView.delegate = self;
  composeView.tableView.dataSource = self;
  composeView.tableView.tableHeaderView = v;
  [composeView.tableView reloadData];
  return nil;
}

- (id)onDrafts:(id)s
{
  [textView resignFirstResponder];
  onPhoto = NO;
  onDrafts = YES;
  composeView.tableView.delegate = self;
  composeView.tableView.dataSource = self;
  [composeView.tableView reloadData];
  return nil;
}

- (void)addAttachment:(id)s
{
  if (![UIImagePickerController isSourceTypeAvailable:
        UIImagePickerControllerSourceTypeCamera]) {
    [self actionSheet:nil didDismissWithButtonIndex:1];
    return;
  }
  
  UIActionSheet *a = 
  [[[UIActionSheet alloc] initWithTitle:@"Choose Source" delegate:self 
                      cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil 
            otherButtonTitles:@"Camera", @"Existing Photo", nil] autorelease];
  [a showInView:self.view];
}

-(void) actionSheet:(UIActionSheet *)actionSheet 
didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  if (actionSheet.tag == 101) {
    if (buttonIndex == 0) {
//      YMDraft *d = [[[YMDraft alloc] init] autorelease];
//      d.groupID = inGroup.groupID;
//      d.inReplyToID = inReplyTo.messageID;
//      d.directToID = directTo.userID;
//      d.attachments = attachments;
//      d.body = textView.text;
//      d.networkPK = nsni(network.pk);
//      d.userAccountPK = nsni(userAccount.pk);
//      [d save];
    }
    self.navigationItem.leftBarButtonItem = nil;
    [self.navigationController.parentViewController 
     dismissModalViewControllerAnimated:YES];
    return;
  }
  NSLog(@"button index %i %@", buttonIndex, self.imagePicker);
  self.imagePicker.delegate = self;
  if (buttonIndex == 0) {
    self.imagePicker.sourceType 
      = UIImagePickerControllerSourceTypeCamera;
  } else if (buttonIndex == 1) {
    self.imagePicker.sourceType 
      = UIImagePickerControllerSourceTypePhotoLibrary;
  } else {
    [composeView kb:nil];
  }
  if (buttonIndex < 2) [self presentModalViewController:self.imagePicker 
                                               animated:YES]; 
}

-(void) imagePickerController:(UIImagePickerController *)picker 
        didFinishPickingImage:(UIImage *)image 
                  editingInfo:(NSDictionary *)editingInfo
{
  [self dismissModalViewControllerAnimated:YES];
  HUD = [[MBProgressHUD alloc] initWithView:self.view];
  [self.view addSubview:HUD];
  HUD.delegate = self;
  HUD.labelText = @"Processing...";
  [HUD showWhileExecuting:@selector(processPhoto:) onTarget:
   self withObject:image animated:YES];
}

- (void)processPhoto:(UIImage *)img
{
  UIImage *scaled = [img resizedImageWithContentMode:
                     UIViewContentModeScaleAspectFit bounds:
                     CGSizeMake(1024, 1024) interpolationQuality:
                     kCGInterpolationDefault];
  [self performSelectorOnMainThread:@selector(doneProcessingPhoto:) 
                         withObject:scaled waitUntilDone:NO];
  return;
}

- (void)doneProcessingPhoto:(UIImage *)img
{
  [attachments addObject:img];
  [composeView photo:nil];
  [composeView.tableView reloadData];
}

- (void)hudWasHidden
{
  [HUD removeFromSuperview];
  [HUD release];
  HUD = nil;
}

- (id)textViewPartialWillClose:(id)sender
{
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
  if (searchIndexSet) [searchIndexSet release];
  searchIndexSet = nil;
  if (hashes) [hashes release];
  hashes = nil;
  [[web autocomplete:self.userAccount string:username]
   addBoth:callbackTS(self, _gotAutocompleteUsers:)];
  composeView.tableView.tableHeaderView = nil;
  [composeView.activity startAnimating];
  [composeView.tableView reloadData];
  return nil;
}

- (id)_gotAutocompleteUsers:(id)results
{
  if (![results isKindOfClass:[NSDictionary class]]) return results;
  
  if (usernames) [usernames release];
  usernames = nil;
  if (fullNames) [fullNames release];
  fullNames = nil;
  if (searchIndexSet) [searchIndexSet release];
  searchIndexSet = nil;
  NSMutableArray *newUsernames = [NSMutableArray array];
  NSMutableArray *newFullnames = [NSMutableArray array];
  for (NSDictionary *u in [results objectForKey:@"users"]) {
    [newUsernames addObject:[u objectForKey:@"name"]];
    [newFullnames addObject:[u objectForKey:@"full_name"]];
  }

  [newUsernames sortArrayUsingSelector:
   @selector(localizedCaseInsensitiveCompare:)
               withPairedMutableArrays:newFullnames, nil];
  
  searchIndexSet = [[NSMutableArray array] retain];
  for (int i = 0; i < [newUsernames count]; i++) {
    [searchIndexSet addObject:nsni(i)];
  }
  usernames = [newUsernames retain];
  fullNames = [newFullnames retain];
  
  composeView.tableView.delegate = self;
  composeView.tableView.dataSource = self;
  [composeView.tableView reloadData];
  
  [composeView.activity stopAnimating];
  
  if (composeView.onPartial) {
    [composeView revealPartial];
    composeView.tableView.tableHeaderView = nil;
  } else {
    UISearchBar *b = [[[UISearchBar alloc] initWithFrame:
                       CGRectMake(0, 0, 320, 44)] autorelease];
    b.delegate = self;
    composeView.tableView.tableHeaderView = b;
  }
  
  return results;
}

- (id)userInputHash:(NSString *)hash
{
  if (!composeView.onPartial) {
    if (hashes) [hashes release];
    hashes = nil;
  }
  if (searchIndexSet) [searchIndexSet release];
  searchIndexSet = nil;
  if (usernames) [usernames release];
  if (fullNames) [fullNames release];
  usernames = fullNames = nil;
  [[web autocomplete:self.userAccount string:hash]
   addBoth:callbackTS(self, _gotAutocompleteHashes:)];
  [composeView.activity startAnimating];
  composeView.tableView.tableHeaderView = nil;
  [composeView.tableView reloadData];
  return nil;
}

- (id)_gotAutocompleteHashes:(id)results
{
  if (![results isKindOfClass:[NSDictionary class]]) return results;
  
  if (hashes) [hashes release];
  hashes = nil;
  if (searchIndexSet) [searchIndexSet release];
  searchIndexSet = nil;
  
  NSMutableArray *newHashes = [NSMutableArray array];
  for (NSDictionary *h in [results objectForKey:@"tags"]) {
    [newHashes addObject:[h objectForKey:@"name"]];
  }
  hashes = [newHashes retain];
  searchIndexSet = [[NSMutableArray array] retain];
  for (int i = 0; i < [newHashes count]; i++) {
    [searchIndexSet addObject:nsni(i)];
  }
  
  composeView.tableView.delegate = self;
  composeView.tableView.dataSource = self;
  [composeView.tableView reloadData];
  
  [composeView.activity stopAnimating];
  
  if (composeView.onPartial) {
    [composeView revealPartial];
    composeView.tableView.tableHeaderView = nil;
  } else {
    UISearchBar *b = [[[UISearchBar alloc] initWithFrame:
                       CGRectMake(0, 0, 320, 44)] autorelease];
    b.showsCancelButton = NO;
    b.delegate = self;
    composeView.tableView.tableHeaderView = b;
  }
  
  return results;
}

- (BOOL) searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
  [searchBar setShowsCancelButton:YES animated:YES];
  [self.navigationController setNavigationBarHidden:YES animated:YES];
  [composeView.tableView.superview bringSubviewToFront:composeView.tableView];
  [composeView.actionBar.superview bringSubviewToFront:composeView.actionBar];
  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationDuration:.30];
  composeView.tableView.frame 
    = CGRectInset(CGRectOffset(composeView.tableView.frame, 0, -217), 0, 0);
  composeView.tableView.contentInset = UIEdgeInsetsMake(44, 0, 0, 0);
  composeView.actionBar.frame 
    = CGRectOffset(composeView.actionBar.frame, 0, -217);
  [composeView.tableView scrollRectToVisible:
   CGRectMake(0, 0, 320, 44) animated:YES];
  [UIView commitAnimations];
  return YES;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
  NSMutableArray *newIndex = [NSMutableArray array];
  BOOL search = [searchText length] > 0;
  if (composeView.onUser) {
    for (int i = 0; i < [usernames count]; i++) {
      if (([[usernames objectAtIndex:i] rangeOfString:
            searchText options:NSCaseInsensitiveSearch].location != NSNotFound) 
          || ([[fullNames objectAtIndex:i] rangeOfString:
            searchText options:NSCaseInsensitiveSearch].location != NSNotFound) 
          || !search)
        [newIndex addObject:nsni(i)];
    }
  } else {
    for (int i = 0; i < [hashes count]; i++) {
      if ([[hashes objectAtIndex:i] rangeOfString:
           searchText options:NSCaseInsensitiveSearch].location != NSNotFound 
          || !search)
        [newIndex addObject:nsni(i)];
    }
  }
  if (searchIndexSet) [searchIndexSet release];
  searchIndexSet = nil;
  searchIndexSet = [newIndex retain];
  [composeView.tableView reloadData];
}

- (void) searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
  [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
  searchBar.text = @"";
  [searchBar resignFirstResponder];
}

- (BOOL) searchBarShouldEndEditing:(UISearchBar *)searchBar
{
  [searchBar setShowsCancelButton:NO animated:YES];
  [self.navigationController setNavigationBarHidden:NO animated:YES];
  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationDuration:.30];
  composeView.tableView.frame 
    = CGRectInset(CGRectOffset(composeView.tableView.frame, 0, 217), 0, 0);
  composeView.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
  composeView.actionBar.frame 
    = CGRectOffset(composeView.actionBar.frame, 0, 217);  
  [UIView commitAnimations];
  return YES;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)table
{
  return 1;
}

- (NSInteger) tableView:(UITableView *)table
numberOfRowsInSection:(NSInteger)section
{
  if (composeView.onPhoto) return [attachments count];
  if (searchIndexSet) return [searchIndexSet count];
//  if (composeView.onUser) {
//    return [usernames count];
//  } else if (composeView.onHash) {
//    return [hashes count];
//  }
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
                  UITableViewCellStyleDefault reuseIdentifier:pident]
                 autorelease];
    c.imageView.image = [attachments objectAtIndex:indexPath.row];
    c.textLabel.text = [NSString stringWithFormat:@"photo-%i.jpg", 
                        indexPath.row + 1];
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
                                        [UIImage imageNamed:
                                         @"user-bg-small.png"]];
    c.textLabel.textColor = [UIColor whiteColor];
    c.detailTextLabel.textColor = [UIColor colorWithWhite:.8 alpha:1];
    c.textLabel.font = [UIFont systemFontOfSize:15];
  }  
  if (composeView.onUser && [usernames count]) {
    int i = intv([searchIndexSet objectAtIndex:indexPath.row]);
    NSString *s = [NSString stringWithFormat:@"@%@ (%@)", 
                   [usernames objectAtIndex:i], 
                   [fullNames objectAtIndex:i]];
    c.textLabel.text = s;
  } else if (composeView.onHash && [hashes count]) {
    int i = intv([searchIndexSet objectAtIndex:indexPath.row]);
    c.imageView.image = nil;
    c.detailTextLabel.text = @"";
    c.textLabel.text = [@"#" stringByAppendingString:
                        [hashes objectAtIndex:i]];
  }
  return c;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:
(NSIndexPath *)indexPath
{
  return composeView.onPhoto;
}

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:
(NSIndexPath *)indexPath
{
  NSLog(@"willbeginediting %@", indexPath);
}

- (void) tableView:(UITableView *)tableView commitEditingStyle:
(UITableViewCellEditingStyle)editingStyle 
 forRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (composeView.onPhoto) {
    [attachments removeObjectAtIndex:indexPath.row];
    [tableView deleteRowsAtIndexPaths:array_(indexPath) withRowAnimation:
     UITableViewRowAnimationBottom];
  }
}

- (UITableViewCellEditingStyle) tableView:(UITableView *)tableView 
            editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (composeView.onPhoto) return UITableViewCellEditingStyleDelete;
  return UITableViewCellEditingStyleNone;
}

- (NSIndexPath *) tableView:(UITableView *)tableView 
   willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (composeView.onPhoto) return nil;
  return indexPath;
}

- (void) tableView:(UITableView *)table
willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:
(NSIndexPath *)indexPath
{
  cell.textLabel.backgroundColor = [UIColor clearColor];
  cell.detailTextLabel.backgroundColor = [UIColor clearColor];
}

- (void) tableView:(UITableView *)table
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (composeView.onUser) {
    [composeView performAutocomplete:[@"@" stringByAppendingString:
    [usernames objectAtIndex:intv([searchIndexSet objectAtIndex:indexPath.row])]]
                           isAppending:!composeView.onPartial];
  } else if (composeView.onHash) {
    [composeView performAutocomplete:[@"#" stringByAppendingString:
      [hashes objectAtIndex:intv([searchIndexSet objectAtIndex:indexPath.row])]]
                           isAppending:!composeView.onPartial];
  }
  if (composeView.onPartial)
    [composeView hidePartial];
  UISearchBar *b = (UISearchBar *)composeView.tableView.tableHeaderView;
  if (b && [b isKindOfClass:[UISearchBar class]] && [b isFirstResponder]) 
    [b resignFirstResponder];
  [table deselectRowAtIndexPath:indexPath animated:YES];
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
  [text release];
  [attachments release];
  [usernames release];
  [hashes release];
  self.onCompleteSend = nil;
  self.network = nil;
  self.inGroup = nil;
  self.inReplyTo = nil;
  self.directTo = nil;
  self.userAccount = nil;
  [super dealloc];
}


@end
