//
//  IASearchResultsCellView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/4/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IASearchResultsCellView.h"

//- Selected Box View ------------------------------------------------------------------------------

@implementation InfinitSelectedBoxView

static NSImage* check_mark = nil;

- (void)drawRect:(NSRect)dirtyRect
{
  if (check_mark == nil)
    check_mark = [IAFunctions imageNamed:@"icon-contact-checked"];
  NSRect circle_bounds = {
    .origin = NSMakePoint(1.0, 1.0),
    .size = NSMakeSize(NSWidth(self.bounds) - 2.0, NSHeight(self.bounds) - 2.0)
  };

  NSBezierPath* circle = [NSBezierPath bezierPathWithOvalInRect:circle_bounds];
  if (_hover && !_selected)
  {
    [IA_RGB_COLOUR(0, 255, 0) set];
    [circle stroke];
  }
  else
  {
    [IA_RGB_COLOUR(0, 195, 192) set];
    if (_selected)
    {
      [circle fill];
      NSPoint point = NSMakePoint((NSWidth(self.bounds) / 2.0) - (check_mark.size.width / 2.0) + 1.0,
                                  (NSHeight(self.bounds) / 2.0) - (check_mark.size.height / 2.0) - 1.0);
      [check_mark drawAtPoint:point
                    fromRect:NSZeroRect
                   operation:NSCompositeSourceOver
                    fraction:1.0];
    }
    else
    {
      [circle stroke];
    }
  }
}

- (void)setSelected:(BOOL)selected
{
  _selected = selected;
  [self setNeedsDisplay:YES];
}

- (void)setHover:(BOOL)hover
{
  _hover = hover;
  [self setNeedsDisplay:YES];
}

@end

//- Set Cell Values --------------------------------------------------------------------------------

@implementation IASearchResultsCellView
{
  BOOL _is_favourite;
  id<IASearchResultsCellProtocol> _delegate;

  NSTrackingArea* _tracking_area;
}

- (void)prepareForReuse
{
  self.hover = NO;
  self.selected = NO;
  [self removeTrackingArea:_tracking_area];
  [super prepareForReuse];
}

- (void)dealloc
{
  _tracking_area = nil;
}

- (void)setDelegate:(id<IASearchResultsCellProtocol>)delegate
{
  _delegate = delegate;
}

- (void)setUserFullname:(NSString*)fullname
{
  NSFont* name_font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica"
                                                                 traits:NSUnboldFontMask
                                                                 weight:0
                                                                   size:12.0];
  NSDictionary* style = [IAFunctions textStyleWithFont:name_font
                                        paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                                colour:IA_RGB_COLOUR(37.0, 47.0, 51.0)
                                                shadow:nil];
  NSAttributedString* fullname_str = [[NSAttributedString alloc] initWithString:fullname
                                                                     attributes:style];
  self.result_fullname.attributedStringValue = fullname_str;
}

- (void)setUserEmail:(NSString*)email
{
  NSFont* email_font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica"
                                                                  traits:NSUnboldFontMask
                                                                  weight:0
                                                                    size:11.0];
  NSDictionary* style = [IAFunctions textStyleWithFont:email_font
                                        paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                                colour:IA_GREY_COLOUR(196.0)
                                                shadow:nil];
  NSAttributedString* email_str = [[NSAttributedString alloc] initWithString:email
                                                                  attributes:style];
  self.result_email.attributedStringValue = email_str;
}

- (void)setUserHandle:(NSString*)handle
{
  NSFont* handle_font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica"
                                                                   traits:NSUnboldFontMask
                                                                   weight:0
                                                                     size:11.0];
  NSDictionary* style = [IAFunctions textStyleWithFont:handle_font
                                        paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                                colour:IA_GREY_COLOUR(196.0)
                                                shadow:nil];
  NSAttributedString* handle_str = [[NSAttributedString alloc] initWithString:handle
                                                                   attributes:style];
  self.result_handle.attributedStringValue = handle_str;
}

- (void)setUserAvatar:(NSImage*)image
{
  self.result_avatar.image = image;
}

- (void)setUserFavourite:(BOOL)favourite
{
  _is_favourite = favourite;
  if (favourite)
  {
    self.result_star.image = [IAFunctions imageNamed:@"icon-star-selected"];
    [self.result_star setToolTip:NSLocalizedString(@"Remove user as favourite",
                                                   @"remove user as favourite")];
  }
  else
  {
    self.result_star.image = [IAFunctions imageNamed:@"icon-star"];
    [self.result_star setToolTip:NSLocalizedString(@"Add user as favourite",
                                                   @"add user as favourite")];
  }
}

//- Mouse Handling ---------------------------------------------------------------------------------

- (void)updateTrackingAreas
{
  [self removeTrackingArea:_tracking_area];
  [self createTrackingArea];
  [super updateTrackingAreas];
}

- (void)createTrackingArea
{
  _tracking_area = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                options:(NSTrackingMouseEnteredAndExited |
                                                         NSTrackingActiveAlways)
                                                  owner:self
                                               userInfo:nil];

  [self addTrackingArea:_tracking_area];
}

- (void)mouseEntered:(NSEvent*)theEvent
{
  [self setExternalHover:YES];
}

- (void)mouseExited:(NSEvent*)theEvent
{
  [self setExternalHover:NO];
}

- (void)mouseDown:(NSEvent*)theEvent
{
  [self setExternalSelected:!_selected];
}

- (void)setExternalHover:(BOOL)hover
{
  [self setHover:hover];
  [_delegate searchResultCell:self gotHover:hover];
}

- (void)setHover:(BOOL)hover
{
  _hover = hover;
  self.result_selected.hover = hover;
  if (!_is_favourite)
    self.result_star.hidden = !hover;
  [self setNeedsDisplay:YES];
}

- (void)setExternalSelected:(BOOL)selected
{
  [self setSelected:selected];
  [_delegate searchResultCell:self gotSelected:selected];
}

- (void)setSelected:(BOOL)selected
{
  _selected = selected;
  self.result_selected.selected = selected;
  [self setNeedsDisplay:YES];
}

//- Drawing ----------------------------------------------------------------------------------------

- (BOOL)isOpaque
{
  return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
  // Background
  if (_hover)
    [IA_RGB_COLOUR(242, 253, 255) set];
  else
    [IA_GREY_COLOUR(255) set];
  NSRectFill(self.bounds);

  // Dark line
  NSRect dark_rect = NSMakeRect(45.0,
                                0.0,
                                NSWidth(self.bounds) - 65.0,
                                1.0);
  NSBezierPath* dark_line = [NSBezierPath bezierPathWithRect:dark_rect];
  if (_hover)
    [IA_RGB_COLOUR(50, 245, 242) set];
  else
    [IA_GREY_COLOUR(244) set];
  [dark_line fill];
}

//- Cell Actions -----------------------------------------------------------------------------------

- (IBAction)starClicked:(NSButton*)sender
{
  if (sender != self.result_star)
    return;
  if (_is_favourite)
  {
    _is_favourite = NO;
    self.result_star.image = [IAFunctions imageNamed:@"icon-star"];
    [_delegate searchResultCellWantsRemoveFavourite:self];
    [self.result_star setToolTip:NSLocalizedString(@"Add user as favourite",
                                                   @"add user as favourite")];
  }
  else
  {
    _is_favourite = YES;
    self.result_star.image = [IAFunctions imageNamed:@"icon-star-selected"];
    [_delegate searchResultCellWantsAddFavourite:self];
    [self.result_star setToolTip:NSLocalizedString(@"Remove user as favourite",
                                                   @"remove user as favourite")];
  }
}

@end
