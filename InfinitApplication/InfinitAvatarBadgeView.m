//
//  InfinitAvatarBadgeView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 12/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitAvatarBadgeView.h"

@implementation InfinitAvatarBadgeView
{
@private
  NSAttributedString* _num_str;
}

static NSDictionary* _num_attrs = nil;

- (id)initWithFrame:(NSRect)frameRect
{
  if (self = [super initWithFrame:frameRect])
  {
  }
  return self;
}

- (BOOL)isOpaque
{
  return NO;
}

- (void)drawRect:(NSRect)dirtyRect
{
  if (_count > 0)
  {
    NSBezierPath* circle = [NSBezierPath bezierPathWithOvalInRect:self.bounds];
    [IA_RGB_COLOUR(0, 174, 242) set];
    [circle fill];
    NSPoint pt = NSMakePoint(floor((NSWidth(self.bounds) - _num_str.size.width) / 2.0 + 1.0),
                             floor((NSHeight(self.bounds) - _num_str.size.height) / 2.0 + 1.0));
    [_num_str drawAtPoint:pt];
  }
}

//- General Functions ------------------------------------------------------------------------------

- (void)setCount:(NSUInteger)count
{
  if (_count == count && _num_str != nil)
    return;
  else
    _count = count;

  if (_num_attrs == nil)
  {
    NSFont* font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica"
                                                              traits:NSUnboldFontMask
                                                              weight:5
                                                                size:12.0];
    _num_attrs = [IAFunctions textStyleWithFont:font
                                 paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                         colour:IA_GREY_COLOUR(255.0)
                                         shadow:nil];
  }

  if (_count < 10)
  {
    _num_str = [[NSAttributedString alloc]
               initWithString:[[NSNumber numberWithUnsignedInteger:_count] stringValue]
               attributes:_num_attrs];
  }
  else
  {
    _num_str = [[NSAttributedString alloc] initWithString:@"+"
                                               attributes:_num_attrs];
  }

  [self setNeedsDisplay:YES];
}

@end
