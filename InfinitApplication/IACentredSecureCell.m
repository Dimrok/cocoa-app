//
//  IACentredPasswordCell.m
//  InfinitApplication
//
//  Created by Christopher Crone on 7/29/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IACentredSecureCell.h"

#import "IADefine.h"

@implementation IACentredSecureCell

- (void)awakeFromNib
{
    [self setFocusRingType:NSFocusRingTypeNone];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{
    NSBezierPath* better_bounds = [NSBezierPath bezierPathWithRoundedRect:cellFrame
                                                                  xRadius:3.0
                                                                  yRadius:3.0];
    [better_bounds addClip];
    [super drawWithFrame:cellFrame
                  inView:controlView];
    if (self.isBezeled)
    {
        [better_bounds setLineWidth:2];
        [IA_GREY_COLOUR(194.0) set];
        [better_bounds stroke];
    }
}

- (NSRect)adjustedFrameToVerticallyCenterText:(NSRect)frame
{
    // super would normally draw text at the top of the cell
    NSInteger offset = floor((NSHeight(frame) -
                              (self.font.ascender - self.font.descender)) / 2.0);
    NSRect new_frame = NSMakeRect(frame.origin.x, frame.origin.y, NSWidth(frame), NSHeight(frame));
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
