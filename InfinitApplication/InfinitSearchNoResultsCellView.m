//
//  InfinitSearchNoResultsCellView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 15/10/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitSearchNoResultsCellView.h"

@implementation InfinitSearchInfinitView
{
  NSTrackingArea* _tracking_area;
}

- (id)initWithFrame:(NSRect)frameRect
{
  if (self = [super initWithFrame:frameRect])
  {
    _hover = 0.0;
  }
  return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
  CGFloat colour_diff = 0;
  if (_hover > 0)
    colour_diff = (255 - 248) * _hover;
  [IA_RGB_COLOUR(248 - colour_diff, 248 - colour_diff, 248 + colour_diff) set];
  NSRectFill(self.bounds);
  NSRect top_line = NSMakeRect(0.0, NSHeight(self.bounds) - 1.0, NSWidth(self.bounds), 1.0);
  [IA_GREY_COLOUR(229) set];
  NSRectFill(top_line);
}

- (void)setHover:(CGFloat)hover
{
  _hover = hover;
  [self setNeedsDisplay:YES];
}

- (void)mouseDown:(NSEvent*)theEvent
{
  if (theEvent.clickCount == 1)
  {
    [((InfinitSearchNoResultsCellView*)self.superview) gotWantsSearchInfinit];
  }
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

- (void)updateTrackingAreas
{
  [self removeTrackingArea:_tracking_area];
  [self createTrackingArea];
  [super updateTrackingAreas];
}

- (void)mouseEntered:(NSEvent*)theEvent
{
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
   {
     [self.animator setHover:1.0];
   } completionHandler:^{
     self.hover = 1.0;
   }];
}

- (void)mouseExited:(NSEvent*)theEvent
{
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
   {
     [self.animator setHover:0.0];
   } completionHandler:^{
     self.hover = 0.0;
   }];
}

- (void)resetCursorRects
{
  [super resetCursorRects];
  NSCursor* cursor = [NSCursor pointingHandCursor];
  [self addCursorRect:self.bounds cursor:cursor];
}

@end

@implementation InfinitSearchNoResultsCellView

static NSDictionary* _attrs = nil;
static NSDictionary* _bold_attrs = nil;
static NSAttributedString* _no_results_str = nil;
static NSAttributedString* _search_infinit_str = nil;

- (void)dealloc
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)setup
{
  if (_attrs == nil)
  {
    NSFont* font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica Neue"
                                                              traits:NSUnboldFontMask
                                                              weight:3
                                                                size:12.0];
    NSFont* bold_font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica Neue"
                                                                   traits:NSBoldFontMask
                                                                   weight:3
                                                                     size:12.0];
    NSMutableParagraphStyle* para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    para.alignment = NSCenterTextAlignment;
    _attrs = [IAFunctions textStyleWithFont:font
                             paragraphStyle:para
                                     colour:IA_GREY_COLOUR(60)
                                     shadow:nil];
    _bold_attrs = [IAFunctions textStyleWithFont:bold_font
                                  paragraphStyle:para
                                          colour:IA_GREY_COLOUR(60)
                                          shadow:nil];
    NSMutableAttributedString* temp =
      [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"No results. ", nil)
                                             attributes:_bold_attrs];
    [temp appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"Send to an email address instead.", nil)
                                                                 attributes:_attrs]];
    _no_results_str = temp;
    _search_infinit_str =
      [[NSAttributedString alloc] initWithString:NSLocalizedString(@"or search for  on Infinit", nil)
                                      attributes:_attrs];
  }
  [self.spinner stopAnimation:nil];
  self.spinner.hidden = YES;
  self.no_results_msg.attributedStringValue = _no_results_str;
  self.search_infinit_msg.hidden = NO;
}

- (void)setDelegate:(id<InfinitSearchNoResultsProcotol>)delegate
{
  _delegate = delegate;
  [self setup];
}

- (void)setSearch_string:(NSString*)search_string
{
  if ([search_string isEqualToString:_search_string])
    return;
  _search_string = search_string;
  [self setup];
  NSMutableAttributedString* temp = [_search_infinit_str mutableCopy];
  NSAttributedString* quoted =
    [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\"%@\"", _search_string]
                                    attributes:_bold_attrs];
  [temp insertAttributedString:quoted atIndex:14];
  self.search_infinit_msg.attributedStringValue = temp;
  [self setNeedsDisplay:YES];
}

- (void)gotWantsSearchInfinit
{
  [self performSelector:@selector(delayedGotWantsSearchInfinit) withObject:nil afterDelay:1.0];
  [self.spinner startAnimation:nil];
  self.search_infinit_msg.hidden = YES;
  self.spinner.hidden = NO;
}

- (void)delayedGotWantsSearchInfinit
{
  [_delegate cellWantsSearchInfinit:self];
}

- (BOOL)isOpaque
{
  return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
  [IA_GREY_COLOUR(255) set];
  NSRectFill(self.bounds);
}

@end
