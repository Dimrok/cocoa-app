//
//  IAPaddedTextFieldCell.m
//  InfinitApplication
//
//  Created by Christopher Crone on 9/6/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAPaddedTextFieldCell.h"

@implementation IAPaddedTextFieldCell
{
@private
    CGFloat _padding;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithCoder:(NSCoder*)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        _padding = 10.0;
    }
    return self;
}

//- General Functions ------------------------------------------------------------------------------

- (NSRect)padRect:(NSRect)rect
{
    return NSMakeRect(rect.origin.x + _padding,
                      rect.origin.y + _padding,
                      rect.size.width - 2.0 * _padding,
                      rect.size.height - 2.0 * _padding);
}

//- Drawing ----------------------------------------------------------------------------------------

- (void)drawWithFrame:(NSRect)cellFrame
               inView:(NSView*)controlView
{
    NSBezierPath* better_bounds = [NSBezierPath bezierPathWithRoundedRect:cellFrame
                                                                  xRadius:5.0
                                                                  yRadius:5.0];
    [better_bounds addClip];
    [super drawWithFrame:cellFrame
                  inView:controlView];
    if (self.isBezeled)
    {
        [better_bounds setLineWidth:1.0];
        [IA_GREY_COLOUR(224.0) set];
        [better_bounds stroke];
    }
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame
                       inView:(NSView*)controlView
{
    [super drawInteriorWithFrame:[self padRect:cellFrame]
                          inView:controlView];
}

- (void)editWithFrame:(NSRect)aRect inView:(NSView*)controlView
               editor:(NSText*)editor
             delegate:(id)delegate
                event:(NSEvent*)event
{
    [super editWithFrame:[self padRect:aRect]
                  inView:controlView
                  editor:editor
                delegate:delegate
                   event:event];
}

- (void)selectWithFrame:(NSRect)aRect
                 inView:(NSView*)controlView
                 editor:(NSText*)textObj
               delegate:(id)anObject
                  start:(NSInteger)selStart
                 length:(NSInteger)selLength
{
    [super selectWithFrame:[self padRect:aRect]
                    inView:controlView
                    editor:textObj
                  delegate:anObject
                     start:selStart
                    length:selLength];
}

- (NSRect)_focusRingFrameForFrame:(NSRect)frame
                        cellFrame:(NSRect)cellFrame
{
    return self.controlView.bounds;
}

@end
