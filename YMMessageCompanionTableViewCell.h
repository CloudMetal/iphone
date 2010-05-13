//
//  YMMessageCompanionTableViewCell.h
//  Yammer
//
//  Created by Samuel Sutch on 5/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface YMMessageCompanionTableViewCell : UITableViewCell
{
  IBOutlet UIButton *userButton;
  IBOutlet UIButton *likeButton;
  IBOutlet UIButton *threadButton;
  IBOutlet UIButton *moreButton;
  IBOutlet UIButton *replyButton;
  id<DKCallback> onReply;
  id<DKCallback> onUser;
  id<DKCallback> onLike;
  id<DKCallback> onThread;
  id<DKCallback> onMore;
}

@property (nonatomic, readwrite, retain) 
  id<DKCallback> onUser, onLike, onThread, onMore, onReply;

- (IBAction)user:(id)sender;
- (IBAction)like:(id)sender;
- (IBAction)thread:(id)sender;
- (IBAction)more:(id)sender;
- (IBAction)reply:(id)sender;

@end
