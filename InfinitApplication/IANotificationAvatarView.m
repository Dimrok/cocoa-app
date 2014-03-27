//
//  IANotificationAvatarView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/21/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IANotificationAvatarView.h"

#import <QuartzCore/QuartzCore.h>

#import "InfinitMetricsManager.h"

@implementation IANotificationAvatarView
{
@private
    CGFloat _badge_angle_size;
    CGFloat _start_angle;
}

//- Initialisation ---------------------------------------------------------------------------------

@synthesize totalProgress = _total_progress;

- (id)initWithFrame:(NSRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        _badge_angle_size = 40.0;
        _total_progress = 0.0;
        _start_angle = 47.0 - (_badge_angle_size / 2.0);
    }
    
    return self;
}

- (BOOL)isOpaque
{
    return NO;
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
        CGFloat radius = _avatar.size.width / 2.0;
        
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
    if (progress > 1.0 || progress < 0.0)
        return;
    _total_progress = progress;
    [self setNeedsDisplay:YES];
}

//- Mouse Handling ---------------------------------------------------------------------------------

- (void)mouseDown:(NSEvent*)theEvent
{
    if (theEvent.clickCount > 1)
        return;
  
    [_delegate avatarClicked:self];
}

//- Animation --------------------------------------------------------------------------------------

+ (id)defaultAnimationForKey:(NSString*)key
{
    if ([key isEqualToString:@"totalProgress"])
        return [CABasicAnimation animation];
    
    return [super defaultAnimationForKey:key];
}

@end
