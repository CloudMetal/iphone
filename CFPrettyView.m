//
//  CFPrettyView.m
//  CraigsFish
//
//  Created by Samuel Sutch on 8/3/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "CFPrettyView.h"
#import "UIColor+Extensions.h"
#import "NSString+UUID.h"

@implementation CFPrettyView

@synthesize strokeColor;
@synthesize rectColor;
@synthesize strokeWidth;
@synthesize cornerRadius;
@synthesize contentView;
@synthesize showCloseButton;

#define HUD_ACTIVITY 8838
#define HUD_LABEL 8322
#define HUD_SUBVIEW 8344
#define FLASH_SUBVIEW 8345

static NSMutableDictionary *flashes;
static BOOL openFlash = NO;

+ (NSMutableDictionary *)_flashes {
//  if (!flashes) {
//    NSArray *keys = [[NSUserDefaults standardUserDefaults] objectForKey:@"CFFlashKeys"];
//    flashes = [[[NSMutableDictionary alloc] 
//               initWithObjects:[keys map:functionTS((id)[NSNull class], null)] 
//               forKeys:keys] retain];
//  }
  return flashes;
}

+ (void)saveFlashKey:(NSString *)k {
  NSArray *a = [[NSUserDefaults standardUserDefaults] objectForKey:@"CFFlashKeys"];
  if (!a) a = [NSArray array];
  NSMutableArray *ks = [NSMutableArray arrayWithArray:a];
  [ks addObject:k];
  [[NSUserDefaults standardUserDefaults] setObject:ks forKey:@"CFFlashKeys"];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setShowCloseButton:(BOOL)value {
  if (value != showCloseButton) {
    if (value) {
      if (!closeButton) {
        closeButton = [[UIButton alloc] initWithFrame:CGRectMake(-15., -5., 44., 33.)];
        [closeButton setImage:[UIImage imageNamed:@"close-hud.png"] forState:UIControlStateNormal];
        [closeButton setImage:[UIImage imageNamed:@"close-hud-highlight.png"] forState:UIControlStateHighlighted];
        [closeButton addTarget:self action:@selector(closeHud:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:closeButton];
      }
    }
      
  }
  showCloseButton = value;
}

- (void)closeHud:(id)sender {
  originalBounds = self.bounds;
  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationDuration:.25];
  [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
  [UIView setAnimationDelegate:self];
  [UIView setAnimationDidStopSelector:@selector(doneAnimating:)];
  [self setAlpha:0.0];
  self.bounds = CGRectMake([self superview].center.x, [self superview].center.y, self.bounds.size.width - 90., self.bounds.size.height - 90.);
  [UIView commitAnimations];
  [deferred callback:self];
  [deferred release];
  deferred = nil;
}

- (id)close {
  [self closeHud:nil];
  [deferred release];
  deferred = nil;
  return self;
}

- (void)doneAnimating:(id)arg {
  [self removeFromSuperview];
  [self setAlpha:1.0];
  self.bounds = originalBounds;
}

- (DKDeferred *)showInView:(UIView *)view {
//  if (deferred) {
//    [deferred release];
//    deferred = nil;
//  }
  self.rectColor = [UIColor colorWithWhite:.02 alpha:.7];
  self.strokeColor = [UIColor colorWithWhite:1.0 alpha:.7];
  self.strokeWidth = 5.;
//  deferred = [[DKDeferred deferred] retain];
//  CGRect bounds = self.bounds;
//  self.bounds = CGRectMake(view.center.x, view.center.y, self.bounds.size.width - 90., self.bounds.size.height - 90.);
//  [self setAlpha:0.0];
//  [view addSubview:self];
  self.showCloseButton = YES;
//  [UIView beginAnimations:nil context:nil];
//  [UIView setAnimationDuration:.25];
//  [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
//  [self setAlpha:1.0];
//  self.bounds = bounds;
//  [UIView commitAnimations];
//  return deferred;
//  return[self showAsHUDWithDeferred:[DKDeferred deferred] inView:view];
  if (deferred) {
    [deferred release];
    deferred = nil;
  }
  deferred = [[DKDeferred deferred] retain];
  [deferred addBoth:callbackTS(self, _cbCloseHUD:)];
  //  self.rectColor = [UIColor colorWithWhite:.02 alpha:.8];
  //  self.strokeWidth = 0.0;
  UIView *background = [[UIView alloc] initWithFrame:CGRectZero];
  background.autoresizesSubviews = YES;
//  if (UIDeviceOrientationIsPortrait([[UIDevice currentDevice] orientation])) {
//    background.frame = CGRectMake(0, 0, view.frame.size.height, view.frame.size.width);
//  } else {
    background.frame = CGRectMake(0, 0, view.frame.size.width, view.frame.size.height);
//  }
  [background setUserInteractionEnabled:YES];
  [background setAlpha:0.0];
  [background setBackgroundColor:[UIColor colorWithWhite:.1 alpha:.7]];
  [background setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
  [view addSubview:background];
//  CGRect bounds = self.bounds;
////  self.bounds = CGRectMake(0.0, 0.0, self.bounds.size.width - 90., self.bounds.size.height - 90.);
//  CGPoint c = background.center;
//  self.center = CGPointMake(c.x, c.y-100.);
  self.center = CGPointMake(background.frame.size.width/2., background.frame.size.height/2.);
  [self setAlpha:0.0];
  [background addSubview:self];
  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationDuration:.35];
  [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
  [self setAlpha:1.0];
  [background setAlpha:1.0];
//  self.bounds = bounds;
  [UIView commitAnimations];
  return deferred;
}

+ (DKDeferred *)flashText:(NSString *)text lines:(int)lines seconds:(NSTimeInterval)seconds {
  return [CFPrettyView flashText:text lines:lines seconds:seconds flashID:text];
}

+ (DKDeferred *)flashText:(NSString *)text lines:(int)lines seconds:(NSTimeInterval)seconds flashID:(NSString *)_id {
  UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 35)];
  l.backgroundColor = [UIColor clearColor];
  l.font = [UIFont systemFontOfSize:14];
  l.textColor = [UIColor colorWithWhite:.85 alpha:1];
  l.numberOfLines = lines;
  l.textAlignment = UITextAlignmentCenter;
  l.text = text;
  return [CFPrettyView flash:l seconds:seconds flashID:_id];
}

+ (DKDeferred *)flash:(UIView *)view seconds:(NSTimeInterval)seconds flashID:(NSString *)_id {
  NSMutableDictionary *allFlashes = [CFPrettyView _flashes];
  if (_id && [[allFlashes allKeys] containsObject:_id])
    return [DKDeferred succeed:nil];
  if (!_id) _id = [NSString stringWithUUID];
  DKDeferred *ret = [DKDeferred deferred];
  [allFlashes setObject:[NSMutableArray arrayWithObjects:view, nsnd(seconds), ret, nil] forKey:_id];
  [ret addCallback:callbackTS(self, _cbOpenFlash:)];
  if (!openFlash)
    [ret callback:_id];
  return ret;
}

+ (id)_cbOpenFlash:(NSString *)_id {
  NSMutableDictionary *allFlashes = [CFPrettyView _flashes];
  UIView *view = [[[[allFlashes objectForKey:_id] objectAtIndex:0] retain] autorelease];
  NSTimeInterval seconds = doublev([[allFlashes objectForKey:_id] objectAtIndex:1]);
  if (openFlash) {
    DKDeferred *ret = [[DKDeferred deferred] addCallback:callbackTS(self, _cbOpenFlash:)];
    [[allFlashes objectForKey:_id] replaceObjectAtIndex:2 withObject:ret];
    return ret;
  }
  [allFlashes setObject:[NSNull null] forKey:_id];
  openFlash = YES;
  CGFloat height = view.frame.size.height+20.;
  CGRect _viewFrame = view.frame;
  CFPrettyView *v = [[CFPrettyView alloc] initWithFrame:CGRectMake(320, 10, 340, height+20.)];
  view.frame = CGRectMake(10, 10, v.frame.size.width-70., _viewFrame.size.height);
  view.tag = FLASH_SUBVIEW;
  v.rectColor = [UIColor colorWithWhite:.02 alpha:.7];
  v.strokeColor = [UIColor colorWithWhite:.45 alpha:.7];
  v.strokeWidth = 1;
  v.showCloseButton = NO;
  v.alpha = 0;
  UIView *container = [[UIView alloc] initWithFrame:CGRectMake(10, 431.-(height+25.), 310, height+25.)];
  container.clipsToBounds = YES;
  [v.contentView addSubview:view];
  [container addSubview:v];
  [[[UIApplication sharedApplication] keyWindow] addSubview:container];
  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationDuration:.25];
  [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
  v.alpha = 1;
  v.frame = CGRectMake(10, 10, 340, height+20.);
  [UIView commitAnimations];
  return [[DKDeferred wait:seconds value:_id]
          addCallback:callbackTS(v, _cbCloseFlash:)];
}

- (id)_cbCloseFlash:(NSString *)_id {
  CGRect f = [[self.contentView viewWithTag:FLASH_SUBVIEW] frame];
  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
  [UIView setAnimationDuration:.35];
  [UIView setAnimationDelegate:self];
  [UIView setAnimationDidStopSelector:@selector(doneAnimatingFlashClose:)];
  self.alpha = 0;
  self.frame = CGRectMake(320, 10, 340, f.size.height+20.);
  [UIView commitAnimations];
  NSMutableDictionary *allFlashes = [CFPrettyView _flashes];
  openFlash = NO;
  for (NSString *k in [allFlashes allKeys]) {
    if (!([allFlashes objectForKey:k] == (id)[NSNull null])) {
      [[[allFlashes objectForKey:k] objectAtIndex:2] performSelector:@selector(callback:) withObject:k afterDelay:.35];
    }
  }
  return nil;
}

- (void)doneAnimatingFlashClose:(id)arg {
  [[self superview] removeFromSuperview];
}

- (id)_cbCloseHUD:(id)results {
  if (isDeferred(results))
    return [results addBoth:callbackTS(self, _cbCloseHUD:)];
  originalBounds = self.bounds;
  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
  [UIView setAnimationDuration:.35];
  [UIView setAnimationDelegate:self];
  [UIView setAnimationDidStopSelector:@selector(doneAnimatingHUDClose:)];
  [self setAlpha:0.0];
//  self.bounds = CGRectMake([self superview].center.x, [self superview].center.y, self.bounds.size.width - 90.0f, self.bounds.size.height - 90.0f);
  [[self superview] setAlpha:0.0];
  [UIView commitAnimations];
  return results;
}

- (void)doneAnimatingHUDClose:(id)arg {
  [[self superview] removeFromSuperview];
  [[self superview] setAlpha:1.0];
  [self setAlpha:1.0];
  self.bounds = originalBounds;
}

- (DKDeferred *)showAsLoadingHUDWithDeferred:(DKDeferred *)d inView:(UIView *)view {
//  self.frame = CGRectMake(0.0f, 0.0f, 100.0f, 100.0f);
  UIActivityIndicatorView *v = 
    [[UIActivityIndicatorView alloc]
     initWithActivityIndicatorStyle:
     UIActivityIndicatorViewStyleWhiteLarge];
  v.tag = HUD_ACTIVITY;
  self.frame = CGRectMake(0., 0., 100., 100.);
  [v startAnimating];
  return [self showAsHUDWithDeferred:d subView:v text:@"Loading" inView:view];
}

- (DKDeferred *)showAsHUDWithDeferred:(DKDeferred *)d subView:(UIView *)subView
                                 text:(NSString *)string inView:(UIView *)view {
  [subView setAutoresizingMask:
   UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |
   UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
  subView.center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
  subView.backgroundColor = [UIColor clearColor];
  subView.tag = HUD_SUBVIEW;
  [self addSubview:subView];
  if (string && [string length]) {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.tag = HUD_LABEL;
    label.text = string;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = UITextAlignmentCenter;
    label.font = [UIFont boldSystemFontOfSize:19.0f];
    label.shadowColor = [UIColor colorWithWhite:.1 alpha:1.0];
    label.shadowOffset = CGSizeMake(.0f, -1.0f);
    label.backgroundColor = [UIColor colorWithWhite:.1 alpha:.8];
    [label.layer setCornerRadius:5.0f];
    [label sizeToFit];
    label.center = CGPointMake(subView.center.x, subView.center.y + 60.0f);
    [label setAutoresizingMask:
     UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |
     UIViewAutoresizingFlexibleWidth];
    [self addSubview:label];
  }
  return [self showAsHUDWithDeferred:d inView:view];
}

- (DKDeferred *)showAsHUDWithDeferred:(DKDeferred *)d inView:(UIView *)view {
  if (deferred) {
    [deferred release];
    deferred = nil;
  }
  deferred = [d retain];
  [deferred addBoth:callbackTS(self, _cbCloseHUD:)];
  self.rectColor = [UIColor colorWithWhite:.02 alpha:.8];
  self.strokeWidth = 0.0;
  UIImageView *background = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hud-overlay.png"]];
  background.autoresizesSubviews = YES;
  if (UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation])) {
    background.frame = CGRectMake(0, 0, view.frame.size.height, view.frame.size.width);
  } else {
    background.frame = CGRectMake(0, 0, view.frame.size.width, view.frame.size.height);
  }
  [background setUserInteractionEnabled:YES];
  [background setAlpha:0.0];
  [background setBackgroundColor:[UIColor clearColor]];
  [background setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
  [view addSubview:background];
  CGRect bounds = self.bounds;
  self.bounds = CGRectMake(0.0, 0.0, self.bounds.size.width - 90., self.bounds.size.height - 90.);
  self.center = background.center;
  [self setAlpha:0.0];
  self.showCloseButton = NO;
  [background addSubview:self];
  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationDuration:.35];
  [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
  [self setAlpha:1.0];
  [background setAlpha:1.0];
  self.bounds = bounds;
  [UIView commitAnimations];
  return d;
}

- (id)initWithCoder:(NSCoder *)decoder
{
  if (self = [super initWithCoder:decoder])
  {
    self.strokeColor = [UIColor blackColor]; //kDefaultStrokeColor;
    self.backgroundColor = [UIColor clearColor];
    self.strokeWidth = kDefaultStrokeWidth;
    self.rectColor = [UIColor colorWithHexString:@"313131"]; //kDefaultRectColor;
    self.cornerRadius = kDefaultCornerRadius;
    self.clipsToBounds = NO;
    contentView = [[[UIView alloc] initWithFrame:
      CGRectMake(CGRectGetMinX(self.bounds) + 10., 
                 CGRectGetMinY(self.bounds) + 10.,
                 CGRectGetWidth(self.bounds) - 20., 
                 CGRectGetHeight(self.bounds) - 20.)] retain];
    [self sendSubviewToBack:contentView];
    [self addSubview:contentView];
    [contentView setBackgroundColor:[UIColor clearColor]];
  }
  return self;
}

- (id)initWithFrame:(CGRect)frame 
{
  if (self = [super initWithFrame:frame]) 
  {
    self.strokeColor = [UIColor blackColor]; //kDefaultStrokeColor;
    self.backgroundColor = [UIColor clearColor];
    self.strokeWidth = kDefaultStrokeWidth;
    self.rectColor = [UIColor colorWithHexString:@"313131"]; //kDefaultRectColor;
    self.cornerRadius = kDefaultCornerRadius;
    self.clipsToBounds = NO;
    contentView = [[[UIView alloc] initWithFrame:
                    CGRectMake(CGRectGetMinX(self.bounds) + 10., 
                               CGRectGetMinY(self.bounds) + 10.,
                               CGRectGetWidth(self.bounds) - 20., 
                               CGRectGetHeight(self.bounds) - 20.)] retain];
    [self addSubview:contentView];
    [self sendSubviewToBack:contentView];
    [contentView setBackgroundColor:[UIColor clearColor]];
  }
  return self;
}

- (void)setBounds:(CGRect)newBounds {
  CGFloat diffx = CGRectGetWidth(newBounds) - CGRectGetWidth(self.bounds);
  CGFloat diffy = CGRectGetHeight(newBounds) - CGRectGetHeight(self.bounds);
  contentView.bounds = 
    CGRectMake(contentView.bounds.origin.x, 
               contentView.bounds.origin.y, 
               contentView.bounds.size.width + diffx, 
               contentView.bounds.size.height + diffy);
  [super setBounds:newBounds];
}

- (void)setFrame:(CGRect)newFrame {
  CGFloat diffx = CGRectGetWidth(newFrame) - CGRectGetWidth(self.frame);
  CGFloat diffy = CGRectGetHeight(newFrame) - CGRectGetHeight(self.frame);
  contentView.frame = 
    CGRectMake(contentView.frame.origin.x, 
               contentView.frame.origin.y, 
               contentView.frame.size.width + diffx, 
               contentView.frame.size.height + diffy);
  [super setFrame:newFrame];
}

//- (void)setBackgroundColor:(UIColor *)newBGColor
//{
//  // Ignore any attempt to set background color - backgroundColor must stay set to clearColor
//  // We could throw an exception here, but that would cause problems with IB, since backgroundColor
//  // is a palletized property, IB will attempt to set backgroundColor for any view that is loaded
//  // from a nib, so instead, we just quietly ignore this.
//  //
//  // Alternatively, we could put an NSLog statement here to tell the programmer to set rectColor...
//}

//- (void)setOpaque:(BOOL)newIsOpaque
//{
//  // Ignore attempt to set opaque to YES.
//}

- (void)drawRect:(CGRect)rect {
//  NSLog(@"drawRect:%i", [self tag]);
  [self sendSubviewToBack:contentView];
  CGContextRef context = UIGraphicsGetCurrentContext();
  
  CGContextSaveGState(context);
  CGContextSetShadowWithColor(context, CGSizeMake(0., 0.), 10., [UIColor blackColor].CGColor);
//  CGContextSetShadow(context, CGSizeMake(0., 0.), 20.0f);
  
//  [super drawRect:rect];
  CGContextSetLineWidth(context, strokeWidth);
  CGContextSetStrokeColorWithColor(context, self.strokeColor.CGColor);
  CGContextSetFillColorWithColor(context, self.rectColor.CGColor);
  
//  CGContextFillRect(context, CGRectMake(self.frame.origin.x + 10., self.frame.origin.y + 10., self.frame.size.width - 20., self.frame.size.height - 20.));
  
  CGRect rrect = CGRectMake(self.bounds.origin.x + 10., self.bounds.origin.y + 10., self.bounds.size.width - 20., self.bounds.size.height - 20.);
//  CGRect rrect = CGRectMake(rsrect.origin.x, rsrect.origin.y, rsrect.size.width + 40.0f, rsrect.size.height + 40.0f);
  
  
  CGFloat radius = cornerRadius;
  CGFloat width = CGRectGetWidth(rrect);
  CGFloat height = CGRectGetHeight(rrect);
  
  
  // Make sure corner radius isn't larger than half the shorter side
  if (radius > width/2.0)
    radius = width/2.0;
  if (radius > height/2.0)
    radius = height/2.0;    
//  
  CGFloat minx = CGRectGetMinX(rrect);
  CGFloat midx = CGRectGetMidX(rrect);
  CGFloat maxx = CGRectGetMaxX(rrect);
  CGFloat miny = CGRectGetMinY(rrect);
  CGFloat midy = CGRectGetMidY(rrect);
  CGFloat maxy = CGRectGetMaxY(rrect);
  CGContextMoveToPoint(context, minx, midy);
  CGContextAddArcToPoint(context, minx, miny, midx, miny, radius);
  CGContextAddArcToPoint(context, maxx, miny, maxx, midy, radius);
  CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, radius);
  CGContextAddArcToPoint(context, minx, maxy, minx, midy, radius);
  CGContextClosePath(context);
  CGContextDrawPath(context, kCGPathFillStroke);
  
  CGContextRestoreGState(context);
  
}

- (void)dealloc {
  [deferred release];
  [strokeColor release];
  [rectColor release];
  [contentView release];
  [super dealloc];
}

@end


@implementation CFPrettyView2

//- (void)drawRect:(CGRect)rect {
////  CGContextRef currentContext = UIGraphicsGetCurrentContext();
////  CGContextSaveGState(currentContext);
////  CGContextSetShadow(currentContext, CGSizeMake(-15, 20), 5);
//  [super drawRect:rect];
////  CGContextRestoreGState(currentContext);
//}

@end

