//
//  InfinitFeatureManager.h
//  InfinitApplication
//
//  Created by Christopher Crone on 02/10/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface InfinitFeatureManager : NSObject

@property (nonatomic, readonly) NSDictionary* features;

+ (instancetype)sharedInstance;

- (NSString*)valueForFeature:(NSString*)feature;

@end
