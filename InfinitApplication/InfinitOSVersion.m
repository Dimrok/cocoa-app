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

InfinitOSVersionStruct
InfinitOSReleaseMake(int major, int minor)
{
  return InfinitOSVersionMake(major, minor, 0);
}

static InfinitOSVersionStruct _version;
static dispatch_once_t _version_token = 0;

@implementation InfinitOSVersion

#pragma mark - Version

+ (InfinitOSVersionStruct)osVersion
{
  dispatch_once(&_version_token, ^
  {
    SInt32 major, minor, subminor;
    if (Gestalt(gestaltSystemVersionMajor, &major) != noErr)
    {
      _version = InfinitOSVersionMake(0, 0, 0);
      _version_token = 0;
    }
    if (Gestalt(gestaltSystemVersionMinor, &minor) != noErr)
    {
      _version = InfinitOSVersionMake(0, 0, 0);
      _version_token = 0;
    }
    if (Gestalt(gestaltSystemVersionBugFix, &subminor) != noErr)
    {
      _version = InfinitOSVersionMake(0, 0, 0);
      _version_token = 0;
    }
    _version = InfinitOSVersionMake(major, minor, subminor);
  });
  return _version;
}

+ (NSString*)osVersionString
{
  InfinitOSVersionStruct version = [self osVersion];
  return [NSString stringWithFormat:@"%d.%d.%d", version.major, version.minor, version.subminor];
}

#pragma mark - Release Comparison

+ (BOOL)equalToRelease:(InfinitOSVersionStruct)version
{
  InfinitOSVersionStruct this_version = [self osVersion];
  if (this_version.major == version.major && this_version.minor == version.minor)
    return YES;
  return NO;
}

+ (BOOL)greaterThanRelease:(InfinitOSVersionStruct)version
{
  InfinitOSVersionStruct this_version = [self osVersion];
  if (version.major > this_version.major)
    return YES;
  if (version.major == this_version.major && version.minor > this_version.minor)
    return YES;
  return NO;
}

+ (BOOL)greaterThanEqualToRelease:(InfinitOSVersionStruct)version
{
  if (![self lessThanRelease:version])
    return YES;
  return NO;
}

+ (BOOL)lessThanRelease:(InfinitOSVersionStruct)version
{
  if (![self greaterThanRelease:version] && ![self equalToRelease:version])
    return YES;
  return NO;
}

+ (BOOL)equalTo:(InfinitOSVersionStruct)version
{
  InfinitOSVersionStruct this_version = [self osVersion];
  if (this_version.major == version.major &&
      this_version.minor == version.minor &&
      this_version.subminor == version.subminor)
  {
    return YES;
  }
  return NO;
}

#pragma mark - Release Comparison

+ (BOOL)greaterThan:(InfinitOSVersionStruct)version
{
  InfinitOSVersionStruct this_version = [self osVersion];
  if (version.major > this_version.major)
    return YES;
  if (version.major == this_version.major && version.minor > this_version.minor)
    return YES;
  if (version.major == this_version.major &&
      version.minor == this_version.minor &&
      version.subminor > this_version.subminor)
  {
    return YES;
  }
  return NO;
}

+ (BOOL)greaterThanEqualTo:(InfinitOSVersionStruct)version
{
  return ![self lessThan:version];
}

+ (BOOL)lessThan:(InfinitOSVersionStruct)version
{
  if (![self greaterThan:version] && ![self equalTo:version])
    return YES;
  return NO;
}

@end
