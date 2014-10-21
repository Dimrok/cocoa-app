//
//  IASearchResultsCellView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/4/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IASearchResultsCellView.h"

//- Set Cell Values --------------------------------------------------------------------------------

@implementation IASearchResultsCellView
{
  BOOL _infinit_user;
  // WORKAROUND: 10.7 doesn't allow weak references to certain classes (like NSViewController)
  __unsafe_unretained id<IASearchResultsCellProtocol> _delegate;

  NSTrackingArea* _tracking_area;

  NSAttributedString* _fullname_norm;
  NSAttributedString* _fullname_selected;
}

static NSDictionary* _fullname_style = nil;
static NSDictionary* _email_style = nil;

- (void)prepareForReuse
{
  self.hover = NO;
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
             withEmail:(NSString *)email
{
  if (_fullname_style == nil)
  {
    NSFont* name_font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica Neue"
                                                                   traits:NSUnboldFontMask
                                                                   weight:3
                                                                     size:12.0];
    _fullname_style = [IAFunctions textStyleWithFont:name_font
                                      paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                              colour:IA_RGB_COLOUR(37, 47, 51)
                                              shadow:nil];
    NSFont* email_font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica Neue"
                                                                    traits:NSUnboldFontMask
                                                                    weight:2
                                                                      size:11.0];
    _email_style = [IAFunctions textStyleWithFont:email_font
                                   paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                           colour:IA_GREY_COLOUR(160)
                                           shadow:nil];
  }
  NSMutableAttributedString* fullname_norm_str =
    [[NSMutableAttributedString alloc] initWithString:fullname attributes:_fullname_style];
  if (email.length > 0)
  {
    _infinit_user = NO;
    NSAttributedString* email_str =
      [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"  (%@)", email]
                                      attributes:_email_style];
    [fullname_norm_str appendAttributedString:email_str];
  }
  else
  {
    _infinit_user = YES;
  }

  self.result_fullname.attributedStringValue = fullname_norm_str;
  _fullname_norm = fullname_norm_str;
}

- (void)setUserAvatar:(NSImage*)image
{
  self.result_avatar.image = image;
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
  _hover = YES;
  [self setExternalHover:YES];
}

- (void)mouseExited:(NSEvent*)theEvent
{
  _hover = NO;
  [self setExternalHover:NO];
}

- (void)mouseDown:(NSEvent*)theEvent
{
  if (theEvent.clickCount == 1)
    [_delegate searchResultCellGotSelected:self];
}

- (void)setExternalHover:(BOOL)hover
{
  [self setHover:hover];
  [_delegate searchResultCell:self gotHover:hover];
}

- (void)setHover:(BOOL)hover
{
  _hover = hover;
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
  NSRect dark_rect = NSMakeRect(50.0,
                                0.0,
                                NSWidth(self.bounds) - 70.0,
                                1.0);
  NSBezierPath* dark_line = [NSBezierPath bezierPathWithRect:dark_rect];
  [IA_GREY_COLOUR(244) set];
  [dark_line fill];

  if (_hover)
  {
    NSRect hover = NSMakeRect(0.0, 0.0, NSWidth(self.bounds), NSHeight(self.bounds));
    [IA_RGB_COLOUR(240, 252, 251) set];
    NSRectFill(hover);
  }
}

@end
