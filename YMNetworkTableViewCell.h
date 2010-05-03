//
//  YMNetworkTableViewCell.h
//  Yammer
//
//  Created by Samuel Sutch on 5/3/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface YMNetworkTableViewCell : UITableViewCell {
  UILabel *unreadLabel;
}

@property (nonatomic, readwrite, retain) UILabel *unreadLabel;

@end
