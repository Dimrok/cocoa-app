//
//  InfinitFeatureManager.m
//  InfinitApplication
//
//  Created by Christopher Crone on 02/10/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitFeatureManager.h"

static InfinitFeatureManager* _instance = nil;

@implementation InfinitFeatureManager
{
  NSDictionary* _features;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)init
{
  if (self = [super init])
  {
    _features = nil;
  }
  return self;
}

+ (instancetype)sharedInstance
{
  if (_instance == nil)
    _instance = [[InfinitFeatureManager alloc] init];
  return _instance;
}

//- General Functions ------------------------------------------------------------------------------

- (void)fetchFeatures
{
  _features = [[IAGapState instance] fetchFeatures];
}

- (NSDictionary*)features
{
  return _features;
}

- (NSString*)featuresString
{
  NSMutableString* res = [[NSMutableString alloc] init];
  for (NSString* key in _features)
  {
    [res appendString:[NSString stringWithFormat:@"%@=%@;", key, _features[key]]];
  }
  if (res.length > 0)
    return [res substringToIndex:(res.length - 1)];
  else
    return res;
}

@end
