//
//  InfinitSearchBoxView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 22/03/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitSearchBoxView.h"

#import <Gap/InfinitColor.h>

@implementation InfinitSearchBoxView

- (BOOL)isOpaque
{
  return YES;
}

- (BOOL)isFlipped
{
  return NO;
}

- (void)drawRect:(NSRect)dirtyRect
{
  if (self.link_mode)
    [[InfinitColor colorWithGray:248] set];
  else
    [[NSColor whiteColor] set];
  NSRectFill(self.bounds);
  NSRect line = NSMakeRect(0.0, 0.0, self.bounds.size.width, 1.0);
  [[InfinitColor colorWithGray:228] set];
  NSRectFill(line);
}

- (NSSize)intrinsicContentSize
{
  return self.frame.size;
}

- (void)setLink_mode:(BOOL)link_mode
{
  _link_mode = link_mode;
  [self setNeedsDisplay:YES];
}


@end
