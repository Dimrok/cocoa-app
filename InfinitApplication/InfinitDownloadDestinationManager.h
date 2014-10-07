//
//  InfinitDownloadDestinationManager.h
//  InfinitApplication
//
//  Created by Christopher Crone on 07/10/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface InfinitDownloadDestinationManager : NSObject

@property (nonatomic, readonly) NSString* download_destination;

+ (instancetype)sharedInstance;

- (void)setDownloadDestination:(NSString*)download_destination;
- (void)ensureDownloadDestination;

@end
