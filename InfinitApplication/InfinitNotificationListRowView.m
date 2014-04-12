//
//  InfinitNotificationListRowView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 06/01/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitNotificationListRowView.h"

@implementation InfinitNotificationListRowView
{
@private
  id<InfinitNotificationListRowProtocol> _delegate;
  NSTrackingArea* _tracking_area;
}

@synthesize clickable = _clickable;
@synthesize clicked = _clicked;
@synthesize error = _error;
@synthesize hovered = _hovered;
@synthesize unread = _unread;

- (id)initWithFrame:(NSRect)frameRect
       withDelegate:(id<InfinitNotificationListRowProtocol>)delegate
       andClickable:(BOOL)clickable
{
  if (self = [super initWithFrame:frameRect])
  {
    _clickable = clickable;
    _delegate = delegate;
  }
  return self;
}

- (void)dealloc
{
  _tracking_area = nil;
}

- (BOOL)isOpaque
{
  return YES;
}

- (void)viewDidMoveToSuperview
{
  [self resetCursorRects];
}

- (void)setClicked:(BOOL)clicked
{
  if (!_clickable)
    return;
  _clicked = clicked;
  [self setNeedsDisplay:YES];
}

- (void)setError:(BOOL)error
{
  _error = error;
  [self setNeedsDisplay:YES];
}

- (void)setHovered:(BOOL)hovered
{
  if (!_clickable)
    return;
  _hovered = hovered;
  [self setNeedsDisplay:YES];
}

- (void)setUnread:(BOOL)unread
{
  _unread = unread;
  [self setNeedsDisplay:YES];
}

- (BOOL)isFlipped
{
  return NO;
}

- (void)drawRect:(NSRect)dirtyRect
{
  NSRect colour_bg_frame = NSMakeRect(self.bounds.origin.x,
                                      self.bounds.origin.y + 2.0,
                                      NSWidth(self.bounds),
                                      NSHeight(self.bounds) - 2.0);
  if (self.clicked)
  {
    // White background
    [IA_GREY_COLOUR(255.0) set];
  }
  else if (self.error)
  {
    // Yellow background
    [IA_RGB_COLOUR(253.0, 255.0, 236.0) set];
    
  }
  else if (self.hovered)
  {
    // Blue background
    [IA_RGB_COLOUR(239.0, 252.0, 255.0) set];
  }
  else if (self.unread)
  {
    // White background
    [IA_GREY_COLOUR(255.0) set];
  }
  else
  {
    // Grey background
    [IA_GREY_COLOUR(248.0) set];
  }
  
  NSRectFill(colour_bg_frame);
  
  // White line
  NSRect white_line_frame = NSMakeRect(self.bounds.origin.x,
                                       1.0,
                                       NSWidth(self.bounds),
                                       1.0);
  NSBezierPath* white_line = [NSBezierPath bezierPathWithRect:white_line_frame];
  [IA_GREY_COLOUR(220.0) set];
  [white_line fill];
  
  // Grey line
  NSRect grey_line_frame = NSMakeRect(self.bounds.origin.x,
                                      0.0,
                                      NSWidth(self.bounds),
                                      1.0);
  NSBezierPath* grey_line = [NSBezierPath bezierPathWithRect:grey_line_frame];
  [IA_GREY_COLOUR(255.0) set];
  [grey_line fill];
}

- (void)createTrackingArea
{
  _tracking_area = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                options:(NSTrackingMouseEnteredAndExited |
                                                         NSTrackingActiveAlways)
                                                  owner:self
                                               userInfo:nil];
  
  [self addTrackingArea:_tracking_area];
  
  NSPoint mouse_loc = self.window.mouseLocationOutsideOfEventStream;
  mouse_loc = [self convertPoint:mouse_loc fromView:nil];
  if (NSPointInRect(mouse_loc, self.bounds))
    [self mouseEntered:nil];
  else
    [self mouseExited:nil];
}

- (void)updateTrackingAreas
{
  [self removeTrackingArea:_tracking_area];
  [self createTrackingArea];
}

- (void)mouseEntered:(NSEvent*)theEvent
{
  self.hovered = YES;
  [_delegate notificationRowHoverChanged:self];
}

- (void)mouseExited:(NSEvent*)theEvent
{
  self.hovered = NO;
  [_delegate notificationRowHoverChanged:self];
}

- (void)resetCursorRects
{
  NSCursor* cursor = [NSCursor pointingHandCursor];
  [self addCursorRect:self.bounds cursor:cursor];
}

@end
