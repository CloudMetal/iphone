//
//  UIImage+DKDeferred.m
//  DeferredKit
//
//  Created by Samuel Sutch on 8/30/09.
//

#import "UIImage+DKDeferred.h"
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>


@implementation UIImage (DKDeferredAdditions)

+ (UIImage*)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
  
  UIGraphicsBeginImageContext(newSize);
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextTranslateCTM(context, 0.0, newSize.height);
	CGContextScaleCTM(context, 1.0, -1.0);
	
	CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, newSize.width, newSize.height), image.CGImage);
	
	UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
	
	UIGraphicsEndImageContext();
	
	return scaledImage;
}

- (UIImage *)scaleImageToSize:(CGSize)newSize {
  return [UIImage imageWithImage:self scaledToSize:newSize];
}

@end
