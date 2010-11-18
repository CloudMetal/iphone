//
//  NSDate-SQLitePersistence.m
// ----------------------------------------------------------------------
// Part of the SQLite Persistent Objects for Cocoa and Cocoa Touch
//
// Original Version: (c) 2008 Jeff LaMarche (jeff_Lamarche@mac.com)
// ----------------------------------------------------------------------
// This code may be used without restriction in any software, commercial,
// free, or otherwise. There are no attribution requirements, and no
// requirement that you distribute your changes, although bugfixes and 
// enhancements are welcome.
// 
// If you do choose to re-distribute the source code, you must retain the
// copyright notice and this license information. I also request that you
// place comments in to identify your changes.
//
// For information on how to use these classes, take a look at the 
// included Readme.txt file
// ----------------------------------------------------------------------
#import "NSDate-SQLitePersistence.h"

static NSDateFormatter *dateFormatter1 = nil;
static NSDateFormatter *dateFormatter2 = nil;

@implementation NSDate(SQLitePersistence)
+ (id)objectWithSqlColumnRepresentation:(NSString *)columnData;
{ 
  if (!dateFormatter1) {
    dateFormatter1 = [[[NSDateFormatter alloc] init] retain];
    [dateFormatter1 setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSSS"];
  }
  return [dateFormatter1 dateFromString:columnData];
}
- (NSString *)sqlColumnRepresentationOfSelf
{
  if (!dateFormatter2) {
    dateFormatter2 = [[[NSDateFormatter alloc] init] retain];
    [dateFormatter2 setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSSS"];
  }
  
  NSString *formattedDateString = [dateFormatter2 stringFromDate:self];
  
  return formattedDateString;
}
+ (BOOL)canBeStoredInSQLite
{
  return YES;
}
+ (NSString *)columnTypeForObjectStorage
{
  return kSQLiteColumnTypeReal;
}
+ (BOOL)shouldBeStoredInBlob
{
  return NO;
}
@end
