//
//  InfinitInvitationButtonCell.m
//  InfinitApplication
//
//  Created by Christopher Crone on 23/03/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitInvitationButtonCell.h"

#import <Gap/InfinitColor.h>

@interface NSButtonCell (Private)
- (void)_updateMouseTracking;
@end

@interface InfinitInvitationButtonCell ()

@property (nonatomic, readonly) NSAttributedString* disabled_str;
@property (nonatomic, readonly) NSAttributedString* enabled_str;

@end

@implementation InfinitInvitationButtonCell
{
@private
  BOOL _hover;
}

// Override private mouse tracking function to ensure that we get mouseEntered/Exited events.
- (void)_updateMouseTracking
{
  [super _updateMouseTracking];
  if (self.controlView != nil && [self.controlView respondsToSelector:@selector(_setMouseTrackingForCell:)])
  {
    [self.controlView performSelector:@selector(_setMouseTrackingForCell:) withObject:self];
  }
}

- (void)mouseEntered:(NSEvent*)theEvent
{
  _hover = YES;
  [self.controlView setNeedsDisplay:YES];
}

- (void)mouseExited:(NSEvent*)theEvent
{
  _hover = NO;
  [self.controlView setNeedsDisplay:YES];
}

- (NSRect)drawTitle:(NSAttributedString*)title
          withFrame:(NSRect)frame
             inView:(NSView*)controlView
{
  if (!self.isEnabled)
  {
    if (self.disabled_str == nil)
    {
      NSFont* font = [[NSFontManager sharedFontManager] fontWithFamily:@"Source Sans Pro"
                                                                traits:NSBoldFontMask
                                                                weight:3
                                                                  size:13.0];
      NSMutableParagraphStyle* para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
      para.alignment = NSCenterTextAlignment;
      NSShadow* shadow = [[NSShadow alloc] init];
      shadow.shadowOffset = NSMakeSize(0.0, -1.0);
      NSDictionary* attrs = [IAFunctions textStyleWithFont:font
                                        paragraphStyle:para
                                                colour:[InfinitColor colorWithGray:255 alpha:0.5]
                                                shadow:shadow];
      _disabled_str = [[NSAttributedString alloc] initWithString:self.title attributes:attrs];
    }
    return [super drawTitle:self.disabled_str withFrame:frame inView:controlView];
  }
  if (self.enabled_str == nil)
  {
    NSFont* font = [[NSFontManager sharedFontManager] fontWithFamily:@"Source Sans Pro"
                                                              traits:NSBoldFontMask
                                                              weight:3
                                                                size:13.0];
    NSMutableParagraphStyle* para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    para.alignment = NSCenterTextAlignment;
    NSShadow* shadow = [[NSShadow alloc] init];
    shadow.shadowOffset = NSMakeSize(0.0, -1.0);
    NSDictionary* attrs = [IAFunctions textStyleWithFont:font
                                          paragraphStyle:para
                                                  colour:[InfinitColor colorWithGray:255]
                                                  shadow:shadow];
    _enabled_str = [[NSAttributedString alloc] initWithString:self.title attributes:attrs];
  }
  return [super drawTitle:self.enabled_str withFrame:frame inView:controlView];
}

- (NSBezierPath*)buttonBezierForFrame:(NSRect)frame
{
  CGFloat corner_rad = 3.0;
  NSBezierPath* res = [NSBezierPath bezierPath];
  if (self.left)
  {
    [res moveToPoint:NSMakePoint(0.0f, 0.0f)];
    [res lineToPoint:NSMakePoint(0.0f, frame.size.height - corner_rad)];
    [res appendBezierPathWithArcFromPoint:NSMakePoint(0.0f, frame.size.height)
                                  toPoint:NSMakePoint(corner_rad, frame.size.height) 
                                   radius:corner_rad];
    [res lineToPoint:NSMakePoint(frame.size.width, frame.size.height)];
    [res lineToPoint:NSMakePoint(frame.size.width, 0.0f)];
  }
  else
  {
    [res moveToPoint:NSMakePoint(0.0f, 0.0f)];
    [res lineToPoint:NSMakePoint(0.0f, frame.size.height)];
    [res lineToPoint:NSMakePoint(frame.size.width - corner_rad, frame.size.height)];
    [res appendBezierPathWithArcFromPoint:NSMakePoint(frame.size.width, frame.size.height)
                                  toPoint:NSMakePoint(frame.size.width, frame.size.height - corner_rad)
                                   radius:corner_rad];
    [res lineToPoint:NSMakePoint(frame.size.width, 0.0f)];
  }
  [res closePath];
  return res;
}

- (void)drawBezelWithFrame:(NSRect)frame
                    inView:(NSView*)controlView
{
  NSBezierPath* bg = [self buttonBezierForFrame:frame];
  if (self.isEnabled && _hover && !self.isHighlighted)
    [[InfinitColor colorWithGray:255 alpha:0.1f] set];
  else if (self.isEnabled && self.isHighlighted)
    [[InfinitColor colorWithGray:0 alpha:0.1f] set];
  else
    [[NSColor clearColor] set];
  [bg fill];
  [[InfinitColor colorWithRed:196 green:54 blue:55] set];
  NSRect line;
  if (self.left)
    line = NSMakeRect(frame.size.width - 1.0f, 0.0f, 1.0f, NSHeight(frame));
  else
    line = NSMakeRect(frame.origin.x, 0.0f, 1.0f, NSHeight(frame));
  NSRectFill(line);
}

@end
