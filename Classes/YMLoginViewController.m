    //
//  ECLoginViewController.m
//  Yammer
//
//  Created by Samuel Sutch on 4/30/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "YMLoginViewController.h"
#import "YMWebService.h"
#import "CFPrettyView.h"
#import <QuartzCore/QuartzCore.h>
#import "UIColor+Extensions.h"

//#import "LocalStorage.h"
//#import "YMLegacyShim.h"
#import "YammerAppDelegate.h"


#define LOGIN_USERNAME_TAG 34343
#define LOGIN_PASSWORD_TAG 34443

/*
 
 @protocol ActionTableViewHeader
 
 - (void)flipImageAnimated:(BOOL)animated;
 - (void)toggleActivityView:(BOOL)isON;
 - (void)setStatus:(int)status;
 
 @property BOOL isFlipped;
 
 @end
*/

@interface CFSpecialTextField : UITextField

@end

@implementation CFSpecialTextField

- (CGRect) textRectForBounds:(CGRect)bounds
{
  return CGRectInset([super textRectForBounds:bounds], 10, 0);
}

- (CGRect) editingRectForBounds:(CGRect)bounds 
{
  return CGRectInset([super textRectForBounds:bounds], 10, 0);
}

@end

@implementation YMThisIsWhereIWantToGoView

@synthesize isFlipped, theTextField;

- (void)flipImageAnimated:(BOOL)animated { }

- (void)toggleActivityView:(BOOL)isOn 
{
  if (isOn) [self setStatus:kLoadingStatus];
}

- (id) initWithFrame:(CGRect)frame
{
  if ((self = [super initWithFrame:frame])) {
    hasFlipped = NO;
    theTextField = [[[CFSpecialTextField alloc]
                   initWithFrame:CGRectMake(10, frame.size.height - 50.0, 300, 44)] retain];
    theTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    theTextField.delegate = self;
    theTextField.font = [UIFont boldSystemFontOfSize:17];
    theTextField.textColor = [UIColor colorWithHexString:@"486681"];
    theTextField.placeholder = @"Pulll down to change URL";
    theTextField.textAlignment = UITextAlignmentLeft;
    theTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    theTextField.backgroundColor = [UIColor whiteColor];
    theTextField.layer.cornerRadius = 10;
    theTextField.layer.borderColor = [UIColor colorWithHexString:@"919191"].CGColor;
    theTextField.layer.borderWidth = 1;
    theTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    theTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    theTextField.keyboardType = UIKeyboardTypeURL;
    [self addSubview:theTextField];
  }
  return self;
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
  hasFlipped = YES;
  [theTextField resignFirstResponder];
  return YES;
}

- (void)setStatus:(int)status
{
  if (hasFlipped) return;
	switch (status) {
		case kReleaseToReloadStatus:
			theTextField.placeholder = @"Release to change URL";
			break;
		case kPullToReloadStatus:
			theTextField.placeholder = @"Pull down to change URL";
			break;
		case kLoadingStatus:
      theTextField.placeholder = WS_URL;
      [theTextField becomeFirstResponder];
		default:
			break;
	}
}


//- (BOOL) textFieldShouldEndEditing:(UITextField *)textField
//{
//  [textField resignFirstResponder];
//  return YES;
//}

//- (void) textFieldDidEndEditing:(UITextField *)textField
//{
//  [textField resignFirstResponder];
//}

@end


@implementation YMLoginViewController

@synthesize web;

- (id) init
{
  if ((self = [super init])) {
    self.actionTableViewHeaderClass = [YMThisIsWhereIWantToGoView class];
  }
  return self;
}

- (void)reloadTableViewDataSource { }

- (void)loadView
{
  self.tableView = [[UITableView alloc] initWithFrame:
                    CGRectMake(0, 0, 320, 460) style:UITableViewStyleGrouped];
  self.tableView.backgroundColor = [UIColor colorWithHexString:@"cae5fd"];
  self.tableView.delegate = self;
  self.tableView.dataSource = self;
  self.navigationItem.titleView = [[UIImageView alloc] initWithImage:
                                   [UIImage imageNamed:@"title.png"]];
  self.navigationItem.hidesBackButton = YES;
  emailAlreadyBecameFirstResponder = NO;
  
  if (!web) web = [YMWebService sharedWebService];
  
//  NSString *upgradeText = @"";
//  if (![[web loggedInUsers] count])
//    upgradeText = @"     Yammer now supports multiple accounts.\n           "
//                  @"Please login to your first account.\n\n";
//  
//  TTStyledText* theText = [TTStyledText textFromXHTML:[NSString stringWithFormat:
//                           @"%@       No account? Sign up on <a href=\"https:"
//                           @"//www.yammer.com/\">yammer.com</a>", upgradeText]
//                                           lineBreaks:YES URLs:YES];
//  TTStyledTextLabel *l = [[TTStyledTextLabel alloc] 
//                          initWithFrame:CGRectMake(10,115,300,100)];
//	[l setText:theText];
//  [l setTextAlignment:UITextAlignmentCenter];
//	l.backgroundColor = [UIColor clearColor];
//	[self.tableView addSubview:l];
}

