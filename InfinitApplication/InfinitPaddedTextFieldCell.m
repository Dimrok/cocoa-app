//
//  InfinitPaddedTextFieldCell.m
//  InfinitApplication
//
//  Created by Christopher Crone on 24/12/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "InfinitPaddedTextFieldCell.h"

@implementation InfinitPaddedTextFieldCell
{
@private
    CGFloat _padding;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithCoder:(NSCoder*)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        _padding = 15.0;
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
    [IA_GREY_COLOUR(255.0) set];
    NSRectFill(cellFrame);
    [super drawWithFrame:cellFrame
                  inView:controlView];
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

@end
