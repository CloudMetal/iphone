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
  IBOutlet UIButton *feedButton;
  IBOutlet UILabel *joinDateLabel;
  IBOutlet UILabel *followingCountLabel;
  IBOutlet UILabel *yamCountLabel;
  IBOutlet UILabel *followersLabel;
  id<DKCallback> onFollow, onMessage, onFeed;
  YMContact *contact;
}

@property (nonatomic, readwrite, retain) YMContact *contact;
@property (nonatomic, readwrite, retain) 
  id<DKCallback> onFollow, onMessage, onFeed;
@property (nonatomic, assign) UIButton *followButton;
@property (nonatomic, assign) UILabel *joinDateLabel, *followingCountLabel, *yamCountLabel, *followersLabel;

+ (id)contactDetailViewWithRect:(CGRect)rect;

- (IBAction)follow:(id)sender;
- (IBAction)message:(id)sender;
- (IBAction)feed:(id)sender;
- (void)hideFollowAndPM;

@end
