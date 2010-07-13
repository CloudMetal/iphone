//
//  YMMessageTextView.m
//  Yammer
//
//  Created by Samuel Sutch on 5/20/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "YMMessageTextView.h"


static UIButton *kbButton   = nil;
static UIButton *hashButton = nil;
static UIButton *atButton   = nil;
static UIView *toolbarView  = nil;

@interface YMMessageTextView (PrivateParts)

- (void)privateInit;

@end


@implementation YMMessageTextView

@synthesize userTableView, hashTableView, userDataSource, hashDataSource,
            autocompleteEnabled, onPartial;

+ (void)initialize
{
  if (self == [YMMessageTextView class]) {
    if (!kbButton) kbButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    if (!hashButton) hashButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    if (!atButton) atButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    
    kbButton.frame = CGRectMake(160, 0, 50, 37);
    atButton.frame = CGRectMake(214, 0, 50, 37);
    hashButton.frame = CGRectMake(266, 0, 50, 37);
    [kbButton setImage:[UIImage imageNamed:@"kb-tab-keyboard.png"] 
              forState:UIControlStateNormal];
    [hashButton setImage:[UIImage imageNamed:@"kb-tab-hash.png"]
                forState:UIControlStateNormal];
    [atButton setImage:[UIImage imageNamed:@"kb-tab-at.png"] 
              forState:UIControlStateNormal];
//    atButton.hidden = YES;
//    hashButton.hidden = YES;
//    kbButton.hidden = YES;
    
    if (!toolbarView) toolbarView = [[[UIView alloc] initWithFrame:
                                      CGRectMake(0, 0, 320, 37)] retain];
    toolbarView.backgroundColor = [UIColor clearColor];
    toolbarView.opaque = NO;
    [toolbarView addSubview:kbButton];
    [toolbarView addSubview:atButton];
    [toolbarView addSubview:hashButton];
  }
}

- (id)initWithFrame:(CGRect)rect
{
  if ((self = [super initWithFrame:rect]))
    [self privateInit];
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
  if ((self = [super initWithCoder:aDecoder]))
    [self privateInit];
  return self;
}

- (void)privateInit
{
  autocompleteEnabled = YES;
  onHash = NO;
  onAt = NO;
  hashButtonCenter = CGPointZero;
  atButtonCenter = CGPointZero;
  kbButtonCenter = CGPointZero;
//  [[NSNotificationCenter defaultCenter] 
//   addObserver:self selector:@selector(keyboardWillShow:) 
//   name:UIKeyboardWillShowNotification object:nil];
//  [[NSNotificationCenter defaultCenter]
//   addObserver:self selector:@selector(keyboardWillHide:) 
//   name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)note
{
  NSMutableArray *keyboards = [NSMutableArray array];

  for (UIView *kbWinder in [[UIApplication sharedApplication] windows]) {
    for (UIView *kb in [kbWinder subviews]) {
      if ([[kb description] hasPrefix:@"<UIKeyboard"] == YES 
          || [[kb description] hasPrefix:@"<UIPeripheralHostView"] == YES) {
        CGRect r = [[[note userInfo] valueForKey:
                     UIKeyboardBoundsUserInfoKey] CGRectValue];
        CGPoint c = [[[note userInfo] valueForKey:
                      UIKeyboardCenterEndUserInfoKey] CGPointValue];
        CGPoint c1 = [[[note userInfo] valueForKey:
                       UIKeyboardCenterBeginUserInfoKey] CGPointValue];
        toolbarView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        toolbarView.center = CGPointMake(c1.x, c1.y-(r.size.height/2.0)-(37.0/2.0));
        [kbWinder addSubview:toolbarView];
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:[[[note userInfo] valueForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
        [UIView setAnimationCurve:[[[note userInfo] valueForKey:UIKeyboardAnimationCurveUserInfoKey] intValue]];
        toolbarView.center = CGPointMake(c.x, c.y-(r.size.height/2.0)-(37.0/2.0));
        [UIView commitAnimations];
        
        keyboardContainer = kb;
        keyboardRect = r;
        kbWindow = (UIWindow *)kbWinder;
        for (UIView *sub in [kb subviews]) {
          if ([[sub description] hasPrefix:@"<UIKeyboardImpl"] == YES) {
            [keyboards addObject:sub];
          }
        }
      }
    }
  }
  
  toolbarView.clipsToBounds = NO;
  if (keyboardViews) [keyboardViews release];
  keyboardViews = [keyboards retain];
  [atButton addTarget:self action:@selector(doAt:)
     forControlEvents:UIControlEventTouchUpInside];
  [hashButton addTarget:self action:@selector(doHash:) 
       forControlEvents:UIControlEventTouchUpInside];
  [kbButton addTarget:self action:@selector(doKeyboard:) 
     forControlEvents:UIControlEventTouchUpInside];
}

- (void)revealPartialAt:(id)sender
{
  if (onAt || onHash || !autocompleteEnabled) return;
  if (onPartial) return [userTableView reloadData];
  
  onPartial = YES;
  atButtonCenter = atButton.center;
  
  userTableView.frame = CGRectMake(0, 0, keyboardRect.size.width, 100);
  userTableView.center =  keyboardContainer.center;
  userTableView.dataSource = userDataSource;
  userTableView.delegate = userDataSource;
  userTableView.alpha = 0;
  
  [userTableView reloadData];
  [kbWindow addSubview:userTableView];
  [kbWindow sendSubviewToBack:userTableView];
  [atButton setHighlighted:YES];
  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationDuration:.35];
  userTableView.center = CGPointMake(userTableView.center.x, userTableView.center.y-(keyboardRect.size.height/2.0)-50.0);
  userTableView.alpha = 1.0;
  atButton.center = CGPointMake(atButtonCenter.x, atButtonCenter.y - 100.0);
  [UIView commitAnimations];
}

- (void)hidePartials:(id)sender
{
  if (!onPartial) return;
  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationDuration:.35];
  if (!CGPointEqualToPoint(atButtonCenter, CGPointZero)) 
    atButton.center = atButtonCenter;
  if (!CGPointEqualToPoint(kbButtonCenter, CGPointZero)) 
    kbButton.center = kbButtonCenter;
  if (!CGPointEqualToPoint(hashButtonCenter, CGPointZero)) 
    hashButton.center = hashButtonCenter;
  
  userTableView.alpha = 0;
  hashTableView.alpha = 0;
  [UIView commitAnimations];
  
  onPartial = NO;
  atButtonCenter = hashButtonCenter = kbButtonCenter = CGPointZero;
  [atButton setHighlighted:NO];
  [kbButton setHighlighted:NO];
  [hashButton setHighlighted:NO];
}

- (void)revealPartialHash:(id)sender
{
  if (onAt || onHash || !autocompleteEnabled) return;
  if (onPartial) return [hashTableView reloadData];
  
  onPartial = YES;
  hashButtonCenter = hashButton.center;
  
  hashTableView.frame = CGRectMake(0, 0, keyboardRect.size.width, 100);
  hashTableView.center = keyboardContainer.center;
  hashTableView.dataSource = hashDataSource;
  hashTableView.delegate = hashDataSource;
  hashTableView.alpha = 0;
  
  [hashTableView reloadData];
  [kbWindow addSubview:hashTableView];
  [kbWindow sendSubviewToBack:hashTableView];
  [hashButton setHighlighted:YES];
  
  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationDuration:.35];
  hashTableView.center = CGPointMake(hashTableView.center.x, hashTableView.center.y - (keyboardRect.size.height/2.0)-50.0);
  hashTableView.alpha = 1;
  hashButton.center = CGPointMake(hashButtonCenter.x, hashButtonCenter.y - 100.0);
  [UIView commitAnimations];
}

