//
//  InfinitOSVersion.m
//  InfinitApplication
//
//  Created by Christopher Crone on 15/07/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitOSVersion.h"

InfinitOSVersionStruct
InfinitOSVersionMake(int major, int minor, int subminor)
{
  InfinitOSVersionStruct res;
  res.major = major;
  res.minor = minor;
  res.subminor = subminor;
  return res;
}

@implementation InfinitOSVersion

+ (InfinitOSVersionStruct)osVersion
{
  SInt32 major, minor, subminor;
  if (Gestalt(gestaltSystemVersionMajor, &major) != noErr)
    return InfinitOSVersionMake(0, 0, 0);
  if (Gestalt(gestaltSystemVersionMinor, &minor) != noErr)
    return InfinitOSVersionMake(0, 0, 0);
  if (Gestalt(gestaltSystemVersionBugFix, &subminor) != noErr)
    return InfinitOSVersionMake(0, 0, 0);
  return InfinitOSVersionMake(major, minor, subminor);
}

@end
