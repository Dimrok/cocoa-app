//
//  InfinitLoginButton.m
//  InfinitApplication
//
//  Created by Christopher Crone on 19/03/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitLoginButton.h"

#import <Gap/InfinitColor.h>

@interface NSButtonCell (Private)
- (void)_updateMouseTracking;
@end

static NSDictionary* _attrs = nil;

@interface InfinitLoginButtonCell : NSButtonCell
@end

@implementation InfinitLoginButtonCell
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

- (void)drawInteriorWithFrame:(NSRect)cellFrame
                       inView:(NSView*)controlView
{
  NSBezierPath* bg_path =
    [NSBezierPath bezierPathWithRoundedRect:cellFrame xRadius:5.0f yRadius:5.0f];
  [self.backgroundColor set];
  [bg_path fill];
  NSSize image_size = NSMakeSize(0.0f, 0.0f);
  CGFloat image_space = 0.0f;
  if (self.image)
  {
    image_size = self.image.size;
    image_space = 7.0f;
  }
  NSSize text_size = self.attributedTitle.size;
  NSRect text_rect = NSMakeRect(floor((cellFrame.size.width - text_size.width + image_size.width + image_space) / 2.0f),
                                floor((cellFrame.size.height - text_size.height) / 2.0f),
                                text_size.width,
                                text_size.height);
  text_rect = [self drawTitle:self.attributedTitle withFrame:text_rect inView:controlView];
  text_size = text_rect.size;
  NSRect image_rect = NSMakeRect(text_rect.origin.x - image_size.width - image_space,
                                 text_rect.origin.y + 2.0f,
                                 image_size.width,
                                 image_size.height);
  [self drawImage:self.image withFrame:image_rect inView:controlView];
  if (self.isEnabled && self.isHighlighted)
  {
    [[InfinitColor colorWithGray:0 alpha:0.1f] set];
    [bg_path fill];
  }
  else if (self.isEnabled && _hover)
  {
    [[InfinitColor colorWithGray:255 alpha:0.1f] set];
    [bg_path fill];
  }
}

- (void)drawBezelWithFrame:(NSRect)frame
                    inView:(NSView*)controlView
{}

@end

@implementation InfinitLoginButton

#pragma mark - Customisation

- (void)setColor:(NSColor*)color
{
  _color = color;
  [self.cell setBackgroundColor:color];
  [self setNeedsDisplay];
}

- (void)setText:(NSString*)text
{
  if (_attrs == nil)
  {
    NSMutableParagraphStyle* para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    para.alignment = NSCenterTextAlignment;
    _attrs = @{NSFontAttributeName: [NSFont fontWithName:@"Source Sans Pro Bold" size:12.0f],
               NSParagraphStyleAttributeName: para,
               NSForegroundColorAttributeName: [InfinitColor colorWithGray:255]};
  }
  self.attributedTitle = [[NSAttributedString alloc] initWithString:text attributes:_attrs];
  [self setNeedsDisplay:YES];
}

@end
