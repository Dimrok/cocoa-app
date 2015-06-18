//
//  IAHoverButton.m
//  InfinitApplication
//
//  Created by Christopher Crone on 9/6/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAHoverButton.h"

@interface IAHoverButton ()

@property (nonatomic, readonly) NSTrackingArea* tracking_area;
@property (nonatomic, readonly) NSAttributedString* hover_attr_str;
@property (nonatomic, readonly) NSAttributedString* normal_attr_str;

@end

@implementation IAHoverButton

#pragma mark - Init

- (id)initWithCoder:(NSCoder*)aDecoder
{
  if (self = [super initWithCoder:aDecoder])
  {
    _normal_attrs = [IAFunctions textStyleWithFont:[NSFont systemFontOfSize:11.0]
                                    paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                            colour:IA_RGB_COLOUR(103.0, 181.0, 214.0)
                                            shadow:nil];
    _hover_attrs = [IAFunctions textStyleWithFont:[NSFont systemFontOfSize:11.0]
                                   paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                           colour:IA_RGB_COLOUR(11.0, 117.0, 162)
                                           shadow:nil];
    _hand_cursor = YES;
    _normal_image = nil;
  }
  return self;
}

- (void)awakeFromNib
{
  [self setFocusRingType:NSFocusRingTypeNone];
  if (self.normal_image == nil)
    self.normal_image = self.image;
}

- (void)dealloc
{
  if (self.tracking_area)
  {
    for (NSTrackingArea* tracking_area in self.trackingAreas)
      [self removeTrackingArea:tracking_area];
    _tracking_area = nil;
  }
}

#pragma mark - Mouse Handling

- (void)resetCursorRects
{
  [super resetCursorRects];
  NSCursor* cursor;
  if (self.hand_cursor)
    cursor = [NSCursor pointingHandCursor];
  else
    cursor = [NSCursor arrowCursor];
  [self addCursorRect:self.bounds cursor:cursor];
}

- (void)createTrackingArea
{
  _tracking_area = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                options:(NSTrackingMouseEnteredAndExited |
                                                         NSTrackingActiveAlways)
                                                  owner:self
                                               userInfo:nil];
  [self addTrackingArea:self.tracking_area];
  NSPoint mouse_loc = self.window.mouseLocationOutsideOfEventStream;
  mouse_loc = [self convertPoint:mouse_loc fromView:nil];
  if (NSPointInRect(mouse_loc, self.bounds))
    [self mouseEntered:nil];
  else
    [self mouseExited:nil];
}

- (void)updateTrackingAreas
{
  [self removeTrackingArea:self.tracking_area];
  [self createTrackingArea];
  [super updateTrackingAreas];
}

- (void)mouseEntered:(NSEvent*)theEvent
{
  if (!self.hover_attr_str)
  {
    _hover_attr_str = [[NSAttributedString alloc] initWithString:self.attributedTitle.string
                                                      attributes:_hover_attrs];
  }
  self.attributedTitle = self.hover_attr_str;
  self.image = self.hover_image;
  [self setNeedsDisplay:YES];
}

- (void)mouseExited:(NSEvent*)theEvent
{
  if (!self.normal_attr_str)
  {
    _normal_attr_str = [[NSAttributedString alloc] initWithString:self.attributedTitle.string
                                                       attributes:_normal_attrs];
  }
  self.attributedTitle = self.normal_attr_str;
  self.image = self.normal_image;
  [self setNeedsDisplay:YES];
}

#pragma mark - External

- (void)setNormal_image:(NSImage*)normal_image
{
  _normal_image = normal_image;
}

- (void)setHover_image:(NSImage*)hover_image
{
  _hover_image = hover_image;
}

- (void)setNormal_attrs:(NSDictionary*)normal_attrs
{
  _normal_attrs = normal_attrs;
}

- (void)setHover_attrs:(NSDictionary*)hover_attrs
{
  _hover_attrs = hover_attrs;
}

@end