- (void)viewWillAppear:(BOOL)animated
{
  if ([[web loggedInUsers] count])
    [self.navigationItem setHidesBackButton:NO animated:YES];
  [super viewWillAppear:YES];
}

- (void) viewDidAppear:(BOOL)animated
{
  self.navigationController.navigationBar.tintColor 
    = [UIColor colorWithRed:0.27 green:0.34 blue:0.39 alpha:1.0];
  
//  [[(UIControl *)[[self.tableView visibleCells] 
//  objectAtIndex:0] viewWithTag:LOGIN_USERNAME_TAG] performSelector:
//   @selector(becomeFirstResponder) withObject:nil afterDelay:.2];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)table
{
  return 1;
}

- (NSInteger) tableView:(UITableView *)table 
  numberOfRowsInSection:(NSInteger)section
{
  return 2;
}

- (UITableViewCell *) tableView:(UITableView *)table
          cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:
                           UITableViewCellStyleDefault reuseIdentifier:@"asdfasdf"];
  if (indexPath.row == 0) {
    cell.textLabel.text = @"Email";
    UITextField *f = [[[UITextField alloc] initWithFrame:
                       CGRectMake(115, 9, 190, 35)] autorelease];
    f.keyboardType = UIKeyboardTypeEmailAddress;
    f.borderStyle = UITextBorderStyleNone;
    f.textAlignment = UITextAlignmentRight;
    f.font = [UIFont boldSystemFontOfSize:17];
    f.delegate = self;
    f.returnKeyType = UIReturnKeyNext;
    f.adjustsFontSizeToFitWidth = NO;
    f.autocorrectionType = UITextAutocorrectionTypeNo;
    f.autocapitalizationType = UITextAutocapitalizationTypeNone;
    f.tag = LOGIN_USERNAME_TAG;
    [cell addSubview:f];
    if (!emailAlreadyBecameFirstResponder)
      [f becomeFirstResponder];
    emailAlreadyBecameFirstResponder = YES;
  } else {
    cell.textLabel.text = @"Password";
    UITextField *f = [[[UITextField alloc] initWithFrame:
                       CGRectMake(115, 9, 190, 35)] autorelease];
    f.keyboardType = UIKeyboardTypeDefault;
    f.borderStyle = UITextBorderStyleNone;
    f.textAlignment = UITextAlignmentRight;
    f.secureTextEntry = YES;
    f.delegate = self;
    f.autocorrectionType = UITextAutocorrectionTypeNo;
    f.autocapitalizationType = UITextAutocapitalizationTypeNone;
    f.tag = LOGIN_PASSWORD_TAG;
    f.returnKeyType = UIReturnKeyGo;
    f.font = [UIFont boldSystemFontOfSize:17];
    f.adjustsFontSizeToFitWidth = NO;
    [cell addSubview:f];
  }
  return cell;
}

- (void) tableView:(UITableView *)table
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [table deselectRowAtIndexPath:indexPath animated:YES];
  
  UIControl *c = nil;
  UITableViewCell *cell = [table cellForRowAtIndexPath:indexPath];
  if ((c = (UIControl *)[cell viewWithTag:LOGIN_PASSWORD_TAG]) 
      || (c = (UIControl *)[cell viewWithTag:LOGIN_USERNAME_TAG]) 
      && [c canBecomeFirstResponder])
    [c becomeFirstResponder];
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
  NSArray *cells = [self.tableView visibleCells];
  UITableViewCell *nextCell = [cells objectAtIndex:1];
  if (textField.tag == LOGIN_USERNAME_TAG) {
    [[nextCell viewWithTag:LOGIN_PASSWORD_TAG] becomeFirstResponder];
  } else {
    [textField resignFirstResponder];
    [self performLoginWithUsername:
     [(UITextField *)[[cells objectAtIndex:0] 
                      viewWithTag:LOGIN_USERNAME_TAG] text] 
                          password:textField.text];
  }
  return YES;
}

