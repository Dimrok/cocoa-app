//
//  InfinitScreenshotTextView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 03/10/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitScreenshotTextView.h"

@implementation InfinitScreenshotTextView

- (void)drawRect:(NSRect)dirtyRect
{
  [IA_RGB_COLOUR(255, 255, 255) set];
  NSRectFill(self.bounds);
  NSBezierPath* line =
    [NSBezierPath bezierPathWithRect:NSMakeRect(0.0, 1.0, NSWidth(self.bounds), 1.0)];
  [IA_RGB_COLOUR(198, 198, 198) set];
  [line fill];
}

@end
