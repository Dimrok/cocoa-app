//
//  InfinitUsageBar.m
//  InfinitApplication
//
//  Created by Christopher Crone on 18/08/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitUsageBar.h"

#import <Gap/InfinitColor.h>

@interface InfinitUsageBar ()

@property (readwrite) NSTrackingArea* tracking_area;

@end

static NSColor* _bar_color = nil;
static NSColor* _background_color = nil;
static CGFloat _height = 6.0f;
static NSColor* _shadow_color = nil;

@implementation InfinitUsageBar

- (BOOL)isFlipped
{
  return NO;
}

- (BOOL)wantsUpdateLayer
{
  return NO;
}

#pragma mark - Init

- (instancetype)initWithCoder:(NSCoder*)coder
{
  if (self = [super initWithCoder:coder])
  {
    if (!_bar_color)
      _bar_color = [InfinitColor colorWithGray:255];
    if (!_background_color)
      _background_color = [InfinitColor colorWithGray:255 alpha:0.6f];
    if (!_shadow_color)
      _shadow_color = [InfinitColor colorWithGray:0 alpha:0.3f];
    self.delegate = nil;
  }
  return self;
}

- (void)dealloc
{
  _delegate = nil;
}

#pragma mark - Drawing

- (void)drawRect:(NSRect)dirtyRect
{
  CGFloat radius = floor(_height / 2.0f);
  CGFloat y_inset = floor((NSHeight(self.bounds) - _height) / 2.0f);
  NSRect background_rect = CGRectInset(self.bounds, 0.0f, y_inset);
  NSBezierPath* shadow =
    [NSBezierPath bezierPathWithRoundedRect:CGRectOffset(background_rect, 0.0f, -1.0f)
                                    xRadius:radius
                                    yRadius:radius];
  [_shadow_color set];
  [shadow fill];
  NSBezierPath* background = [NSBezierPath bezierPathWithRoundedRect:background_rect
                                                             xRadius:radius
                                                             yRadius:radius];
  [_background_color set];
  [background fill];
  CGFloat usage_width = floor(self.doubleValue / self.maxValue * NSWidth(self.bounds));
  NSRect usage_rect =
    NSMakeRect(background_rect.origin.x, background_rect.origin.y, usage_width, _height);
  NSBezierPath* usage = [NSBezierPath bezierPathWithRoundedRect:usage_rect
                                                        xRadius:radius
                                                        yRadius:radius];
  [_bar_color set];
  [usage fill];
}

#pragma mark - Mouse Handling

- (void)createTrackingArea
{
  self.tracking_area = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                    options:(NSTrackingMouseEnteredAndExited |
                                                             NSTrackingActiveAlways)
                                                      owner:self
                                                   userInfo:nil];
  [self addTrackingArea:self.tracking_area];
  NSPoint mouse_loc = self.window.mouseLocationOutsideOfEventStream;
  mouse_loc = [self convertPoint:mouse_loc fromView:nil];
  if (NSPointInRect(mouse_loc, self.bounds))
    [self mouseEntered:nil];
  else
    [self mouseExited:nil];
}

- (void)updateTrackingAreas
{
  [self removeTrackingArea:self.tracking_area];
  [self createTrackingArea];
  [super updateTrackingAreas];
}

- (void)resetCursorRects
{
  [super resetCursorRects];
  [self addCursorRect:self.bounds cursor:[NSCursor pointingHandCursor]];
}

- (void)mouseEntered:(NSEvent*)theEvent
{
  [self.delegate mouseEnteredUsageBar:self];
}

- (void)mouseExited:(NSEvent*)theEvent
{
  [self.delegate mouseExitedUsageBar:self];
}

- (void)mouseDown:(NSEvent*)theEvent
{
  if (theEvent.clickCount != 1)
    return;
  [self.delegate clickedUsageBar:self];
}

@end
