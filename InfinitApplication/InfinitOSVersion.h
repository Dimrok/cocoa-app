//
//  InfinitOSVersion.h
//  InfinitApplication
//
//  Created by Christopher Crone on 15/07/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct _InfinitOSVersionStruct
{
  SInt32 major, minor, subminor;
} InfinitOSVersionStruct;

@interface InfinitOSVersion : NSObject

+ (InfinitOSVersionStruct)osVersion;

@end
