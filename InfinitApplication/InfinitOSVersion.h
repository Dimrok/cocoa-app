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

InfinitOSVersionStruct
InfinitOSVersionMake(int major, int minor, int subminor);

InfinitOSVersionStruct
InfinitOSReleaseMake(int major, int minor);

@interface InfinitOSVersion : NSObject

+ (InfinitOSVersionStruct)osVersion;
+ (NSString*)osVersionString;

/// Check only major and minor version numbers.
+ (BOOL)equalToRelease:(InfinitOSVersionStruct)version;
+ (BOOL)greaterThanRelease:(InfinitOSVersionStruct)version;
+ (BOOL)greaterThanEqualToRelease:(InfinitOSVersionStruct)version;
+ (BOOL)lessThanRelease:(InfinitOSVersionStruct)version;

/// Exact version checking.
+ (BOOL)equalTo:(InfinitOSVersionStruct)version;
+ (BOOL)greaterThan:(InfinitOSVersionStruct)version;
+ (BOOL)greaterThanEqualTo:(InfinitOSVersionStruct)version;
+ (BOOL)lessThan:(InfinitOSVersionStruct)version;

@end
