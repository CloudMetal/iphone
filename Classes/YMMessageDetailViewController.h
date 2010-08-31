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
@class YMUserAccount;
@class YMWebService;

@interface YMMessageDetailViewController : UITableViewController {
  YMMessageDetailView *detailView;
  YMMessage *message;
  YMWebService *web;
  YMUserAccount *userAccount;
  NSArray *attachments;
  NSMutableDictionary *attachmentCache;
  id<DKKeyedPool> loadingPool;
  BOOL fetchingAttachment;
  NSArray *feedItems;
  BOOL refreshing;
}

@property (nonatomic, readwrite, retain) NSArray *feedItems;
@property (nonatomic, readwrite, retain) YMMessage *message;
@property (nonatomic, readwrite, retain) YMUserAccount *userAccount;

- (void)refreshMessageData;

@end
