//
//  YMContactDetailViewController.h
//  Yammer
//
//  Created by Samuel Sutch on 5/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>


@class YMUserAccount, YMWebService, YMContact, YMNetwork;


@interface YMContactDetailViewController : UITableViewController
<MFMailComposeViewControllerDelegate>
{
  YMWebService *web;
  YMUserAccount *userAccount;
  YMContact *contact;
  YMNetwork *network;
}

@property (nonatomic, readwrite, retain) YMContact *contact;
@property (nonatomic, readwrite, retain) YMUserAccount *userAccount;

@end
