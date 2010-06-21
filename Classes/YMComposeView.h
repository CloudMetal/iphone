//
//  YMComposeView.h
//  Yammer
//
//  Created by Samuel Sutch on 5/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class YMMessageTextView;

@interface YMComposeView : UIView <UITextViewDelegate> {
  IBOutlet YMMessageTextView *messageTextView;
  IBOutlet UILabel *toLabel;
  IBOutlet UILabel *toTargetLabel;
  id<DKCallback> onUserInputsHash, onUserInputsAt, onPartialWillClose;
}

@property(nonatomic, readwrite, retain) id<DKCallback> onUserInputsHash, onUserInputsAt, onPartialWillClose;
@property(nonatomic, readwrite, retain) YMMessageTextView *messageTextView;
@property(nonatomic, readwrite, retain) UILabel *toLabel, *toTargetLabel;

- (void)performAutocomplete:(NSString *)str isAppending:(BOOL)appending;

@end
