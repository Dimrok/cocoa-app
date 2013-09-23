//
//  IANotificationAvatarView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/21/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IANotificationAvatarView.h"

#import <QuartzCore/QuartzCore.h>

@implementation IANotificationAvatarView
{
@private
    CGFloat _badge_angle_size;
    CGFloat _start_angle;
    NSTrackingArea* _tracking_area;
    NSInteger _tracking_options;
    BOOL _mouse_over;
}

//- Initialisation ---------------------------------------------------------------------------------

@synthesize totalProgress = _total_progress;

- (id)initWithFrame:(NSRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        _badge_angle_size = 45.0;
        _total_progress = 0.0;
        _start_angle = 45.0 - (_badge_angle_size / 2.0);
        _mouse_over = NO;
        _tracking_options = (NSTrackingInVisibleRect |
                            NSTrackingActiveAlways |
                            NSTrackingMouseEnteredAndExited|
                            NSTrackingMouseMoved);
    }
    
    return self;
}

- (void)dealloc
{
    _tracking_area = nil;
}

//- Mouse Handling ---------------------------------------------------------------------------------

- (void)resetCursorRects
{
    [super resetCursorRects];
    if (_mode == AVATAR_VIEW_NORMAL)
        return;
    NSCursor* cursor = [NSCursor pointingHandCursor];
    [self addCursorRect:self.bounds cursor:cursor];
}

- (void)ensureTrackingArea
{
    if (_tracking_area == nil)
    {
        _tracking_area = [[NSTrackingArea alloc] initWithRect:NSZeroRect
                                                             options:_tracking_options
                                                               owner:self
                                                            userInfo:nil];
    }
}

- (void)updateTrackingAreas
{
    [super updateTrackingAreas];
    [self ensureTrackingArea];
    if (![self.trackingAreas containsObject:_tracking_area])
    {
        [self addTrackingArea:_tracking_area];
    }
}

//- Drawing ----------------------------------------------------------------------------------------

- (void)drawRect:(NSRect)dirtyRect
{
    NSRect avatar_frame = NSMakeRect((NSWidth(self.frame) - _avatar.size.width) / 2.0,
                                     (NSHeight(self.frame) - _avatar.size.height) / 2.0,
                                     _avatar.size.width,
                                     _avatar.size.height);
    [_avatar drawInRect:avatar_frame
               fromRect:NSZeroRect
              operation:NSCompositeSourceOver
               fraction:1.0];
    
    if (_total_progress > 0.0)
    {
        NSPoint centre = NSMakePoint(NSWidth(self.frame) / 2.0, NSHeight(self.frame) / 2.0);
        CGFloat radius = _avatar.size.width / 2.0 + 1.0;
        
        NSBezierPath* progress = [NSBezierPath bezierPath];
        CGFloat new_angle = _start_angle - _total_progress * (360.0 - _badge_angle_size);
        [progress appendBezierPathWithArcWithCenter:centre
                                             radius:radius
                                         startAngle:_start_angle
                                           endAngle:new_angle
                                          clockwise:YES];
        [IA_RGB_COLOUR(65.0, 165.0, 236.0) set];
        progress.lineWidth = 3.0;
        [progress stroke];
    }
    
    // This assumes that the border around the avatar image is 2px and the shadow is 1px
    CGFloat border = 3.0;
    NSRect avatar_image_frame = NSMakeRect(avatar_frame.origin.x + border,
                                           avatar_frame.origin.y + border,
                                           NSWidth(avatar_frame) - 2.0 * border,
                                           NSHeight(avatar_frame) - 2.0 * border);
    
    if (_mode == AVATAR_VIEW_ACCEPT_REJECT)
    {
        NSPoint centre = NSMakePoint(NSWidth(self.frame) / 2.0, NSHeight(self.frame) / 2.0);
        // Accept
        NSBezierPath* accept_mask = [NSBezierPath bezierPath];
        [accept_mask moveToPoint:NSMakePoint(centre.x - NSWidth(avatar_image_frame) / 2.0,
                                             centre.y)];
        [accept_mask appendBezierPathWithArcWithCenter:centre
                                                radius:(NSWidth(avatar_image_frame) / 2.0)
                                            startAngle:180.0
                                              endAngle:0.0
                                             clockwise:YES];
        [accept_mask closePath];
        [IA_RGBA_COLOUR(180.0, 219.0, 89.0, 0.9) set];
        [accept_mask fill];
        
        NSImage* accept_icon = [IAFunctions imageNamed:@"icon-accept"];
        NSRect accept_image_frame = NSMakeRect(centre.x - accept_icon.size.width / 2.0,
                                               centre.y + border + 1.0,
                                               accept_icon.size.width,
                                               accept_icon.size.height);
        [accept_icon drawInRect:accept_image_frame
                       fromRect:NSZeroRect
                      operation:NSCompositeSourceOver
                       fraction:1.0];
        
        
        
        // Reject
        NSBezierPath* reject_mask = [NSBezierPath bezierPath];
        [reject_mask moveToPoint:NSMakePoint(centre.x - NSWidth(avatar_image_frame) / 2.0,
                                             centre.y)];
        [reject_mask appendBezierPathWithArcWithCenter:centre
                                                radius:(NSWidth(avatar_image_frame) / 2.0)
                                            startAngle:180.0
                                              endAngle:0.0];
        [reject_mask closePath];
        [IA_RGBA_COLOUR(255.0, 61.0, 42.0, 0.82) set];
        [reject_mask fill];
        
        NSImage* cancel_icon = [IAFunctions imageNamed:@"icon-reject"];
        NSRect cancel_image_frame = NSMakeRect(centre.x - cancel_icon.size.width / 2.0,
                                               centre.y - NSHeight(avatar_image_frame) / 2.0 + border + 1.0,
                                               cancel_icon.size.width,
                                               cancel_icon.size.height);
        [cancel_icon drawInRect:cancel_image_frame
                       fromRect:NSZeroRect
                      operation:NSCompositeSourceOver
                       fraction:1.0];
    }
    
    if (_mode == AVATAR_VIEW_CANCEL && _mouse_over)
    {
        NSBezierPath* cancel_mask = [NSBezierPath bezierPathWithOvalInRect:avatar_image_frame];
        [IA_RGBA_COLOUR(255.0, 61.0, 42.0, 0.82) set];
        [cancel_mask fill];
        
        NSImage* cancel_icon = [IAFunctions imageNamed:@"icon-reject"];
        NSRect cancel_image_frame = NSMakeRect(NSWidth(avatar_image_frame) / 2.0 + border - 1.0,
                                               NSHeight(avatar_image_frame) / 2.0,
                                               cancel_icon.size.width,
                                               cancel_icon.size.height);
        [cancel_icon drawInRect:cancel_image_frame
                       fromRect:NSZeroRect
                      operation:NSCompositeSourceOver
                       fraction:1.0];
    }
}

