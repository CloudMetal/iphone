//
//  YMDraft.h
//  Yammer
//
//  Created by Samuel Sutch on 8/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SQLitePersistentObject.h"


@interface YMDraft : SQLitePersistentObject {
  NSNumber *groupID;
  NSNumber *inReplyToID;
  NSNumber *directToID;
  NSString *body;
  NSArray *attachments;
  NSNumber *userAccountPK;
  NSNumber *networkPK;
  
}

@property (nonatomic, readwrite, retain) NSNumber *groupID, 
  *inReplyToID, *directToID, *userAccountPK, *networkPK;
@property (nonatomic, readwrite, retain) NSString *body;
@property (nonatomic, readwrite, retain) NSArray *attachments;

@end
