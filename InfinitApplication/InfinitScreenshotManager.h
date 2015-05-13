//
//  InfinitScreenshotManager.h
//  InfinitApplication
//
//  Created by Christopher Crone on 25/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface InfinitScreenshotManager : NSObject <NSMetadataQueryDelegate>

@property (nonatomic, readwrite) BOOL watch;

+ (instancetype)sharedInstance;

@end
