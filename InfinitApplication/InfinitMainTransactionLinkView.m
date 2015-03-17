//
//  InfinitMainTransactionLinkView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 16/03/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitMainTransactionLinkView.h"

#import <QuartzCore/QuartzCore.h>

@implementation InfinitMainTransactionLinkView
{
@private
  // WORKAROUND: 10.7 doesn't allow weak references to certain classes (like NSViewController)
  __unsafe_unretained id<InfinitMainTransactionLinkProtocol> _delegate;
  NSTrackingArea* _tracking_area;

  NSAttributedString* _link_norm_str;
  NSAttributedString* _link_hover_str;
  NSAttributedString* _link_high_str;

  NSAttributedString* _transaction_norm_str;
  NSAttributedString* _transaction_hover_str;
  NSAttributedString* _transaction_high_str;

  BOOL _hover;
}

- (void)setupViewForPeopleView:(BOOL)flag
{
  NSFont* font = [NSFont fontWithName:@"Montserrat" size:11.0];
  NSMutableParagraphStyle* para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
  para.alignment = NSCenterTextAlignment;
  NSDictionary* norm_attrs = [IAFunctions textStyleWithFont:font
                                             paragraphStyle:para
                                                     colour:IA_RGB_COLOUR(139, 139, 131)
                                                     shadow:nil];
  NSDictionary* high_attrs = [IAFunctions textStyleWithFont:font
                                             paragraphStyle:para
                                                     colour:IA_RGB_COLOUR(0, 195, 192)
                                                     shadow:nil];
  NSDictionary* hover_attrs = [IAFunctions textStyleWithFont:font
                                              paragraphStyle:para
                                                      colour:IA_RGB_COLOUR(81, 81, 73)
                                                      shadow:nil];
  NSString* link_str = NSLocalizedString(@"LINKS", nil);
  NSString* transaction_str = NSLocalizedString(@"PEOPLE", nil);

  _link_norm_str = [[NSAttributedString alloc] initWithString:link_str attributes:norm_attrs];
  _link_hover_str = [[NSAttributedString alloc] initWithString:link_str attributes:hover_attrs];
  _link_high_str = [[NSAttributedString alloc] initWithString:link_str attributes:high_attrs];

  _transaction_norm_str = [[NSAttributedString alloc] initWithString:transaction_str
                                                          attributes:norm_attrs];
  _transaction_hover_str = [[NSAttributedString alloc] initWithString:transaction_str
                                                           attributes:hover_attrs];
  _transaction_high_str = [[NSAttributedString alloc] initWithString:transaction_str
                                                          attributes:high_attrs];
  if (flag)
  {
    self.transaction_text.attributedStringValue = _transaction_high_str;
    self.link_text.attributedStringValue = _link_norm_str;
    self.transaction_counter.highlighted = YES;
    self.link_counter.highlighted = NO;
    _mode = INFINIT_MAIN_VIEW_TRANSACTION_MODE;
    _animate_mode = 0.0;
  }
  else
  {
    self.transaction_text.attributedStringValue = _transaction_norm_str;
    self.link_text.attributedStringValue = _link_high_str;
    self.transaction_counter.highlighted = NO;
    self.link_counter.highlighted = YES;
    _mode = INFINIT_MAIN_VIEW_LINK_MODE;
    _animate_mode = 1.0;
  }
}

- (void)setDelegate:(id<InfinitMainTransactionLinkProtocol>)delegate
{
  _delegate = delegate;
}

- (void)setLinkCount:(NSUInteger)count
{
  self.link_counter.count = count;
}

- (void)setTransactionCount:(NSUInteger)count
{
  self.transaction_counter.count = count;
}

- (BOOL)isOpaque
{
  return NO;
}

- (void)dealloc
{
  _tracking_area = nil;
}

- (void)setAnimate_mode:(CGFloat)animate_mode
{
  _animate_mode = animate_mode;
  [self setNeedsDisplay:YES];
}

