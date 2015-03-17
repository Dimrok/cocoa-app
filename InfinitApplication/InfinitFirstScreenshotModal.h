//
//  InfinitFirstScreenshotModal.h
//  InfinitApplication
//
//  Created by Christopher Crone on 30/09/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSUInteger, InfinitFirstScreenshotResponse)
{
  INFINIT_UPLOAD_SCREENSHOTS,
  INFINIT_NO_UPLOAD_SCREENSHOTS,
};

@interface InfinitFirstScreenshotModal : NSWindowController

- (void)close;

@end
