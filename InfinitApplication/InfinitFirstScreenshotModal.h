//
//  InfinitFirstScreenshotModal.h
//  InfinitApplication
//
//  Created by Christopher Crone on 30/09/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum
{
  INFINIT_UPLOAD_SCREENSHOTS,
  INFINIT_NO_UPLOAD_SCREENSHOTS,
} InfinitFirstScreenshotResponse;

@interface InfinitFirstScreenshotModal : NSWindowController

@property (nonatomic, weak) IBOutlet NSTextField* information;

- (id)init;

- (void)close;

@end
