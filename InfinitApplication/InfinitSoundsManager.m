//
//  InfinitSoundsManager.m
//  InfinitApplication
//
//  Created by Christopher Crone on 21/07/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitSoundsManager.h"

#import "IAUserPrefs.h"

@interface InfinitSoundsManager ()

@property (atomic, readwrite) BOOL sounds_enabled;

@end

static InfinitSoundsManager* _instance = nil;
static dispatch_once_t _instance_token = 0;
static NSString* _pref_name = @"sounds_enabled";

@implementation InfinitSoundsManager

#pragma mark - Init

- (instancetype)init
{
  NSCAssert(_instance == nil, @"Use sharedInstance.");
  if (self = [super init])
  {
    id pref = [IAUserPrefs prefsForKey:_pref_name];
    if (pref != nil)
      self.sounds_enabled = [pref boolValue];
    else
      self.sounds_enabled = YES;
  }
  return self;
}

+ (instancetype)sharedInstance
{
  dispatch_once(&_instance_token, ^
  {
    _instance = [[self alloc] init];
  });
  return _instance;
}

#pragma mark - Public

+ (BOOL)soundsEnabled
{
  return [[self sharedInstance] sounds_enabled];
}

+ (void)setSoundsEnabled:(BOOL)enabled
{
  InfinitSoundsManager* manager = [self sharedInstance];
  if (manager.sounds_enabled != enabled)
  {
    manager.sounds_enabled = enabled;
    [IAUserPrefs setPref:@(enabled) forKey:_pref_name];
  }
}

@end
