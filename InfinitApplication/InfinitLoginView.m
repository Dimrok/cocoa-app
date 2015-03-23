//
//  InfinitLoginView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 19/03/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitLoginView.h"

#import <Gap/InfinitColor.h>

@implementation InfinitLoginView

- (BOOL)isOpaque
{
  return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
  CGFloat top_h = 170.0f;
  [[NSColor whiteColor] set];
  NSRectFill(NSMakeRect(0.0f, self.bounds.size.height - top_h, self.bounds.size.width, top_h));
  CGFloat center = floor(self.bounds.size.width / 2.0f);
  CGFloat triangle_w = 15.0f;
  CGFloat triangle_h = 10.0f;
  CGFloat delta_x = self.selector == InfinitLoginSelectorLeft ? - 30.0f : 50.0f;
  NSBezierPath* bottom_path = [NSBezierPath bezierPath];
  [bottom_path moveToPoint:NSMakePoint(-1.0f, self.bounds.size.height - top_h)];
  [bottom_path lineToPoint:NSMakePoint(center - triangle_w + delta_x,
                                       self.bounds.size.height - top_h)];
  [bottom_path lineToPoint:NSMakePoint(center - (triangle_w / 2.0f) + delta_x,
                                       self.bounds.size.height - top_h + triangle_h)];
  [bottom_path lineToPoint:NSMakePoint(center + delta_x, self.bounds.size.height - top_h)];
  [bottom_path lineToPoint:NSMakePoint(self.bounds.size.width, self.bounds.size.height - top_h)];
  [bottom_path lineToPoint:NSMakePoint(self.bounds.size.width, -1.0f)];
  [bottom_path lineToPoint:NSMakePoint(-1.0f, -1.0f)];
  [bottom_path closePath];
  [[InfinitColor colorWithGray:248] set];
  [bottom_path fill];
  [[InfinitColor colorWithGray:224] set];
  [bottom_path stroke];
}

- (void)setSelector:(InfinitLoginSelector)selector
{
  if (self.selector == selector)
    return;
  _selector = selector;
  [self setNeedsDisplay:YES];
}

@end
