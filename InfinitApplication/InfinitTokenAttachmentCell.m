//
//  InfinitTokenAttachmentCell.m
//  InfinitApplication
//
//  Created by Christopher Crone on 23/04/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitTokenAttachmentCell.h"

@implementation InfinitTokenAttachmentCell

static NSDictionary* _norm_attrs = nil;

- (id)init
{
  if (self = [super init])
  {
    if (_norm_attrs == nil)
    {
      NSFont* token_font = [[NSFontManager sharedFontManager]fontWithFamily:@"Helvetica"
                                                                     traits:NSUnboldFontMask
                                                                     weight:3
                                                                       size:12.5];
      _norm_attrs = [IAFunctions textStyleWithFont:token_font
                                    paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                            colour:IA_GREY_COLOUR(255)
                                            shadow:nil];
    }
  }
  return self;
}

- (NSSize)cellSize
{
  NSSize size = [super cellSize];
  return NSMakeSize(size.width + 10.0, 24.0);
}

- (NSPoint)cellBaselineOffset
{
  return NSMakePoint(0.0, -7.0);
}

- (void)drawTokenWithFrame:(NSRect)rect
                    inView:(NSView*)controlView
{
  NSRect token_rect = {
    .origin = NSMakePoint(rect.origin.x + 5.0, rect.origin.y),
    .size = NSMakeSize(rect.size.width - 10.0, rect.size.height)
  };
  CGFloat corner_radius = 3.0;
  NSBezierPath* bg = [NSBezierPath bezierPathWithRoundedRect:token_rect
                                                     xRadius:corner_radius
                                                     yRadius:corner_radius];
  bg.lineWidth = 1.0;
  if (self.tokenDrawingMode == OEXTokenDrawingModeSelected)
  {
    [IA_RGB_COLOUR(45, 209, 205) set];
    [bg fill];
    [bg stroke];
    self.attributedStringValue = [[NSAttributedString alloc] initWithString:self.stringValue
                                                                 attributes:_norm_attrs];
  }
  else
  {
    [IA_RGB_COLOUR(78, 185, 179) set];
    [bg fill];
    [bg stroke];
    self.attributedStringValue = [[NSAttributedString alloc] initWithString:self.stringValue
                                                                 attributes:_norm_attrs];
  }
  
  NSRect text_rect = {
    .origin = NSMakePoint(token_rect.origin.x + 30.0, token_rect.origin.y + 3.0),
    .size = NSMakeSize(token_rect.size.width - 20.0, token_rect.size.height)
  };
  [self.attributedStringValue drawInRect:text_rect];
  [NSGraphicsContext saveGraphicsState];
  
  NSRect avatar_rect;
  // WORKAROUND Retina has an extra pixel under the avatar
  if ([[NSScreen mainScreen] backingScaleFactor] == 2.0)
  {
    avatar_rect = NSMakeRect(token_rect.origin.x - 1.0, token_rect.origin.y, 24.0, 24.0);
  }
  else
  {
    avatar_rect = NSMakeRect(token_rect.origin.x - 1.0, token_rect.origin.y, 24.0, 25.0);
  }
  
  NSBezierPath* clip = [IAFunctions roundedLeftSideBezierWithRect:avatar_rect
                                                     cornerRadius:corner_radius];
  [clip addClip];
  
	[self.avatar drawInRect:avatar_rect
                 fromRect:NSZeroRect
                operation:NSCompositeSourceOver
                 fraction:1.0
           respectFlipped:YES
                    hints:nil];
  
  [NSGraphicsContext restoreGraphicsState];
}

@end
