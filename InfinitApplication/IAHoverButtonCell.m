//
//  IAHoverButtonCell.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/5/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAHoverButtonCell.h"

@interface NSButtonCell()
- (void)_updateMouseTracking;
@end

@implementation IAHoverButtonCell

@synthesize hoverImage = _hover_image;

- (void)mouseEntered:(NSEvent*)event
{
    if (_hover_image != nil && [_hover_image isValid])
    {
        _normal_image = [(NSButton*)self.controlView image];
        [(NSButton*)self.controlView setImage:_hover_image];
    }
}

- (void)mouseExited:(NSEvent*)event
{
    if (_normal_image != nil && [_normal_image isValid])
    {
        [(NSButton*)self.controlView setImage:_normal_image];
        _normal_image = nil;
    }
}

- (void)_updateMouseTracking
{
    [super _updateMouseTracking];
    if (self.controlView != nil &&
        [self.controlView respondsToSelector:@selector(_setMouseTrackingForCell:)])
    {
        [self.controlView performSelector:@selector(_setMouseTrackingForCell:) withObject:self];
    }
}

- (void)setHoverImage:(NSImage*)new_image
{
    _hover_image = new_image;
    [self.controlView setNeedsDisplay:YES];
}

- (void)dealloc
{
    _normal_image = nil;
    _hover_image = nil;
}

@end
