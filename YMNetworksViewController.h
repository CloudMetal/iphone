//
//  YMNetworksViewController.h
//  Yammer
//
//  Created by Samuel Sutch on 4/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class YMWebService;
@class YMNetwork;


@interface YMNetworksViewController : UITableViewController
{
  YMWebService *web;
}

@property (nonatomic, readonly) YMWebService *web;

- (void)refreshNetworks;
- (id)_legacyEnterAppWithNetwork:(YMNetwork *)network;

@end
