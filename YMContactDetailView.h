//
//  YMContactDetailView.h
//  Yammer
//
//  Created by Samuel Sutch on 5/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class YMContact;

@interface YMContactDetailView : UIView
{
  IBOutlet UIImageView *mugImageView;
  IBOutlet UILabel *fullNameLabel;
  IBOutlet UILabel *locationLabel;
  IBOutlet UILabel *jobTitleLabel;
  IBOutlet UIButton *followButton;
  IBOutlet UIButton *messageButton;
  id<DKCallback> onFollow;
  id<DKCallback> onMessage;
  YMContact *contact;
}

@property (nonatomic, readwrite, retain) YMContact *contact;
@property (nonatomic, readwrite, retain) 
  id<DKCallback> onFollow, onMessage;

+ (id)contactDetailViewWithRect:(CGRect)rect;

- (IBAction)follow:(id)sender;
- (IBAction)message:(id)sender;

@end
