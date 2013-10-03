//
//  IACentredMessageTextCell.m
//  InfinitApplication
//
//  Created by Christopher Crone on 10/3/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IACentredMessageTextCell.h"

@implementation IACentredMessageTextCell

- (void)awakeFromNib
{
    [self setFocusRingType:NSFocusRingTypeNone];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{
    NSBezierPath* better_bounds = [NSBezierPath bezierPathWithRoundedRect:cellFrame
                                                                  xRadius:2.0
                                                                  yRadius:2.0];
    [better_bounds addClip];
    [super drawWithFrame:cellFrame
                  inView:controlView];
}

- (NSRect)adjustedFrameToVerticallyCentreText:(NSRect)frame
{
    // super would normally draw text at the top of the cell
    CGRect text_rect = [self.attributedStringValue
                        boundingRectWithSize:frame.size
                                     options:NSStringDrawingUsesLineFragmentOrigin];
    NSInteger offset = floor((NSHeight(frame) - (text_rect.size.height)) / 2.0);
    NSRect new_frame = NSMakeRect(frame.origin.x, frame.origin.y, NSWidth(frame), NSHeight(frame));
    return NSInsetRect(new_frame, 0.0, offset);
}

- (void)editWithFrame:(NSRect)aRect inView:(NSView*)controlView
               editor:(NSText*)editor delegate:(id)delegate event:(NSEvent*)event
{
    [super editWithFrame:[self adjustedFrameToVerticallyCentreText:aRect]
                  inView:controlView editor:editor delegate:delegate event:event];
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView*)controlView
                 editor:(NSText*)editor delegate:(id)delegate
                  start:(NSInteger)start length:(NSInteger)length
{
    
    [super selectWithFrame:[self adjustedFrameToVerticallyCentreText:aRect]
                    inView:controlView editor:editor delegate:delegate
                     start:start length:length];
}

- (void)drawInteriorWithFrame:(NSRect)frame inView:(NSView*)view
{
    [super drawInteriorWithFrame:[self adjustedFrameToVerticallyCentreText:frame] inView:view];
}

@end
