//
//  InfinitConversationFileCellView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 24/03/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitConversationFileCellView.h"

@implementation InfinitConversationFileCellView
{
@private
  NSDictionary* _attrs_normal;
  NSDictionary* _attrs_hover;
  NSImageView* _file_icon;
  NSTrackingArea* _tracking_area;
  BOOL _hover;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithFrame:(NSRect)frame
             onLeft:(BOOL)on_left
{
  if (self = [super initWithFrame:frame])
  {
    NSFont* font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica"
                                                              traits:NSUnboldFontMask
                                                              weight:0
                                                                size:11.5];
    NSMutableParagraphStyle* para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    para.lineBreakMode = NSLineBreakByTruncatingMiddle;
    _file_name = [[NSTextField alloc] initWithFrame:NSZeroRect];
    _file_icon = [[NSImageView alloc] initWithFrame:NSZeroRect];
    if (on_left)
    {
      _file_name.frame = NSMakeRect(45.0, 9.0, 195.0, 15.0);
      _file_icon.frame = NSMakeRect(22.0, 9.0, 16.0, 16.0);
    }
    else
    {
      para.alignment = NSRightTextAlignment;
      _file_name.frame = NSMakeRect(18.0, 9.0, 195.0, 15.0);
      _file_icon.frame = NSMakeRect(220.0, 9.0, 16.0, 16.0);
    }
    _attrs_normal = [IAFunctions textStyleWithFont:font
                                    paragraphStyle:para
                                            colour:IA_GREY_COLOUR(193.0)
                                            shadow:nil];
    _attrs_hover = [IAFunctions textStyleWithFont:font
                                   paragraphStyle:para
                                           colour:IA_RGB_COLOUR(102.0, 174.0, 211.0)
                                           shadow:nil];
    [_file_name.cell setBordered:NO];
    [_file_name.cell setDrawsBackground:NO];
    [_file_name.cell setLineBreakMode:NSLineBreakByTruncatingMiddle];
    [_file_name.cell setTruncatesLastVisibleLine:YES];
    [_file_name.cell setFocusRingType:NSFocusRingTypeNone];
    [_file_name.cell setEditable:NO];
    [self addSubview:_file_name];
    [self addSubview:_file_icon];
    _hover = NO;
  }
  return self;
}

- (void)dealloc
{
  _tracking_area = nil;
}

//- Mouse Handling ---------------------------------------------------------------------------------

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
  if (!self.clickable)
    return;
  
  _hover = YES;
  _file_name.attributedStringValue =
    [[NSAttributedString alloc] initWithString:_file_name.stringValue attributes:_attrs_hover];
  [self setNeedsDisplay:YES];
}

- (void)mouseExited:(NSEvent*)theEvent
{
  if (!self.clickable)
    return;
  
  _hover = NO;
  _file_name.attributedStringValue =
    [[NSAttributedString alloc] initWithString:_file_name.stringValue attributes:_attrs_normal];
  [self setNeedsDisplay:YES];
}

//- Drawing ----------------------------------------------------------------------------------------

- (void)drawRect:(NSRect)dirtyRect
{
  if (_hover)
    [IA_GREY_COLOUR(255.0) set];
  else
    [IA_GREY_COLOUR(248.0) set];

  NSRectFill(self.bounds);
  NSBezierPath* border = [NSBezierPath bezierPathWithRect:self.bounds];
  [IA_GREY_COLOUR(220.0) set];
  [border stroke];
  NSRect line_rect = NSMakeRect(1.0, NSHeight(self.bounds) - 1.0, NSWidth(self.bounds) - 2.0, 1.0);
  NSBezierPath* line = [NSBezierPath bezierPathWithRect:line_rect];
  [IA_GREY_COLOUR(255.0) set];
  [line fill];
}

- (void)setFileName:(NSString*)name
{
  _file_name.attributedStringValue =
    [[NSAttributedString alloc] initWithString:name attributes:_attrs_normal];
  _file_icon.image =
    [[NSWorkspace sharedWorkspace] iconForFileType:[_file_name.stringValue pathExtension]];
  [self setNeedsDisplay:YES];
}

@end
