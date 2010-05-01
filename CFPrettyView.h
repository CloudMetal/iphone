//
//  CFPrettyView.h
//  CraigsFish
//
//  Created by Samuel Sutch on 8/3/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kDefaultStrokeColor         [UIColor colorWithRed:.31764f green:.31764f blue:.31764f alpha:1.0f]
#define kDefaultRectColor           [UIColor colorWithRed:86.0 green:149.0 blue:247.0 alpha:1.0]
#define kDefaultStrokeWidth         2.0
#define kDefaultCornerRadius        10.0

@interface CFPrettyView : UIView {
  UIColor *strokeColor;
  UIColor *rectColor;
  CGFloat strokeWidth;
  CGFloat cornerRadius;
  IBOutlet UIView *contentView;
  BOOL showCloseButton;
  DKDeferred *deferred;
  UIButton *closeButton;
  CGRect originalBounds;
}

@property (nonatomic, retain) UIColor *strokeColor;
@property (nonatomic, retain) UIColor *rectColor;
@property (nonatomic, assign) CGFloat strokeWidth;
@property (nonatomic, assign) CGFloat cornerRadius;
@property (nonatomic, readonly) UIView *contentView;
@property (nonatomic, readwrite, assign) BOOL showCloseButton;

- (DKDeferred *)showInView:(UIView *)view;
- (DKDeferred *)showAsHUDWithDeferred:(DKDeferred *)d subView:(UIView *)subView text:(NSString *)string inView:(UIView *)view;
- (DKDeferred *)showAsLoadingHUDWithDeferred:(DKDeferred *)d inView:(UIView *)view;
- (DKDeferred *)showAsHUDWithDeferred:(DKDeferred *)d inView:(UIView *)view;
- (id)close;
+ (DKDeferred *)flash:(UIView *)view seconds:(NSTimeInterval)seconds flashID:(NSString *)_id;
+ (DKDeferred *)flashText:(NSString *)text lines:(int)lines seconds:(NSTimeInterval)seconds flashID:(NSString *)_id;
+ (DKDeferred *)flashText:(NSString *)text lines:(int)lines seconds:(NSTimeInterval)seconds;
+ (NSMutableDictionary *)_flashes;
+ (void)saveFlashKey:(NSString *)k;

@end

@interface CFPrettyView2 : CFPrettyView
{
}

@end
