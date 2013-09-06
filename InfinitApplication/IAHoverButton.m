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
    NSDictionary* _normal_attrs;
    NSDictionary* _hover_attrs;
    NSImage* _normal_image;
    NSImage* _hover_image;
}

//- Initialisation ---------------------------------------------------------------------------------

@synthesize hoverImage = _hover_image;

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
    }
    return self;
}

- (void)awakeFromNib
{
    _normal_image = self.image;
}

- (void)dealloc
{
    _tracking_area = nil;
}

- (void)resetCursorRects
{
    [super resetCursorRects];
    NSCursor* cursor = [NSCursor pointingHandCursor];
    [self addCursorRect:self.bounds cursor:cursor];
}

- (void)ensureTrackingArea
{
    _tracking_area = [[NSTrackingArea alloc] initWithRect:NSZeroRect
                                                  options:(NSTrackingInVisibleRect |
                                                           NSTrackingActiveAlways |
                                                           NSTrackingMouseEnteredAndExited)
                                                    owner:self
                                                 userInfo:nil];
}

- (void)updateTrackingAreas
{
    [super updateTrackingAreas];
    [self ensureTrackingArea];
    if (![[self trackingAreas] containsObject:_tracking_area])
    {
        [self addTrackingArea:_tracking_area];
    }
}

- (void)mouseEntered:(NSEvent*)theEvent
{
    NSAttributedString* title = self.attributedTitle;
    self.attributedTitle = [[NSAttributedString alloc] initWithString:title.string
                                                           attributes:_hover_attrs];
    self.image = _hover_image;
}

- (void)mouseExited:(NSEvent*)theEvent
{
    NSAttributedString* title = self.attributedTitle;
    self.attributedTitle = [[NSAttributedString alloc] initWithString:title.string
                                                           attributes:_normal_attrs];
    self.image = _normal_image;
}

//- General Functions ------------------------------------------------------------------------------

- (void)setHoverImage:(NSImage*)new_image
{
    _hover_image = new_image;
    [self setNeedsDisplay:YES];
}

- (void)setTextNormalColour:(NSColor*)colour
{
    _normal_attrs = [IAFunctions textStyleWithFont:[NSFont systemFontOfSize:11.0]
                                    paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                            colour:colour
                                            shadow:nil];
}

- (void)setTextHoverColour:(NSColor*)colour
{
    _hover_attrs = [IAFunctions textStyleWithFont:[NSFont systemFontOfSize:11.0]
                                   paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                           colour:colour
                                           shadow:nil];
}

@end
