//
//  IAHoverButton.m
//  InfinitApplication
//
//  Created by Christopher Crone on 9/6/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAHoverButton.h"

@implementation IAHoverButton
{
@private
    NSTrackingArea* _tracking_area;
}

//- Initialisation ---------------------------------------------------------------------------------

@synthesize hand_cursor = _hand_cursor;
@synthesize hover_attrs = _hover_attrs;
@synthesize hover_image = _hover_image;
@synthesize normal_attrs = _normal_attrs;
@synthesize normal_image = _normal_image;

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
  if (_normal_image == nil)
    _normal_image = self.image;
}

- (void)dealloc
{
  _tracking_area = nil;
}

- (void)resetCursorRects
{
  [super resetCursorRects];

  if (!_hand_cursor)
    return;

  NSCursor* cursor = [NSCursor pointingHandCursor];
  [self addCursorRect:self.bounds cursor:cursor];
}

- (void)createTrackingArea
{
  _tracking_area = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                options:(NSTrackingMouseEnteredAndExited |
                                                         NSTrackingActiveAlways)
                                                  owner:self
                                               userInfo:nil];
  
  [self addTrackingArea:_tracking_area];
  
  NSPoint mouse_loc = self.window.mouseLocationOutsideOfEventStream;
  mouse_loc = [self convertPoint:mouse_loc fromView:nil];
  if (NSPointInRect(mouse_loc, self.bounds))
    [self mouseEntered:nil];
  else
    [self mouseExited:nil];
}

- (void)updateTrackingAreas
{
  [self removeTrackingArea:_tracking_area];
  [self createTrackingArea];
  [super updateTrackingAreas];
}

- (void)mouseEntered:(NSEvent*)theEvent
{
    NSString* title = self.attributedTitle.string;
    self.attributedTitle = [[NSAttributedString alloc] initWithString:title
                                                           attributes:_hover_attrs];
    self.image = _hover_image;
    [self setNeedsDisplay:YES];
}

- (void)mouseExited:(NSEvent*)theEvent
{
    NSString* title = self.attributedTitle.string;
    self.attributedTitle = [[NSAttributedString alloc] initWithString:title
                                                           attributes:_normal_attrs];
    self.image = _normal_image;
    [self setNeedsDisplay:YES];
}

//- General Functions ------------------------------------------------------------------------------

- (void)setNormalImage:(NSImage*)normal_image
{
  _normal_image = normal_image;
}

- (void)setHoverImage:(NSImage*)hover_image
{
  _hover_image = hover_image;
}

- (void)setNormalTextAttributes:(NSDictionary*)attrs
{
  _normal_attrs = attrs;
}

- (void)setHoverTextAttributes:(NSDictionary*)attrs
{
  _hover_attrs = attrs;
}

@end
