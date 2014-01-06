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

@synthesize clicked = _clicked;
@synthesize hovered = _hovered;
@synthesize unread = _unread;

- (id)initWithFrame:(NSRect)frameRect
        andDelegate:(id<InfinitNotificationListRowProtocol>)delegate
{
    if (self = [super initWithFrame:frameRect])
    {
        _delegate = delegate;
    }
    return self;
}

- (void)dealloc
{
    _tracking_area = nil;
}

- (void)setClicked:(BOOL)clicked
{
    _clicked = clicked;
    [self setNeedsDisplay:YES];
}

- (void)setHovered:(BOOL)hovered
{
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
    if (self.hovered)
    {
        // Blue background
        NSRect blue_bg_frame = NSMakeRect(self.bounds.origin.x,
                                          self.bounds.origin.y + 2.0,
                                          NSWidth(self.bounds),
                                          NSHeight(self.bounds) - 2.0);
        [IA_RGB_COLOUR(239.0, 252.0, 255.0) set];
        NSRectFill(blue_bg_frame);
    }
    else if (self.unread || self.clicked)
    {
        // White background
        NSRect white_bg_frame = NSMakeRect(self.bounds.origin.x,
                                           self.bounds.origin.y + 2.0,
                                           NSWidth(self.bounds),
                                           NSHeight(self.bounds) - 2.0);
        [IA_GREY_COLOUR(255.0) set];
        NSRectFill(white_bg_frame);
    }
    else
    {
        // Grey background
        NSRect grey_bg_frame = NSMakeRect(self.bounds.origin.x,
                                          self.bounds.origin.y + 2.0,
                                          NSWidth(self.bounds),
                                          NSHeight(self.bounds) - 2.0);
        [IA_GREY_COLOUR(248.0) set];
        NSRectFill(grey_bg_frame);
    }
    
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

- (void)ensureTrackingArea
{
    if (_tracking_area == nil)
    {
        _tracking_area = [[NSTrackingArea alloc] initWithRect:NSZeroRect
                                                      options:(NSTrackingInVisibleRect |
                                                               NSTrackingActiveAlways |
                                                               NSTrackingMouseEnteredAndExited)
                                                        owner:self
                                                     userInfo:nil];
    }
}

- (void)updateTrackingAreas
{
    [super updateTrackingAreas];
    [self ensureTrackingArea];
    if (![[self trackingAreas] containsObject:_tracking_area])
    {
        [self addTrackingArea:_tracking_area];
    }
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

@end;
