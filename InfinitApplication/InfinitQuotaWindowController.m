//
//  InfinitQuotaWindowController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 12/05/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitQuotaWindowController.h"

#import <Gap/InfinitColor.h>

#define INFINIT_UPGRADE_PLAN_URL @"https://infinit.io/account?utm_source=app&utm_medium=mac&utm_campaign=upgrade_plan"

@interface InfinitQuotaMainView : NSView
@end

@interface InfinitQuotaWindowController ()
@end

@implementation InfinitQuotaMainView

- (void)drawRect:(NSRect)dirtyRect
{
  [[NSColor whiteColor] set];
  NSRectFill(self.bounds);
  [[InfinitColor colorWithGray:237] set];
  NSRectFill(NSMakeRect(0.0f, 1.0f, self.bounds.size.width, 1.0f));
}

@end

@implementation InfinitQuotaWindowController

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
}

- (IBAction)upgradeClicked:(id)sender
{
  [self.window close];
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:INFINIT_UPGRADE_PLAN_URL]];
}

@end
