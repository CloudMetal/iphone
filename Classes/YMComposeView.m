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

@synthesize messageTextView, toLabel, toTargetLabel,
            onUserInputsHash, onUserInputsAt, onPartialWillClose;

- (void) textViewDidChange:(UITextView *)textView
{
  NSString *s = [textView.text stringByMatching:@"((@|#)[a-zA-Z0-9]*)$" options:
                 RKLDotAll | RKLMultiline | RKLUnicodeWordBoundaries inRange:
                 NSMakeRange(0, textView.text.length) capture:1 error:nil];
  
  if (!s && messageTextView.onPartial) {
    if (self.onPartialWillClose) [self.onPartialWillClose :textView];
    [messageTextView hidePartials:nil];
  }
  if (!s) return;
  
  if ([s hasPrefix:@"#"] && self.onUserInputsHash 
      && messageTextView.autocompleteEnabled)
    [self.onUserInputsHash :s];
  else if ([s hasPrefix:@"@"] && self.onUserInputsAt 
           && messageTextView.autocompleteEnabled)
    [self.onUserInputsAt :s];
}

- (void)performAutocomplete:(NSString *)str isAppending:(BOOL)appending
{
  if (appending) {
    BOOL lastIsWhitespace = [messageTextView.text hasSuffix:@" "];
    messageTextView.text = [messageTextView.text stringByAppendingFormat:@"%@%@ ", 
                            (lastIsWhitespace ? @"" : @" "), str];
  } else {
    messageTextView.text = [messageTextView.text stringByReplacingOccurrencesOfRegex:
                            @"(@|#)[a-zA-Z0-9]*$" withString:
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
