//
//  InfinitAvatarView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 12/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitAvatarView.h"

#import <QuartzCore/QuartzCore.h>

@implementation InfinitAvatarView
{
@private
  CGFloat _badge_angle_size;
  CGFloat _start_angle;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithFrame:(NSRect)frame
{
  if (self = [super initWithFrame:frame])
  {
    _badge_angle_size = 40.0;
    _progress = 0.0;
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
  NSRect avatar_frame = NSMakeRect(floor((NSWidth(self.bounds) - _avatar.size.width) / 2.0),
                                   floor((NSHeight(self.bounds) - _avatar.size.height) / 2.0),
                                   _avatar.size.width,
                                   _avatar.size.height);
  [_avatar drawInRect:avatar_frame
             fromRect:NSZeroRect
            operation:NSCompositeSourceOver
             fraction:1.0];

  if (_progress > 0.0)
  {
    NSPoint centre = NSMakePoint(floor(NSWidth(self.frame) / 2.0),
                                 floor(NSHeight(self.frame) / 2.0));
    CGFloat radius = floor(_avatar.size.width / 2.0) + 1.0;

    NSBezierPath* progress = [NSBezierPath bezierPath];
    CGFloat new_angle = _start_angle - _progress * (360.0 - _badge_angle_size);
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

- (void)setProgress:(CGFloat)progress
{
  if (progress > 1.0 || progress < 0.0)
    return;
  _progress = progress;
  [self setNeedsDisplay:YES];
}

//- Animation --------------------------------------------------------------------------------------

+ (id)defaultAnimationForKey:(NSString*)key
{
  if ([key isEqualToString:@"progress"])
    return [CABasicAnimation animation];

  return [super defaultAnimationForKey:key];
}

@end
