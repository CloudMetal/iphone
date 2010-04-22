//
//  NSFileManager+Convenience.m
//  RingFree
//
//  Created by aarthur on 10/13/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NSFileManager+Convenience.h"


@implementation NSFileManager (Convenience)

+ (NSString*)sandBoxDocsPathForFileName:(NSString*)fileName
{
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths objectAtIndex:0];
  return [documentsDirectory stringByAppendingPathComponent:fileName];
}

+ (NSString*)resourcesPathForFileName:(NSString*)fileName
{
  NSString *resourceItemPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:fileName];
  return resourceItemPath;
}

+ (BOOL)fileNameExistsInDocumentsSandbox:(NSString*)fileName
{
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths objectAtIndex:0];
  NSString *writablePath = [documentsDirectory stringByAppendingPathComponent:fileName];
  
  NSFileManager *fileManager = [self defaultManager];
  BOOL success = [fileManager fileExistsAtPath: writablePath];
  
  return success;
}

- (NSString*)sandBoxDocsPathForFileName:(NSString*)fileName
{
  return [[self class] sandBoxDocsPathForFileName:fileName];
}

- (NSString*)resourcesPathForFileName:(NSString*)fileName
{
  return [[self class] resourcesPathForFileName:fileName];
}

- (BOOL)fileNameExistsInDocumentsSandbox:(NSString*)fileName
{
  return [[self class] fileNameExistsInDocumentsSandbox:fileName];
}

- (void)removeSandBoxItemNamed:(NSString*)itemName
{
  if ([self fileNameExistsInDocumentsSandbox:itemName]) {
    NSError *error;
    NSString *writablePath = [self sandBoxDocsPathForFileName:itemName];
    [self removeItemAtPath:writablePath error:&error];
  }
}

- (BOOL)copyResourceItem:(NSString*)item toFileNameInSandboxDocs:(NSString*)fileName andRetrunError:(NSError**)error
{
  NSString *resourceItemPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:item];
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths objectAtIndex:0];
  NSString *writablePath = [documentsDirectory stringByAppendingPathComponent:fileName];
  BOOL success;
  
  //if it is already there delete it first
  if ([self fileNameExistsInDocumentsSandbox:fileName]) {
    [self removeItemAtPath:writablePath error:error];
  }
  
  success = [self copyItemAtPath:resourceItemPath toPath:writablePath error:error];
  return success;
}

@end
