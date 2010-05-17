//
//  YMMessageDetailViewController.h
//  Yammer
//
//  Created by Samuel Sutch on 5/14/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YMMessageDetailView.h"

//@class YMMessageDetailView, YMMessage, YMWebService;

@class YMMessage;
@class YMWebService;

@interface YMMessageDetailViewController : UITableViewController {
  YMMessageDetailView *detailView;
  YMMessage *message;
  YMWebService *web;
}

@property (nonatomic, readwrite, retain) YMMessage *message;

@end
