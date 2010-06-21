//
//  CommunityActivityController.h
//  Netsketch
//
//  Created by Ben Gotow on 8/15/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DrillDownPage.h"

#define kNavigationForward      1
#define kNavigationBackward     -1

@interface DrillDownWebController : UIViewController <UINavigationBarDelegate, UIWebViewDelegate, DrillDownPageContainer>{

    UIImageView *               splashView;
    UIImage *                   splashImage;
    
    UIView *                    webViewContainer;
    CGRect                      webViewFrame;
    NSString *                  webRoot;
    
    UIActivityIndicatorView *   navigationActivity;
    UINavigationBar *           navigationBar;
    int                         navigationDirection;
    
    BOOL                        animatingBakward;
    BOOL                        leaving;
    
    NSMutableArray *            pageStack;
    DrillDownPage *             pendingPage;
}

@property (nonatomic, retain) UIView * webViewContainer;
@property (nonatomic, retain) NSString * webRoot;
@property (nonatomic, retain) UIImage * splashImage;

- (id)initWithWebRoot:(NSString*)url andTitle: (NSString*)t andSplashImage: (UIImage*)img;
- (void)loadView;
- (void)viewDidAppear:(BOOL)animated;
- (void)leave;
- (void)swapToCustomNavBar;
- (void)swapToParentNavBar;
- (void)dealloc;
- (void)didReceiveMemoryWarning;

#pragma mark DrillDownPage Delegate Functions

- (void)createNewPageForRequest:(NSURLRequest*)request;
- (void)handleNonHTTPRequest:(NSURLRequest*)request;
- (void)pageLoadStarted;
- (void)pageLoadSucceeded;
- (void)pageLoadCancelled;
- (void)pageLoadFailed;

#pragma mark Navigation Bar Delegate Functions

- (void)navigationCustomAction;
- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item;
- (void)navigationBackwardsComplete;
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;

@end