- (void) textFieldDidEndEditing:(UITextField *)textField
{
}

- (void)performLoginWithUsername:(id)username password:(id)password
{  
  YMUserAccount *acct = [YMUserAccount new];
  acct.username = username;
  acct.password = password;
  id url = [[(id)self.refreshHeaderView theTextField] text];
  NSLog(@"url %@", url);
  if (url && ![[url stringByTrimmingCharactersInSet:
                [NSCharacterSet whitespaceCharacterSet]] isEqual:@""]) {
    acct.serviceUrl = url;
  } else url = WS_URL;
  NSLog(@"performLoginWithUsername %@ %@ %@", username, password, url);
  
  // check for dups
  if ([YMUserAccount countByCriteria:@"WHERE username='%@' AND service_url='%@'", username, url]) {
    [(UIAlertView *)[[[UIAlertView alloc]
     initWithTitle:@"Duplicate Account"
     message:[NSString stringWithFormat:@"%@ is already logged in on this device.", username]
     delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] autorelease] show];
    return;
  }
  
  DKDeferred *d = [[self.web loginUserAccount:acct]
                   addCallbacks:callbackTS(self, _cbLoginSucceeded:) 
                   :callbackTS(self, _cbLoginFailed:)];
  
  CFPrettyView *v = [[CFPrettyView alloc] initWithFrame:CGRectZero];
  [v showAsLoadingHUDWithDeferred:d inView:
   [[UIApplication sharedApplication] keyWindow]];
}

- (id)_cbLoginSucceeded:(id)result
{
  if (isDeferred(result))
    return [result addCallbacks:callbackTS(self, _cbLoginSucceeded:) 
                               :callbackTS(self, _cbLoginFailed:)];
  NSLog(@"_cbLoginSucceeded %@", [result loggedIn]);
  return [[self.web networksForUserAccount:result]
          addCallbacks:callbackTS(self, _cbGetNetworksSucceeded:) 
          :callbackTS(self, _cbGetNetworksFailed:)];
}

- (id)_cbLoginFailed:(NSError *)error
{
  [(UIAlertView *)[[[UIAlertView alloc]
     initWithTitle:@"Login Failed"
     message:@"Please check your login credentials and try again."
     delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil]
    autorelease]
   show];
  return error;
}

- (id)_cbGetNetworksSucceeded:(id)result 
{
  NSLog(@"_cbGetNetworksSucceeded: %@", result);
  if (isDeferred(result))
    return [result addCallbacks:callbackTS(self, _cbGetNetworksSucceeded:) 
                               :callbackTS(self, _cbGetNetworksFailed:)];
//  if ([LocalStorage getSetting:@"current_network_id"]) {
//    [self.navigationController popViewControllerAnimated:YES];
//  } else {
//    if ([result isKindOfClass:[NSArray class]] && [result count]) {
//      DKDeferred *d = [DKDeferred deferInThread:
//                       callbackTS([YMLegacyShim sharedShim], 
//                                   _legacyEnterAppWithNetwork:) withObject:[result objectAtIndex:0]];
//      [d addCallback:callbackTS(self, _legacyBootstrapDone:)];
//      
//      CFPrettyView *hud = [[[CFPrettyView alloc] initWithFrame:CGRectZero] autorelease];
//      [hud showAsLoadingHUDWithDeferred:d inView:
//       [[UIApplication sharedApplication] keyWindow]];
//    }
//  }
  [self.navigationController popToRootViewControllerAnimated:YES];
  
  return result;
}

- (id)_cbGetNetworksFailed:(NSError *)error
{
  [(UIAlertView *)[[[UIAlertView alloc]
    initWithTitle:@"Network Error"
    message:@"There was a network error retrieving your networks."
    delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] 
   autorelease] show];
  NSLog(@"_cbGetNetworksFailed: %@ %@", error, [error userInfo]);
  return error;
}

//- (id)_legacyBootstrapDone:(id)r
//{
//  [self.navigationController popToRootViewControllerAnimated:NO];
//  [(id)[[UIApplication sharedApplication] delegate] enterAppWithAccess];
//  return r;
//}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}

- (void)viewDidUnload
{
  self.tableView = nil;
  [super viewDidUnload];
}


- (void)dealloc
{
  [super dealloc];
}


@end