- (void)doKeyboard:(id)sender
{
  if (onHash || onAt) {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:.35];
    keyboardContainer.alpha = 1;
    [UIView commitAnimations];
    [userTableView removeFromSuperview];
    [hashTableView removeFromSuperview];
    onHash = NO;
    onAt = NO;
    autocompleteEnabled = YES;
  }
}

- (void)doHash:(id)sender
{
  if (onHash) return;
  onHash = YES;
  autocompleteEnabled = NO;
  hashTableView.frame = CGRectMake(0, 37, keyboardRect.size.width, keyboardRect.size.height);
  hashTableView.dataSource = hashDataSource;
  hashTableView.delegate = hashDataSource;
  hashTableView.alpha = 0;
  [hashTableView reloadData];
  [userTableView removeFromSuperview];
  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationDuration:.35];
  [keyboardContainer addSubview:hashTableView];
  [keyboardContainer sendSubviewToBack:hashTableView];
  keyboardContainer.alpha = 0;
  hashTableView.alpha = 1;
  [UIView commitAnimations];
}

- (void)doAt:(id)sender
{
  if (onAt) return;
  onAt = YES;
  autocompleteEnabled = NO;
  userTableView.frame = CGRectMake(0, 0, keyboardRect.size.width, keyboardRect.size.height);
  userTableView.center = keyboardContainer.center;
  userTableView.dataSource = userDataSource;
  userTableView.delegate = userDataSource;
  userTableView.alpha = 0;
  [userTableView reloadData];
  [kbWindow addSubview:userTableView];
  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationDuration:.35];
  [hashTableView removeFromSuperview];
  keyboardContainer.alpha = 0;
  userTableView.alpha = 1;
  [UIView commitAnimations];
}

- (void)keyboardWillHide:(NSNotification *)note
{
  if (onPartial) [self hidePartials:nil];
  
  autocompleteEnabled = YES;
  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationDuration:.35];
  [toolbarView removeFromSuperview];
  [userTableView removeFromSuperview];
  [hashTableView removeFromSuperview];
  for (UIView *kb in keyboardViews) {
    kb.alpha = 1;
  }
  [UIView commitAnimations];
  [hashButton removeTarget:self action:@selector(doHash:) 
          forControlEvents:UIControlEventTouchUpInside];
  [atButton removeTarget:self action:@selector(doAt:)
        forControlEvents:UIControlEventTouchUpInside];
  [kbButton removeTarget:self action:@selector(doKeyboard:) 
        forControlEvents:UIControlEventTouchUpInside];
}


- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] 
   removeObserver:self name:UIKeyboardWillHideNotification object:nil];
  [[NSNotificationCenter defaultCenter] 
   removeObserver:self name:UIKeyboardWillShowNotification object:nil];
  [super dealloc];
}


@end
