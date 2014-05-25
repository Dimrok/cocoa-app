//
//  InfinitScreenshotManager.h
//  InfinitApplication
//
//  Created by Christopher Crone on 25/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol InfinitScreenshotManagerProtocol;

@interface InfinitScreenshotManager : NSObject <NSMetadataQueryDelegate>

@property (nonatomic, readwrite) BOOL watch;

- (id)initWithDelegate:(id<InfinitScreenshotManagerProtocol>)delegate;

@end

@protocol InfinitScreenshotManagerProtocol <NSObject>

- (void)screenshotManager:(InfinitScreenshotManager*)sender
            gotScreenshot:(NSString*)path;

@end
