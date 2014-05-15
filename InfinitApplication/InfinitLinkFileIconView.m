//
//  InfinitLinkFileIconView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 14/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitLinkFileIconView.h"

@implementation InfinitLinkFileIconView

static CGFloat corner_radius = 4.0;

- (void)drawRect:(NSRect)dirtyRect
{
  [NSGraphicsContext saveGraphicsState];
  NSBezierPath* rounded_rect = [NSBezierPath bezierPathWithRoundedRect:self.bounds
                                                               xRadius:corner_radius
                                                               yRadius:corner_radius];
  [rounded_rect addClip];
  [_icon drawInRect:self.bounds fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
  [NSGraphicsContext restoreGraphicsState];
}

- (void)setIcon:(NSImage*)icon
{
  _icon = icon;
  [self setNeedsDisplay:YES];
}

@end
