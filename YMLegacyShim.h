//
//  YMLegacyAppShim.h
//  Yammer
//
//  Created by Samuel Sutch on 5/3/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class YMNetwork;

@interface YMLegacyShim : NSObject {

}

+ (id)sharedShim;
- (id)_legacyEnterAppWithNetwork:(YMNetwork *)network;

@end
