//
//  YMSimpleWebView.h
//  Yammer
//
//  Created by Samuel Sutch on 6/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface YMSimpleWebView : UIViewController <UIWebViewDelegate> {
  IBOutlet UIWebView *webView;
  NSMutableURLRequest *req;
}

@property (nonatomic, retain) NSMutableURLRequest *req;
@property (nonatomic, assign) UIWebView *webView;

@end