//- Outside functions ------------------------------------------------------------------------------

- (void)setAvatar:(NSImage*)avatar
{
    _avatar = avatar;
    [self setNeedsDisplay:YES];
}

- (void)setDelegate:(id<IANotificationAvatarProtocol>)delegate
{
    _delegate = delegate;
}

- (void)setTotalProgress:(CGFloat)progress
{
    _total_progress = progress;
    [self setNeedsDisplay:YES];
}

- (void)setViewMode:(IANotificationAvatarMode)mode
{
    _mouse_over = NO;
    _mode = mode;
    [self setNeedsDisplay:YES];
}

//- Mouse Handling ---------------------------------------------------------------------------------

- (void)mouseEntered:(NSEvent*)theEvent
{
    _mouse_over = YES;
    [self setNeedsDisplay:YES];
}

- (void)mouseExited:(NSEvent*)theEvent
{
    _mouse_over = NO;
    [self setNeedsDisplay:YES];
}

- (void)mouseDown:(NSEvent*)theEvent
{
    // Determine button click based on where the click was on the avatar and the current mode
    NSPoint click_location = [self convertPoint:theEvent.locationInWindow fromView:nil];
    switch (_mode)
    {
        case AVATAR_VIEW_NORMAL:
            [_delegate avatarClicked:self];
            return;
            
        case AVATAR_VIEW_ACCEPT_REJECT:
            if (click_location.y > self.frame.size.height / 2.0)
                [_delegate avatarHadAcceptClicked:self];
            else if (click_location.y < self.frame.size.height / 2.0)
                [_delegate avatarHadRejectClicked:self];
            return;
        
        case AVATAR_VIEW_CANCEL:
            [_delegate avatarHadCancelClicked:self];
            return;
            
        default:
            return;
    }
}

//- Animation --------------------------------------------------------------------------------------

+ (id)defaultAnimationForKey:(NSString*)key
{
    if ([key isEqualToString:@"totalProgress"])
        return [CABasicAnimation animation];
    
    return [super defaultAnimationForKey:key];
}

@end
