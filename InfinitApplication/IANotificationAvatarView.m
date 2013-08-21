//
//  IANotificationAvatarView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/21/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IANotificationAvatarView.h"

@implementation IANotificationAvatarView
{
@private
    CGFloat _start_angle;
    NSTrackingArea* _tracking_area;
}

@synthesize avatar = _avatar;
@synthesize total_progress = _total_progress;

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithFrame:(NSRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        _total_progress = 0.0;
        _start_angle = 45.0;
    }
    
    return self;
}

- (void)dealloc
{
    _tracking_area = nil;
}

//- Mouse Handling ---------------------------------------------------------------------------------

- (void)ensureTrackingArea
{
    if (_tracking_area == nil)
    {
        _tracking_area = [[NSTrackingArea alloc] initWithRect:NSZeroRect
                                                      options:(NSTrackingInVisibleRect |
                                                               NSTrackingActiveAlways |
                                                               NSTrackingMouseEnteredAndExited)
                                                        owner:(NSTableCellView*)self.superview
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

//- Drawing ----------------------------------------------------------------------------------------

- (void)drawRect:(NSRect)dirtyRect
{
    NSRect avatar_frame = NSMakeRect((self.frame.size.width - _avatar.size.width) / 2.0,
                                     (self.frame.size.height - _avatar.size.height) / 2.0,
                                     _avatar.size.width,
                                     _avatar.size.height);
    [_avatar drawInRect:avatar_frame
               fromRect:NSZeroRect
              operation:NSCompositeSourceOver
               fraction:1.0];
    
    if (_total_progress > 0.0)
    {
        NSPoint centre = NSMakePoint(self.frame.size.width / 2.0, self.frame.size.height / 2.0);
        CGFloat radius = _avatar.size.width / 2.0 + 1.0;
        
        NSBezierPath* progress = [NSBezierPath bezierPath];
        [progress moveToPoint:NSMakePoint(centre.x + radius * cos(_start_angle),
                                          centre.y + radius * sin(_start_angle))];
        [progress appendBezierPathWithArcWithCenter:centre
                                             radius:radius
                                         startAngle:_start_angle
                                           endAngle:(_start_angle - _total_progress * 360)
                                          clockwise:YES];
        [IA_RGB_COLOUR(65.0, 165.0, 236.0) set];
        progress.lineWidth = 3.0;
        [progress stroke];
    }
    
}

//- Outside functions ------------------------------------------------------------------------------

- (void)setAvatar:(NSImage*)avatar
{
    _avatar = avatar;
    [self setNeedsDisplay:YES];
}


- (void)setTotalProgress:(CGFloat)progress
{
    _total_progress = progress;
    [self setNeedsDisplay:YES];
}

@end