- (void)setMode:(InfinitTransactionLinkMode)mode
{
  if (_mode == mode)
    return;
  _mode = mode;
  CGFloat val;
  if (_mode == INFINIT_MAIN_VIEW_TRANSACTION_MODE)
  {
    self.transaction_text.attributedStringValue = _transaction_high_str;
    self.link_text.attributedStringValue = _link_norm_str;
    self.link_counter.highlighted = NO;
    self.transaction_counter.highlighted = YES;
    val = 0.0;
  }
  else
  {
    self.transaction_text.attributedStringValue = _transaction_norm_str;
    self.link_text.attributedStringValue = _link_high_str;
    self.link_counter.highlighted = YES;
    self.transaction_counter.highlighted = NO;
    val = 1.0;
  }

  [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context)
   {
     context.duration = 0.2;
     context.timingFunction =
       [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
     [self.animator setAnimate_mode:val];
   }
                      completionHandler:^
   {
     _animate_mode = val;
   }];
}

//- Animation --------------------------------------------------------------------------------------

+ (id)defaultAnimationForKey:(NSString*)key
{
  if ([key isEqualToString:@"animate_mode"])
    return [CABasicAnimation animation];

  return [super defaultAnimationForKey:key];
}

//- Mouse Handling ---------------------------------------------------------------------------------

- (void)resetCursorRects
{
  [super resetCursorRects];
  NSCursor* cursor = [NSCursor pointingHandCursor];
  [self addCursorRect:self.bounds cursor:cursor];
}


- (void)createTrackingArea
{
  _tracking_area = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                options:(NSTrackingMouseEnteredAndExited |
                                                         NSTrackingMouseMoved |
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

- (void)mouseExited:(NSEvent*)theEvent
{
  _hover = NO;
  if (_mode == INFINIT_MAIN_VIEW_TRANSACTION_MODE)
  {
    self.transaction_text.attributedStringValue = _transaction_high_str;
    self.link_text.attributedStringValue = _link_norm_str;
  }
  else
  {
    self.transaction_text.attributedStringValue = _transaction_norm_str;
    self.link_text.attributedStringValue = _link_high_str;
  }
  [self setNeedsDisplay:YES];
}

- (void)mouseMoved:(NSEvent*)theEvent
{
  NSPoint loc = theEvent.locationInWindow;
  if (loc.x < self.bounds.size.width / 2.0)
  {
    if (_mode == INFINIT_MAIN_VIEW_LINK_MODE)
    {
      self.transaction_text.attributedStringValue = _transaction_hover_str;
      self.link_text.attributedStringValue = _link_high_str;
      _hover = YES;
    }
    else
    {
      self.link_text.attributedStringValue = _link_norm_str;
      _hover = NO;
    }
  }
  else
  {
    if (_mode == INFINIT_MAIN_VIEW_TRANSACTION_MODE)
    {
      self.link_text.attributedStringValue = _link_hover_str;
      self.transaction_text.attributedStringValue = _transaction_high_str;
      _hover = YES;
    }
    else
    {
      self.transaction_text.attributedStringValue = _transaction_norm_str;
      _hover = NO;
    }
  }
  [self setNeedsDisplay:YES];
}

- (void)mouseDown:(NSEvent*)theEvent
{
  _hover = NO;
  NSPoint click_loc = theEvent.locationInWindow;
  if (click_loc.x < self.bounds.size.width / 2.0)
    [_delegate gotUserClick:self];
  else
    [_delegate gotLinkClick:self];
}

//- Drawing ----------------------------------------------------------------------------------------

- (void)drawRect:(NSRect)dirtyRect
{
  NSBezierPath* bg = [IAFunctions roundedTopBezierWithRect:self.bounds cornerRadius:6.0];
  [IA_GREY_COLOUR(255) set];
  [bg fill];
  NSBezierPath* light_line =
  [NSBezierPath bezierPathWithRect:NSMakeRect(0.0, 0.0, NSWidth(self.bounds), 2.0)];
  if (_hover)
    [IA_RGB_COLOUR(213, 213, 213) set];
  else
    [IA_GREY_COLOUR(230) set];
  [light_line fill];
  NSRect dark_rect = {
    .origin = NSMakePoint((NSWidth(self.bounds) / 2.0) * _animate_mode, 0.0),
    .size = NSMakeSize(NSWidth(self.bounds) / 2.0, 2.0)
  };
  NSBezierPath* dark_line = [NSBezierPath bezierPathWithRect:dark_rect];
  [IA_RGB_COLOUR(0, 195, 192) set];
  [dark_line fill];
}

@end
