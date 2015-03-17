//
//  InfinitFeatureManager.m
//  InfinitApplication
//
//  Created by Christopher Crone on 02/10/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitFeatureManager.h"

#import <Gap/InfinitConnectionManager.h>
#import <Gap/InfinitStateManager.h>

static InfinitFeatureManager* _instance = nil;

@implementation InfinitFeatureManager
{
  NSDictionary* _features;
}

#pragma mark - Init

- (id)init
{
  NSCAssert(_instance == nil, @"Use sharedInstance");
  if (self = [super init])
  {
    _features = nil;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(connectionStatusChanged:)
                                                 name:INFINIT_CONNECTION_STATUS_CHANGE 
                                               object:nil];
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (instancetype)sharedInstance
{
  if (_instance == nil)
    _instance = [[InfinitFeatureManager alloc] init];
  return _instance;
}

#pragma mark - General

- (void)updateFeatures
{
  _features = [[[InfinitStateManager sharedInstance] features] copy];
}

- (NSString*)valueForFeature:(NSString*)feature
{
  return _features[feature];
}

#pragma mark - Connection Status Changed

- (void)connectionStatusChanged:(NSNotification*)notification
{
  InfinitConnectionStatus* connection_status = notification.object;
  if (connection_status.status)
    [self updateFeatures];
}

@end
