//
//  IACentredTextField.m
//  InfinitApplication
//
//  Created by Christopher Crone on 7/29/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IACenteredTextFieldCell.h"

@implementation IACenteredTextFieldCell

- (NSRect)adjustedFrameToVerticallyCenterText:(NSRect)frame
{
    // super would normally draw text at the top of the cell
    NSInteger offset = floor((NSHeight(frame) -
                              ([[self font] ascender] - [[self font] descender])) / 2.0);
    NSRect new_frame = NSMakeRect(frame.origin.x, frame.origin.y,
                                  frame.size.width, frame.size.height);
    return NSInsetRect(new_frame, 7.0, offset - 4.0);
}

- (void)editWithFrame:(NSRect)aRect inView:(NSView*)controlView
               editor:(NSText*)editor delegate:(id)delegate event:(NSEvent*)event
{
    [super editWithFrame:[self adjustedFrameToVerticallyCenterText:aRect]
                  inView:controlView editor:editor delegate:delegate event:event];
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView*)controlView
                 editor:(NSText*)editor delegate:(id)delegate
                  start:(NSInteger)start length:(NSInteger)length
{
    
    [super selectWithFrame:[self adjustedFrameToVerticallyCenterText:aRect]
                    inView:controlView editor:editor delegate:delegate
                     start:start length:length];
}

- (void)drawInteriorWithFrame:(NSRect)frame inView:(NSView*)view
{
    [super drawInteriorWithFrame:[self adjustedFrameToVerticallyCenterText:frame] inView:view];
}

@end
