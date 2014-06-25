//
//  InfinitMainCounterView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 15/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitMainCounterView.h"

@implementation InfinitMainCounterView
{
@private
  NSAttributedString* _num_str;
}

static NSDictionary* _attrs = nil;

- (void)setCount:(NSUInteger)count
{
  if (count == 0)
  {
    self.hidden = YES;
    return;
  }
  else
  {
    self.hidden = NO;
  }
  _count = count;

  if (_attrs == nil)
  {
    NSFont* font = [NSFont fontWithName:@"Montserrat" size:10.0];
    NSMutableParagraphStyle* para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    para.alignment = NSCenterTextAlignment;
    _attrs = [IAFunctions textStyleWithFont:font
                             paragraphStyle:para
                                     colour:IA_GREY_COLOUR(255)
                                     shadow:nil];
  }
  NSString* num;
  if (_count < 10)
    num = [NSString stringWithFormat:@"%ld", _count];
  else
    num = @"+";
  _num_str = [[NSAttributedString alloc] initWithString:num
                                             attributes:_attrs];
  [self setNeedsDisplay:YES];
}

- (void)setHighlighted:(BOOL)highlighted
{
  _highlighted = highlighted;
  [self setNeedsDisplay:YES];
}

//- Drawing ----------------------------------------------------------------------------------------

- (BOOL)isOpaque
{
  return NO;
}

- (void)drawRect:(NSRect)dirtyRect
{
  NSBezierPath* bg = [NSBezierPath bezierPathWithOvalInRect:self.bounds];

  if (_highlighted)
    [IA_RGB_COLOUR(0, 195, 192) set];
  else
    [IA_RGB_COLOUR(139, 139, 131) set];
  [bg fill];
  CGFloat x_pos = floor((NSWidth(self.bounds) - _num_str.size.width) / 2.0) + 1.0;
  CGFloat y_pos = floor((NSHeight(self.bounds) - _num_str.size.height) / 2.0) + 2.0;
  if (_count == 8)
    x_pos -= 1.0;
  NSPoint pt = NSMakePoint(x_pos, y_pos);
  [_num_str drawAtPoint:pt];
}

@end
