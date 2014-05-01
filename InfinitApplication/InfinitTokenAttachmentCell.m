//
//  InfinitTokenAttachmentCell.m
//  InfinitApplication
//
//  Created by Christopher Crone on 23/04/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitTokenAttachmentCell.h"

@implementation InfinitTokenAttachmentCell

static NSDictionary* _norm_attrs;
static NSDictionary* _sel_attrs;

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
                                            colour:IA_RGB_COLOUR(72.0, 86.0, 92.0)
                                            shadow:nil];
      
      _sel_attrs = [IAFunctions textStyleWithFont:token_font
                                   paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                           colour:IA_RGB_COLOUR(59.0, 76.0, 83.0)
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
  return NSMakePoint(0.0, -10.0);
}

- (void)drawTokenWithFrame:(NSRect)rect inView:(NSView *)controlView
{
  NSRect token_rect = {
    .origin = NSMakePoint(rect.origin.x + 5.0, rect.origin.y),
    .size = NSMakeSize(rect.size.width - 10.0, rect.size.height)
  };
  NSBezierPath* bg = [NSBezierPath bezierPathWithRoundedRect:token_rect xRadius:3.0 yRadius:3.0];
  bg.lineWidth = 1.0;
  if (self.tokenDrawingMode == OEXTokenDrawingModeSelected)
  {
    [IA_RGB_COLOUR(222.0, 234.0, 238.0) set];
    [bg fill];
    [IA_RGB_COLOUR(185.0, 197.0, 202.0) set];
    [bg stroke];
    self.attributedStringValue = [[NSAttributedString alloc] initWithString:self.stringValue
                                                                 attributes:_sel_attrs];
  }
  else if (self.tokenDrawingMode == OEXTokenDrawingModeHighlighted)
  {
    [IA_RGB_COLOUR(235, 242, 244) set];
    [bg fill];
    [IA_RGB_COLOUR(188.0, 202.0, 208.0) set];
    [bg stroke];
    self.attributedStringValue = [[NSAttributedString alloc] initWithString:self.stringValue
                                                                 attributes:_norm_attrs];
  }
  else
  {
    [IA_RGB_COLOUR(239.0, 245.0, 247.0) set];
    [bg fill];
    [IA_RGB_COLOUR(202.0, 216.0, 221.0) set];
    [bg stroke];
    self.attributedStringValue = [[NSAttributedString alloc] initWithString:self.stringValue
                                                                 attributes:_norm_attrs];
  }
  [IA_GREY_COLOUR(255.0) set];
  NSBezierPath* top_line = [NSBezierPath bezierPathWithRect:NSMakeRect(token_rect.origin.x + 3.0,
                                                                       1.0,
                                                                       token_rect.size.width - 6.0,
                                                                       1.0)];
  [top_line fill];
  
  NSRect text_rect = {
    .origin = NSMakePoint(token_rect.origin.x + 30.0, token_rect.origin.y + 3.0),
    .size = NSMakeSize(token_rect.size.width - 20.0, token_rect.size.height)
  };
  [self.attributedStringValue drawInRect:text_rect];
  [NSGraphicsContext saveGraphicsState];
  
  NSRect avatar_rect;
  // WORKAROUND Retina has an extra pixel under the avatar
  if ([[NSScreen mainScreen] backingScaleFactor] > 1.0)
  {
    avatar_rect = NSMakeRect(token_rect.origin.x + 0.0, token_rect.origin.y + 1.0, 22.0, 22.0);
  }
  else
  {
    avatar_rect = NSMakeRect(token_rect.origin.x + 0.0, token_rect.origin.y + 0.0, 23.0, 23.0);
  }
  
  NSBezierPath* clip = [IAFunctions roundedLeftSideBezierWithRect:avatar_rect cornerRadius:2.0];
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
