#import "NSString+UUID.h"


@implementation NSString (UUID)
+ (NSString *)stringWithUUID
{
  CFUUIDRef uuid = CFUUIDCreate(nil);
  NSString *uuidString = (NSString *)CFUUIDCreateString(nil, uuid);
  CFRelease(uuid);
  return [uuidString autorelease];
}
@end
