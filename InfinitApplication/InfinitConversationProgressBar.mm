//
//  InfinitConversationProgressBar.m
//  InfinitApplication
//
//  Created by Christopher Crone on 18/03/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitConversationProgressBar.h"

#import <QuartzCore/QuartzCore.h>

#import <algorithm>

namespace
{
  const NSTimeInterval kMinimumTimeInterval = std::numeric_limits<NSTimeInterval>::min();
}

//- Indeterminate Progress Bar ---------------------------------------------------------------------

@interface InfinitConversationBallAnimation : NSView

@property (nonatomic, readwrite) CGFloat pos_multiplier;

@end

@implementation InfinitConversationBallAnimation
{
@private
  NSRect _base_ball_rect;
  CGFloat _x_pos;
}

- (id)initWithFrame:(NSRect)frameRect
{
  if (self = [super initWithFrame:frameRect])
  {
    _x_pos = self.bounds.origin.x;
    _base_ball_rect = NSMakeRect(_x_pos, self.bounds.origin.y + 3.0, 6.0, 6.0);
  }
  return self;
}

- (BOOL)wantsUpdateLayer
{
  return NO;
}

- (void)drawRect:(NSRect)dirtyRect
{
  if (_pos_multiplier == 0.0)
    return;

  for (NSInteger i = 0; i < 4; i++)
  {
    NSRect ball_rect = _base_ball_rect;
    ball_rect.origin.x = self.bounds.origin.x + ([self func:_pos_multiplier ball:i] * NSWidth(self.bounds));
    NSBezierPath* ball = [NSBezierPath bezierPathWithOvalInRect:ball_rect];
    [IA_RGB_COLOUR(0, 214, 242) set];
    [ball fill];
  }
}

- (CGFloat)func:(CGFloat)x ball:(NSInteger)ball
{
  CGFloat x_offset = 0.17 * ball;
  CGFloat f = 50 * pow(x - 0.25 - x_offset, 3) + 0.5;
  return f;
}

- (void)setPos_multiplier:(CGFloat)pos_multiplier
{
  _pos_multiplier = pos_multiplier;
  if (_pos_multiplier > 0.0)
    [self setNeedsDisplay:YES];
}

+ (id)defaultAnimationForKey:(NSString*)key
{
  if ([key isEqualToString:@"pos_multiplier"])
    return [CABasicAnimation animation];
  
  return [super defaultAnimationForKey:key];
}

@end

//- Progress Bar -----------------------------------------------------------------------------------

@implementation InfinitConversationProgressBar
{
@private
  InfinitConversationBallAnimation* _ball_view;
  BOOL _animating;
}

//- Initialisation ---------------------------------------------------------------------------------

@synthesize doubleValue = _doubleValue;

- (id)initWithCoder:(NSCoder*)aDecoder
{
  if (self = [super initWithCoder:aDecoder])
  {
    _animating = NO;
    self.doubleValue = 0.0;
  }
  return self;
}

- (void)dealloc
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

//- Drawing ----------------------------------------------------------------------------------------

- (void)drawRect:(NSRect)dirtyRect
{
  if (_doubleValue > 0)
  {
    [IA_RGB_COLOUR(0, 214, 242) set];
    NSRect bar = NSMakeRect(self.bounds.origin.x, 5.0,
                            (NSWidth(self.bounds) / self.maxValue * _doubleValue), 2.0);
    NSRectFill(bar);
  }
}

- (BOOL)isFlipped
{
  return NO;
}

- (BOOL)wantsUpdateLayer
{
  return NO;
}

//- Properties -------------------------------------------------------------------------------------

- (void)setDoubleValue:(CGFloat)doubleValue
{
  if (doubleValue > self.maxValue || doubleValue < self.minValue)
    return;
  _doubleValue = doubleValue;
  [self setNeedsDisplay:YES];
}

- (double)doubleValue
{
  return _doubleValue;
}

- (void)setIndeterminate:(BOOL)flag
{
  if (_animating)
  {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    _animating = NO;
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
    {
      context.duration = kMinimumTimeInterval;
      [_ball_view setPos_multiplier:0.0];
    } completionHandler:nil];
  }
  if (flag)
  {
    _doubleValue = 0.0;
    _ball_view = nil;
    _ball_view = [[InfinitConversationBallAnimation alloc] initWithFrame:self.bounds];
    [self addSubview:_ball_view];
    [self runBallAnimation];
    [_ball_view setNeedsDisplay:YES];
  }
  else
  {
    _animating = YES;
    [_ball_view removeFromSuperview];
    _ball_view = nil;
    [self setNeedsDisplay:YES];
  }
  [super setIndeterminate:flag];
}

- (void)runBallAnimation
{
  _animating = YES;
  _ball_view.pos_multiplier = 0.0;

  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
   {
     context.duration = 3.0;
     [_ball_view.animator setPos_multiplier:1.0];
   }
                      completionHandler:^
   {
     _animating = NO;
     if (self.isIndeterminate)
       [self performSelector:@selector(runBallAnimation) withObject:nil afterDelay:3.5];
   }];
}

//- Animation --------------------------------------------------------------------------------------

+ (id)defaultAnimationForKey:(NSString*)key
{
  if ([key isEqualToString:@"doubleValue"])
    return [CABasicAnimation animation];

  return [super defaultAnimationForKey:key];
}

@end
