//
//  Page.m
//  Netsketch
//
//  Created by Ben Gotow on 10/28/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "DrillDownPage.h"
#import "DrillDownWebController.h"
#import <QuartzCore/QuartzCore.h>

// number of seconds to wait before displaying connection lost
#define kNavigationTimeout 15.0

// the number of webiews to keep in the view stack before replacing
// them with static images.
#define kMaxWebViews       5

@implementation DrillDownPage

@synthesize request;
@synthesize container;

+ (DrillDownPage*)pageWithRequest:(NSURLRequest*)r andContainer:(id<DrillDownPageContainer>)c
{
    DrillDownPage * p = [[DrillDownPage alloc] initWithRequest:r andContainer:c];
    return [p autorelease];
}

- (id)initWithRequest:(NSURLRequest*)r andContainer:(id<DrillDownPageContainer>)c
{
    if (self = [super init]){
        self.request = r;
        self.container = c;
        
        [self createWebView];
        [self loadWebView];
        
        depth = 0;
        
        webImageView = [[UIImageView alloc] initWithFrame: container.webViewContainer.bounds];
        [webImageView setHidden: YES];
        [container.webViewContainer addSubview: webImageView];
        [container.webViewContainer sendSubviewToBack: webImageView];
    }
    return self;
}

- (void)createWebView
{
    webView = [[UIWebView alloc] initWithFrame: container.webViewContainer.bounds];
    webView.scalesPageToFit = YES;
    //webView.detectsPhoneNumbers = NO;
    webView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    webView.delegate = self;
    webView.userInteractionEnabled = NO;
    webViewUnlinked = NO;
    
    [container.webViewContainer addSubview: webView];
    [container.webViewContainer sendSubviewToBack: webView];
}

- (void)loadWebView
{
    [webView loadRequest: request];
    
    // create a timer that we'll fire if the page doesn't load properly
    //[navigationTimeoutTimer invalidate];
    //[navigationTimeoutTimer release];
    //navigationTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:15.0 target:self selector:@selector(webViewTimeout) userInfo:nil repeats:NO];
    //[navigationTimeoutTimer retain];
}

- (NSString*)executeJavascript:(NSString*)javascript
{
    return [webView stringByEvaluatingJavaScriptFromString: javascript];
}

- (void)unlink
{
    // tell it we want to ignore any further delegate calls from the webView
    webViewUnlinked = YES;
    if (![webView isLoading])
        [self unlinkComplete];
        
    [container pageLoadCancelled];
    [webImageView removeFromSuperview];
    [webView removeFromSuperview];
}

- (void)unlinkComplete
{
    [self setContainer: nil];
}

- (void)dealloc
{
    [webView release];
    [webImageView release];
    [request release];
    
    //[navigationTimeoutTimer invalidate];
    //[navigationTimeoutTimer release];
    //navigationTimeoutTimer = nil;
    
    [didLoadTimer invalidate];
    [didLoadTimer release];
    didLoadTimer = nil;
    
    [super dealloc];
}

- (UIImage*)takeImage
{
    UIGraphicsBeginImageContext(webView.bounds.size);
    [webView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

- (NSString*)title
{
    return [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
}

- (NSString*)actionText
{
    return [webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('action_text').name"];
}

- (NSString*)actionURL
{
    return [webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('action_url').name"];
}

- (void)setUserInteractionEnabled:(BOOL)enabled
{
    [webImageView setHidden: enabled];
    webView.userInteractionEnabled = enabled;
}

#pragma mark Page Animation

- (void)depthChanged:(NSNumber*)change;
{
    depth += [change intValue];
    //NSLog(@"my depth is %d", depth);
    
    if (depth == 0){
        if (webView == nil){
            [self createWebView];
            [self loadWebView];
        }
        webView.userInteractionEnabled = YES;
        
    } else if (depth > kMaxWebViews - 1){
        webViewUnlinked = YES;
        [webView removeFromSuperview];
        [webView stopLoading];
        [webView release];
        webView = nil;
    }
} 

- (void)slideIn:(int)direction
{
    CGRect end = container.webViewContainer.bounds;
    CGRect start = container.webViewContainer.bounds;
    start.origin.x += start.size.width * direction;
    
    [UIView setAnimationsEnabled: NO];
    [webView setFrame: start];
    [webImageView setFrame: start];
    [UIView setAnimationsEnabled: YES];
    [webView setFrame: end];
    [webImageView setFrame: end];
}

- (void)slideOut:(int)direction
{
    CGRect start = container.webViewContainer.bounds;
    CGRect end = container.webViewContainer.bounds;
    end.origin.x -= end.size.width * direction;
    
    [UIView setAnimationsEnabled: NO];
    [webView setFrame: start];
    [webImageView setFrame: start];
    [UIView setAnimationsEnabled: YES];
    [webView setFrame: end];
    [webImageView setFrame: end];
}

- (BOOL)webView:(UIWebView *)w shouldStartLoadWithRequest:(NSURLRequest *)r navigationType:(UIWebViewNavigationType)navigationType
{
    if (webViewUnlinked){
        return YES;
    }
    
    if (![[[[r URL] absoluteString] substringToIndex:4] isEqualToString:@"http"]){
        [container handleNonHTTPRequest: r];
        return NO;
    }
    
    [self setUserInteractionEnabled:NO];
    
    // if the user wants to go to a completely new page, we add the current page
    // to the path stack and then silently load the new page.
    if ((navigationType == UIWebViewNavigationTypeLinkClicked) || (navigationType == UIWebViewNavigationTypeBackForward))
    {
        [container createNewPageForRequest: r];
        return NO;
    }
    else 
    {
        self.request = r;
        [container pageLoadStarted];
       return YES;
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)w
{
    if (webViewUnlinked){
        [self unlinkComplete];
        return;
    }
        
    //[navigationTimeoutTimer invalidate];
    //[navigationTimeoutTimer release];
    //navigationTimeoutTimer = nil;
    
    [didLoadTimer invalidate];
    [didLoadTimer release];
    didLoadTimer = [NSTimer scheduledTimerWithTimeInterval: 0.4 target:self selector:@selector(webViewDidFinalizeLoad) userInfo:nil repeats:NO];
    [didLoadTimer retain];
}

- (void)webViewDidFinalizeLoad
{
    [webImageView setImage: [self takeImage]];
    [self setUserInteractionEnabled: YES];
    
    [didLoadTimer release];
    didLoadTimer = nil;
    
    [container pageLoadSucceeded];
}

- (void)webView:(UIWebView *)w didFailLoadWithError:(NSError *)error
{
    if (webViewUnlinked){
        [self unlinkComplete];
        return;
    }
    
    //[navigationTimeoutTimer invalidate];
    //[navigationTimeoutTimer release];
    //navigationTimeoutTimer = nil;
       
    [container pageLoadFailed];
}

@end
