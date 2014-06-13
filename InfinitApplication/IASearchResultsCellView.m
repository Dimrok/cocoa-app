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
    [IA_RGB_COLOUR(43, 190, 189) set];
    [circle stroke];
  }
  else
  {
    if (_selected)
    {
      [IA_RGB_COLOUR(43, 190, 189) set];
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
      [IA_GREY_COLOUR(214) set];
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
  BOOL _infinit_user;
  // WORKAROUND: 10.7 doesn't allow weak references to certain classes (like NSViewController)
  id<IASearchResultsCellProtocol> _delegate;

  NSTrackingArea* _tracking_area;

  NSAttributedString* _fullname_norm;
  NSAttributedString* _fullname_selected;
}

static NSDictionary* _fullname_style = nil;
static NSDictionary* _fullname_selected_style = nil;
static NSDictionary* _domain_style = nil;

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
             withDomain:(NSString*)domain
{
  if (_fullname_style == nil)
  {
    NSFont* name_font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica"
                                                                   traits:NSUnboldFontMask
                                                                   weight:0
                                                                     size:12.0];
    _fullname_style = [IAFunctions textStyleWithFont:name_font
                                      paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                              colour:IA_RGB_COLOUR(37, 47, 51)
                                              shadow:nil];
    _fullname_selected_style = [IAFunctions textStyleWithFont:name_font
                                               paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                                       colour:IA_RGB_COLOUR(43, 190, 189)
                                                       shadow:nil];
    NSFont* domain_font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica"
                                                                     traits:NSUnboldFontMask
                                                                     weight:0
                                                                       size:10.0];
    _domain_style = [IAFunctions textStyleWithFont:domain_font
                                    paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                            colour:IA_GREY_COLOUR(190)
                                            shadow:nil];
  }
  NSMutableAttributedString* fullname_norm_str =
    [[NSMutableAttributedString alloc] initWithString:fullname attributes:_fullname_style];
  NSMutableAttributedString* fullname_selected_str =
    [[NSMutableAttributedString alloc] initWithString:fullname attributes:_fullname_selected_style];
  if (domain.length > 0)
  {
    _infinit_user = NO;
    self.result_star.hidden = YES;
    NSAttributedString* domain_str =
      [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"  (%@)", domain]
                                      attributes:_domain_style];
    [fullname_norm_str appendAttributedString:domain_str];
    [fullname_selected_str appendAttributedString:domain_str];
  }
  else
  {
    _infinit_user = YES;
    self.result_star.hidden = NO;
  }

  self.result_fullname.attributedStringValue = fullname_norm_str;
  _fullname_norm = fullname_norm_str;
  _fullname_selected = fullname_selected_str;
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
    self.result_star.hidden = NO;
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
  if (_infinit_user && !_is_favourite)
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
  if (selected)
    self.result_fullname.attributedStringValue = _fullname_selected;
  else
    self.result_fullname.attributedStringValue = _fullname_norm;
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
  [IA_GREY_COLOUR(255) set];
  NSRectFill(self.bounds);

  // Dark line
  NSRect dark_rect = NSMakeRect(45.0,
                                0.0,
                                NSWidth(self.bounds) - 65.0,
                                1.0);
  NSBezierPath* dark_line = [NSBezierPath bezierPathWithRect:dark_rect];
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
