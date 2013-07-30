//
//  IAFunctions.h
//  InfinitApplication
//
//  Created by Christopher Crone on 7/26/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IAFunctions : NSObject

+ (NSImage*)imageNamed:(NSString*)imageName;

+ (BOOL)stringIsValidEmail:(NSString*)str;

@end
