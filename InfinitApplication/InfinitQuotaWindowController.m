//
//  InfinitQuotaWindowController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 12/05/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitQuotaWindowController.h"

#import "InfinitMetricsManager.h"

#import <Gap/InfinitAccountManager.h>
#import <Gap/InfinitColor.h>
#import <Gap/InfinitDataSize.h>

#define INFINIT_UPGRADE_PLAN_URL @"https://infinit.io/account?utm_source=app&utm_medium=mac&utm_campaign=upgrade_plan"

@interface InfinitQuotaMainView : NSView
@end

@interface InfinitQuotaWindowController ()
@property (nonatomic, weak) IBOutlet NSTextField* title_label;
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

static NSString* _title_str = nil;

@implementation InfinitQuotaWindowController

- (void)windowDidLoad
{
  [super windowDidLoad];
  if (_title_str == nil)
    _title_str = NSLocalizedString(@"You have exceeded your <size> quota for links.", nil);
}

- (void)showWindow:(id)sender
{
  [super showWindow:sender];
  NSMutableString* title_str = [_title_str mutableCopy];
  NSRange range = [title_str rangeOfString:@"<size>"];
  uint64_t quota = [InfinitAccountManager sharedInstance].link_space_quota;
  [title_str replaceCharactersInRange:range
                           withString:[InfinitDataSize fileSizeStringFrom:@(quota)]];
  self.title_label.stringValue = title_str;
  self.window.level = kCGFloatingWindowLevel;
  [self.window center];
}

#pragma mark - Button Handling

- (IBAction)cancelClicked:(id)sender
{
  [self.window close];
  [InfinitMetricsManager sendMetric:INFINIT_METRIC_LINK_QUOTA_CANCEL];
}

- (IBAction)upgradeClicked:(id)sender
{
  [self.window close];
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:INFINIT_UPGRADE_PLAN_URL]];
  [InfinitMetricsManager sendMetric:INFINIT_METRIC_LINK_QUOTA_UPGRADE];
}

@end
