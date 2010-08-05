//
//  YMTableViewController.h
//  Yammer
//
//  Created by Samuel Sutch on 7/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YMRefreshView.h"


@interface YMTableViewController : UITableViewController
{
	UIView<ActionTableViewHeader> *refreshHeaderView;
  
	BOOL checkForRefresh;
	BOOL reloading;
  BOOL useSubtitleHeader;
  
  Class actionTableViewHeaderClass;
  NSString *subtitle;
  
//	SoundEffect *psst1Sound;
//	SoundEffect *psst2Sound;
//	SoundEffect *popSound;
}

@property(assign) Class actionTableViewHeaderClass;
@property(readonly) UIView<ActionTableViewHeader> *refreshHeaderView;
@property(readonly) BOOL reloading;
@property(assign) BOOL useSubtitleHeader;

- (void)dataSourceDidFinishLoadingNewData;
- (void) showReloadAnimationAnimated:(BOOL)animated;
-(void) setHeaderTitle:(NSString*)headerTitle andSubtitle:(NSString*)headerSubtitle;

@end