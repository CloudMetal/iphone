//
//  YMMessageTableViewCell.h
//  Yammer
//
//  Created by Samuel Sutch on 5/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface YMMessageTableViewCell : UITableViewCell {
  IBOutlet UIImageView *avatarImageView;
  IBOutlet UILabel *titleLabel;
  IBOutlet UILabel *bodyLabel;
  IBOutlet UILabel *dateLabel;
}

@property (nonatomic, readwrite, assign) UIImageView *avatarImageView;
@property (nonatomic, readwrite, assign) UILabel *titleLabel, *bodyLabel, *dateLabel;

@end
