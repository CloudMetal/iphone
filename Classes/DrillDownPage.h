//
//  Page.h
//  Netsketch
//
//  Created by Ben Gotow on 10/28/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DrillDownWebController;

@protocol DrillDownPageContainer
    @property (nonatomic, retain) UIView * webViewContainer;
    - (void)createNewPageForRequest:(NSURLRequest*)request;
    - (void)handleNonHTTPRequest:(NSURLRequest*)request;
    - (void)pageLoadStarted;
    - (void)pageLoadSucceeded;
    - (void)pageLoadCancelled;
    - (void)pageLoadFailed;
@end

@interface DrillDownPage : NSObject <UIWebViewDelegate>{
    NSURLRequest                * request;
    
    UIWebView                   * webView;
    UIImageView                 * webImageView;
    BOOL                          webViewUnlinked;
    
    id<DrillDownPageContainer>    container;
    
    NSTimer                     * navigationTimeoutTimer;
    NSTimer                     * didLoadTimer;
    
    int                           depth;
}

@property (nonatomic, retain) NSURLRequest * request;
@property (nonatomic, retain) id<DrillDownPageContainer> container;


+ (DrillDownPage*)pageWithRequest:(NSURLRequest*)r andContainer:(id<DrillDownPageContainer>)c;
- (id)initWithRequest:(NSURLRequest*)r andContainer:(id<DrillDownPageContainer>)c;

- (void)createWebView;
- (void)loadWebView;
- (NSString*)executeJavascript:(NSString*)javascript;
- (void)unlink;
- (void)unlinkComplete;
- (void)dealloc;
- (UIImage*)takeImage;
- (NSString*)title;
- (NSString*)actionText;
- (NSString*)actionURL;
- (void)setUserInteractionEnabled:(BOOL)enabled;

#pragma mark Page Animation

- (void)depthChanged:(NSNumber*)change;
- (void)slideIn:(int)direction;
- (void)slideOut:(int)direction;
- (BOOL)webView:(UIWebView *)w shouldStartLoadWithRequest:(NSURLRequest *)r navigationType:(UIWebViewNavigationType)navigationType;
- (void)webViewDidFinishLoad:(UIWebView *)w;
- (void)webViewDidFinalizeLoad;
- (void)webView:(UIWebView *)w didFailLoadWithError:(NSError *)error;
@end
