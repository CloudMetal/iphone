//
//  YMComposeView.m
//  Yammer
//
//  Created by Samuel Sutch on 5/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "YMComposeView.h"
#import "YMMessageTextView.h"

@implementation YMComposeView

@synthesize messageTextView, toLabel, toTargetLabel, activity, onPhoto, onUserPhoto,
onUserInputsHash, onUserInputsAt, onPartialWillClose, actionBar, tableView, onHash, onUser, onPartial, interfaceOrientation;

//- (id)initWithCoder:(NSCoder *)aDecoder
//{
//  if ((self = [super initWithCoder:aDecoder])) {
//    [cancel setBackgroundImage:[[UIImage imageNamed:@"toolbarbutton.png"] stretchableImageWithLeftCapWidth:7 topCapHeight:7] forState:UIControlStateNormal];
//    [send setBackgroundImage:[[UIImage imageNamed:@"toolbarbutton.png"] stretchableImageWithLeftCapWidth:7 topCapHeight:7] forState:UIControlStateNormal];
//    CGRect f = actionBar.frame;
//    f.size.height = 27;
//    actionBar.frame = f;
//  }
//  return self;
//}

//-(void) send:(id)s
//{
//}
//
//-(void) cancel:(id)s
//{
//}

-(void) kb:(id)s
{
  onUser = onPhoto = onHash = NO;
  [self.messageTextView becomeFirstResponder];
}

-(void) photo:(id)s
{
  onPhoto = YES;
  onUser = onHash = onPartial = NO;
  if (self.onUserPhoto) [self.onUserPhoto :nil];
}

-(void) at:(id)s
{
  onUser = YES;
  onHash = onPhoto = onPartial = NO;
  [self.messageTextView resignFirstResponder];
  [self.onUserInputsAt :@"@"];
}

-(void) hash:(id)s
{
  onHash = YES;
  onUser = onPhoto = onPartial = NO;
  [self.messageTextView resignFirstResponder];
  [self.onUserInputsHash :@"#"];
}

- (void) textViewDidChange:(UITextView *)textView
{
  NSString *s = [textView.text stringByMatching:@"((@|#)[a-zA-Z0-9-]+)$" options:
                 RKLDotAll | RKLMultiline | RKLUnicodeWordBoundaries inRange:
                 NSMakeRange(0, textView.text.length) capture:1 error:nil];
  
  if (!s && onPartial) {
    if (self.onPartialWillClose) [self.onPartialWillClose :textView];
    //[messageTextView hidePartials:nil];
  }
  if (!s) return;
  //UIDeviceOrientation o = [[UIDevice currentDevice] orientation];
  if (!s) { // || (o == UIDeviceOrientationLandscapeLeft || o == UIDeviceOrientationLandscapeRight)) {
    if (self.onPartialWillClose) [self.onPartialWillClose :textView];
    return;
  }
  
  if ([s hasPrefix:@"#"] && self.onUserInputsHash 
      && messageTextView.autocompleteEnabled) {
    onHash = onPartial = YES;
    onUser = onPhoto = NO;
    [self.onUserInputsHash :s];
  } else if ([s hasPrefix:@"@"] && self.onUserInputsAt 
             && messageTextView.autocompleteEnabled) {
    onUser = onPartial = YES;
    onHash = onPhoto = NO;
    [self.onUserInputsAt :s];
  }
}

- (void)revealPartial
{
  onPartial = YES;
  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationDuration:.25];
  if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
    messageTextView.frame = CGRectMake(0, 20, 320, 87);
    tableView.frame = CGRectMake(0, 107, 320, 93);
  } else {
    messageTextView.frame = CGRectMake(0, 5, 480, 45);
    tableView.frame = CGRectMake(0, 60, 480, 48);
    toLabel.alpha = 0;
    toTargetLabel.alpha = 0;
  }
  actionBar.alpha = 0;
  [UIView commitAnimations];
}

- (void)hidePartial
{
  onPartial = onPhoto = onHash = onUser = NO;
  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationDuration:.25];
  if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
    messageTextView.frame = CGRectMake(0, 20, 320, 153);
    tableView.frame = CGRectMake(0, 200, 320, 216);
  } else {
    tableView.frame = CGRectMake(0, 106, 480, 162);
    messageTextView.frame = CGRectMake(0, 20, 480, 100);
  }
  toTargetLabel.alpha = 1;
  toLabel.alpha = 1;
  actionBar.alpha = 1;
  [UIView commitAnimations];
}

- (void)performAutocomplete:(NSString *)str isAppending:(BOOL)appending
{
  NSLog(@"autocomplete %i %@", appending, str);
  if (appending) {
    BOOL lastIsWhitespace = [messageTextView.text hasSuffix:@" "];
    messageTextView.text = [messageTextView.text stringByAppendingFormat:@"%@%@ ", 
                            (lastIsWhitespace ? @"" : @" "), str];
  } else {
    messageTextView.text = [messageTextView.text stringByReplacingOccurrencesOfRegex:
                            @"(@|#)[a-zA-Z0-9-]*$" withString:
                            [str stringByAppendingString:@" "]];
  }
}

- (void)dealloc
{
  self.onUserInputsAt = nil;
  self.onUserInputsHash = nil;
  [super dealloc];
}


@end
