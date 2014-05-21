//
//  InfinitLinkClickCountView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 13/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitLinkClickCountView.h"

@implementation InfinitLinkClickCountView
{
@private
  NSAttributedString* _num_str;
}

static NSDictionary* _attrs = nil;

- (void)setCount:(NSNumber*)count
{
  _count = count;
  if (_attrs == nil)
  {
    NSFont* font = [NSFont fontWithName:@"Montserrat" size:12.0];
    NSMutableParagraphStyle* para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    para.alignment = NSCenterTextAlignment;
    _attrs = [IAFunctions textStyleWithFont:font
                             paragraphStyle:para
                                     colour:IA_GREY_COLOUR(255)
                                     shadow:nil];
  }
  _num_str = [[NSAttributedString alloc] initWithString:[IAFunctions numberInUnits:_count]
                                             attributes:_attrs];
  [self setNeedsDisplay:YES];
}

//- Drawing ----------------------------------------------------------------------------------------

- (BOOL)isOpaque
{
  return NO;
}

- (void)drawRect:(NSRect)dirtyRect
{
  CGFloat dim = NSHeight(self.bounds);
  NSRect rect;
  NSBezierPath* bg;
  if (_count.unsignedIntegerValue < 10)
  {
    rect = NSMakeRect(NSWidth(self.frame) - dim, 0.0, dim, dim);
    bg = [NSBezierPath bezierPathWithOvalInRect:rect];
  }
  else
  {
    CGFloat border = 7.0;
    CGFloat radius = floor(NSHeight(self.bounds) / 2.0);
    rect = NSMakeRect(NSWidth(self.frame) - (_num_str.size.width + 2.0 * border), 0.0,
                      _num_str.size.width + (2.0 * border), dim);
    bg = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:radius yRadius:radius];
  }

  [IA_GREY_COLOUR(204) set];
  [bg fill];
  NSPoint pt = NSMakePoint(rect.origin.x + 1.0 + floor((NSWidth(rect) - _num_str.size.width) / 2.0),
                           floor((NSHeight(rect) - _num_str.size.height) / 2.0) + 1.0);
  [_num_str drawAtPoint:pt];
}

@end
