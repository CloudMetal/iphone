//
//  YMSimpleWebView.h
//  Yammer
//
//  Created by Samuel Sutch on 6/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface YMSimpleWebView : UIViewController {
  IBOutlet UIWebView *webView;
}

@property (nonatomic, assign) UIWebView *webView;

@end
