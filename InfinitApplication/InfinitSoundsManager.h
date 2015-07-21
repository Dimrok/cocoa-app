//
//  InfinitSoundsManager.h
//  InfinitApplication
//
//  Created by Christopher Crone on 21/07/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface InfinitSoundsManager : NSObject

+ (BOOL)soundsEnabled;

+ (void)setSoundsEnabled:(BOOL)enabled;

@end
