//
//  InfinitGhostSendWindowController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 25/06/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitGhostSendWindowController.h"

#import "InfinitMetricsManager.h"

#import <Gap/InfinitColor.h>

@interface InfinitGhostSendWindowController ()
@end

@interface InfinitGhostSendWindowView : NSView
@end

@implementation InfinitGhostSendWindowView

- (void)drawRect:(NSRect)dirtyRect
{
  [[NSColor whiteColor] set];
  NSRectFill(self.bounds);
  [[InfinitColor colorWithGray:237] set];
  NSRectFill(NSMakeRect(0.0f, 1.0f, self.bounds.size.width, 1.0f));
}

@end

@implementation InfinitGhostSendWindowController

- (void)windowDidLoad
{
  [super windowDidLoad];
}

- (void)showWindow:(id)sender
{
  [super showWindow:sender];
  self.window.level = kCGFloatingWindowLevel;
  [self.window center];
}

#pragma mark - Button Handling

- (IBAction)cancelClicked:(id)sender
{
  [self.window close];
  [InfinitMetricsManager sendMetric:INFINIT_METRIC_GHOST_LIMIT_CANCEL];
  self.send_block = nil;
}

- (IBAction)okClicked:(id)sender
{
  [self.window close];
  self.send_block();
  [InfinitMetricsManager sendMetric:INFINIT_METRIC_GHOST_LIMIT_CONTINUE];
  self.send_block = nil;
}

@end
