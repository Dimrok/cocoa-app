//
//  IAConversationHeaderView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/30/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAConversationHeaderView.h"

@implementation IAConversationHeaderView
{
@private
    id <IAConversationHeaderProtocol> _delegate;
    NSTrackingArea* _tracking_area;
    NSInteger _tracking_options;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithFrame:(NSRect)frameRect
{
    if (self = [super initWithFrame:frameRect])
    {
        _tracking_options = (NSTrackingInVisibleRect |
                             NSTrackingActiveAlways |
                             NSTrackingMouseEnteredAndExited);
    }
    return self;
}

- (void)setDelegate:(id<IAConversationHeaderProtocol>)delegate
{
    _delegate = delegate;
}


//- Drawing ----------------------------------------------------------------------------------------

- (void)drawRect:(NSRect)dirtyRect
{
    // White background
    NSBezierPath* white_bg = [NSBezierPath bezierPathWithRect:
                              NSMakeRect(0.0,
                                         2.0,
                                         self.bounds.size.width,
                                         self.bounds.size.height - 2.0)];
    [IA_GREY_COLOUR(255.0) set];
    [white_bg fill];
    
    // Grey line
    NSBezierPath* grey_line = [NSBezierPath bezierPathWithRect:NSMakeRect(0.0,
                                                                          1.0,
                                                                          self.bounds.size.width,
                                                                          1.0)];
    [IA_GREY_COLOUR(223.0) set];
    [grey_line fill];
    
    // White line
    NSBezierPath* white_line = [NSBezierPath bezierPathWithRect:NSMakeRect(0.0,
                                                                           0.0,
                                                                           self.bounds.size.width,
                                                                           1.0)];
    [IA_GREY_COLOUR(255.0) set];
    [white_line fill];
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
    [_delegate conversationHeaderGotClick:self];
}

@end
