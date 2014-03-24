//
//  InfinitConversationPersonView.mm
//  InfinitApplication
//
//  Created by Christopher Crone on 17/03/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitConversationPersonView.h"

@implementation InfinitConversationPersonView
{
@private
  id<InfinitConversationPersonViewProtocol> _delegate;
  NSTrackingArea* _tracking_area;
  NSInteger _tracking_options;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithFrame:(NSRect)frame
{
  if (self = [super initWithFrame:frame])
  {
    _tracking_options = (NSTrackingInVisibleRect |
                         NSTrackingActiveAlways |
                         NSTrackingMouseEnteredAndExited);
  }
  return self;
}

- (void)setDelegate:(id<InfinitConversationPersonViewProtocol>)delegate
{
  _delegate = delegate;
}

- (void)dealloc
{
  _tracking_area = nil;
}

//- Drawing ----------------------------------------------------------------------------------------

- (void)drawRect:(NSRect)dirtyRect
{
  [IA_GREY_COLOUR(255.0) set];
  NSRectFill(self.bounds);
  
  NSRect grey_line = NSMakeRect(0.0, 1.0, NSWidth(self.bounds), 1.0);
  [IA_GREY_COLOUR(223) set];
  NSRectFill(grey_line);
}

//- Mouse Handling ---------------------------------------------------------------------------------


- (void)ensureTrackingArea
{
  if (_tracking_area == nil)
  {
    _tracking_area = [[NSTrackingArea alloc] initWithRect:NSZeroRect
                                                  options:_tracking_options
                                                    owner:self
                                                 userInfo:nil];
  }
}

- (void)updateTrackingAreas
{
  [super updateTrackingAreas];
  [self ensureTrackingArea];
  if (![self.trackingAreas containsObject:_tracking_area])
  {
    [self addTrackingArea:_tracking_area];
  }
}

- (void)mouseDown:(NSEvent*)theEvent
{
  if (theEvent.clickCount == 1)
    [_delegate conversationPersonViewGotClick:self];
}

@end
