//
//  InfinitConversationFileCellView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 24/03/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitConversationFileCellView.h"

@implementation InfinitConversationFileCellView
{
@private
  NSDictionary* _attrs;
  
  NSImageView* _file_icon;
  NSTextField* _file_name;
}

- (id)initWithFrame:(NSRect)frame
             onLeft:(BOOL)on_left
{
  if (self = [super initWithFrame:frame])
  {
    NSFont* font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica"
                                                              traits:NSUnboldFontMask
                                                              weight:0
                                                                size:11.5];
    NSMutableParagraphStyle* para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    para.lineBreakMode = NSLineBreakByTruncatingMiddle;
    _file_name = [[NSTextField alloc] initWithFrame:NSZeroRect];
    _file_icon = [[NSImageView alloc] initWithFrame:NSZeroRect];
    if (on_left)
    {
      _file_name.frame = NSMakeRect(45.0, 9.0, 195.0, 15.0);
      _file_icon.frame = NSMakeRect(22.0, 9.0, 16.0, 16.0);
    }
    else
    {
      para.alignment = NSRightTextAlignment;
      _file_name.frame = NSMakeRect(18.0, 9.0, 195.0, 15.0);
      _file_icon.frame = NSMakeRect(220.0, 9.0, 16.0, 16.0);
    }
    _attrs = [IAFunctions textStyleWithFont:font
                             paragraphStyle:para
                                     colour:IA_GREY_COLOUR(193.0)
                                     shadow:nil];
    [_file_name.cell setBordered:NO];
    [_file_name.cell setDrawsBackground:NO];
    [_file_name.cell setLineBreakMode:NSLineBreakByTruncatingMiddle];
    [_file_name.cell setTruncatesLastVisibleLine:YES];
    [self addSubview:_file_name];
    [self addSubview:_file_icon];
  }
  return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
  [IA_GREY_COLOUR(248.0) set];
  NSRectFill(self.bounds);
  NSRect line_rect = NSMakeRect(0.0, NSHeight(self.bounds) - 2.0, NSWidth(self.bounds), 1.0);
  NSBezierPath* line = [NSBezierPath bezierPathWithRect:line_rect];
  [IA_GREY_COLOUR(255.0) set];
  [line fill];
  NSBezierPath* border = [NSBezierPath bezierPathWithRect:self.bounds];
  [IA_GREY_COLOUR(220.0) set];
  [border stroke];
}

- (void)setFileName:(NSString*)name
{
  _file_name.attributedStringValue =
    [[NSAttributedString alloc] initWithString:name attributes:_attrs];
  _file_icon.image =
    [[NSWorkspace sharedWorkspace] iconForFileType:[_file_name.stringValue pathExtension]];
  [self setNeedsDisplay:YES];
}

@end
