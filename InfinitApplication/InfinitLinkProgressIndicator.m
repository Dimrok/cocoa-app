//
//  InfinitLinkProgressIndicator.m
//  InfinitApplication
//
//  Created by Christopher Crone on 13/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitLinkProgressIndicator.h"

#import <QuartzCore/QuartzCore.h>

@implementation InfinitLinkProgressIndicator

- (void)setDoubleValue:(double)doubleValue
{
  if (doubleValue < super.doubleValue)
    return;
  super.doubleValue = doubleValue;
  [self setNeedsDisplay:YES];
}

//- Drawing ----------------------------------------------------------------------------------------

- (BOOL)wantsUpdateLayer
{
  return NO;
}

- (BOOL)isFlipped
{
  return NO;
}

- (void)drawRect:(NSRect)dirtyRect
{
  NSRect rect = {
    .origin = NSMakePoint(0.0, 2.0),
    .size = NSMakeSize(NSWidth(self.bounds) * self.doubleValue, 2.0)
  };
  [IA_RGB_COLOUR(0, 214, 241) set];
  NSRectFill(rect);
}

//- Animation --------------------------------------------------------------------------------------

+ (id)defaultAnimationForKey:(NSString*)key
{
  if ([key isEqualToString:@"doubleValue"])
    return [CABasicAnimation animation];

  return [super defaultAnimationForKey:key];
}

@end
