//
//  YMAttachment.h
//  Yammer
//
//  Created by Samuel Sutch on 6/2/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SQLitePersistentObject.h"

@interface YMAttachment : SQLitePersistentObject
{
  NSString *type, *name, *webURL;
  NSNumber *isImage, *attachmentID, *size, *messageID, *messagePK;
  NSString *url, *imageThumbnailURL;
}

@property(copy) NSString 
  *type, *name, *webURL, *url, *imageThumbnailURL;
@property(copy) NSNumber 
  *isImage, *attachmentID, *size, *messageID, *messagePK;

@end
