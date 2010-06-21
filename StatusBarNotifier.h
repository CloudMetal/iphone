//
//  StatusBarNotifier.h
//  CraigsFish
//
//  Created by Samuel Sutch on 1/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kStatusBarChangedSizeNotification @"StatusBarChangedSizeNotification"

@interface StatusBarNotifier : UIView {
  //  NSMutableArray *flashLines;
  id<MappedPriorityQueue> deferredQueue;
  BOOL isShown;
  BOOL isError;
  UIView *currentLine;
  NSMutableDictionary *queuedViews;
  NSString *errorString;
  CGFloat topOffset;
  UIDeviceOrientation orientation;
}

@property (assign) CGFloat topOffset;
@property (retain) id<MappedPriorityQueue> deferredQueue;
@property (retain) NSMutableDictionary *queuedViews;
@property (assign) BOOL isShown;
@property (assign) BOOL isError;
@property (retain) UIView *currentLine;
@property (copy) NSString *errorString;

+ (id)sharedNotifier;

// displays view where the status bar should go, disappears when
// the returned deferred is called back.
- (void)show;
- (void)setHideTimer:(NSTimeInterval)seconds;
- (void)clearHideTimer;
- (void)hide;

- (DKDeferred *)flashLine:(UIView *)line deferred:(DKDeferred *)d;
//- (DKDeferred *)flashLine:(NSString *)line seconds:(NSTimeInterval)seconds;
//- (DKDeferred *)flashLines:(NSArray *)lines seconds:(NSTimeInterval)seconds;
- (DKDeferred *)flashLoading:(NSString *)text deferred:(DKDeferred *)d;

- (void)_continueFlashing;
- (void)_changingSize;

- (UILabel *)configuredLabel;
- (UIView *)errorView;

@end
