//
//  YMMessageCompanionTableViewCell.m
//  Yammer
//
//  Created by Samuel Sutch on 5/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "YMMessageCompanionTableViewCell.h"


@implementation YMMessageCompanionTableViewCell

@synthesize onLike, onThread, onUser, onMore, onReply;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        // Initialization code
    }
    return self;
}

-(void) like:(id)sender {
  if (self.onLike) [self.onLike :sender];
}

- (void) more:(id)sender {
  if (self.onMore) [self.onMore :sender];
}

- (void) thread:(id)sender {
  if (self.onThread) [self.onThread :sender];
}

- (void) user:(id)sender {
  if (self.onUser) [self.onUser :sender];
}

- (void) reply:(id)sender {
  if (self.onReply) [self.onReply :sender];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
  // do nothing
}


- (void)dealloc {
    [super dealloc];
}


@end
