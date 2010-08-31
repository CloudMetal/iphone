//
//  YMAttachment.m
//  Yammer
//
//  Created by Samuel Sutch on 6/2/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "YMAttachment.h"


@implementation YMAttachment

@synthesize type, name, webURL, isImage, attachmentID, 
            size, url, imageThumbnailURL, messageID, messagePK;

DECLARE_PROPERTIES(
                   DECLARE_PROPERTY(@"type", @"@\"NSString\""),
                   DECLARE_PROPERTY(@"name", @"@\"NSString\""),
                   DECLARE_PROPERTY(@"webURL", @"@\"NSString\""),
                   DECLARE_PROPERTY(@"isImage", @"@\"NSNumber\""),
                   DECLARE_PROPERTY(@"attachmentID", @"@\"NSNumber\""),
                   DECLARE_PROPERTY(@"size", @"@\"NSNumber\""),
                   DECLARE_PROPERTY(@"url", @"@\"NSString\""),
                   DECLARE_PROPERTY(@"imaageThumbnailURL", @"@\"NSString\""),
                   DECLARE_PROPERTY(@"messageID", @"@\"NSNumber\""),
                   DECLARE_PROPERTY(@"messagePK", @"@\"NSNumber\"")
                   )

- (NSString *) description
{
  return [NSString stringWithFormat:@"<YMAttachment type=%@ name=%@ webURL=%@ "
          @"isImage=%@ attachmentID=%@ size=%@ url=%@ imageThumbnailURL=%@ "
          @"messageID=%@ messagePK=%@", self.type, self.name, self.webURL, 
          self.isImage, self.attachmentID, self.size, self.url, 
          self.imageThumbnailURL, self.messageID, self.messagePK];
}

- (void)dealloc
{
  self.type = nil;
  self.name = nil;
  self.webURL = nil;
  self.isImage = nil;
  self.attachmentID = nil;
  self.size = nil;
  self.url = nil;
  self.imageThumbnailURL = nil;
  self.messageID = nil;
  self.messagePK = nil;
  [super dealloc];
}

@end
