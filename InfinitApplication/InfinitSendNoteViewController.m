//
//  InfinitSendNoteViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 10/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitSendNoteViewController.h"

//- View -------------------------------------------------------------------------------------------

@implementation InfinitSendNoteView

- (BOOL)isOpaque
{
  return NO;
}

- (NSSize)intrinsicContentSize
{
  CGFloat height;
  if (_open)
    height = NSHeight(self.header_view.frame) + 100.0;
  else
    height = NSHeight(self.header_view.frame);
  return NSMakeSize(317.0, height);
}

- (void)setOpen:(BOOL)open
{
  _open = open;
  self.header_view.open = open;
}

@end

//- Header View ------------------------------------------------------------------------------------

@implementation InfinitSendNoteHeaderView
{
@private
  NSTrackingArea* _tracking_area;
  id<InfinitSendNoteHeaderViewProtocol> _delegate;
}

- (NSSize)intrinsicContentSize
{
  return self.frame.size;
}

- (BOOL)isOpaque
{
  return YES;
}

- (void)setDelegate:(id<InfinitSendNoteHeaderViewProtocol>)delegate
{
  _delegate = delegate;
}

- (void)drawRect:(NSRect)dirtyRect
{
  [IA_GREY_COLOUR(248) set];
  NSRectFill(self.bounds);
  NSBezierPath* dark_line;
  NSBezierPath* light_line;
  if (!_link_mode)
  {
    [IA_GREY_COLOUR(230) set];
    dark_line = [NSBezierPath bezierPathWithRect:NSMakeRect(0.0, NSHeight(self.bounds) - 1.0,
                                                            NSWidth(self.bounds), 1.0)];
    [dark_line fill];
    [IA_GREY_COLOUR(255) set];
    light_line = [NSBezierPath bezierPathWithRect:NSMakeRect(0.0, NSHeight(self.bounds) - 2.0,
                                                             NSWidth(self.bounds), 1.0)];
  }
  [light_line fill];
  if (_open)
  {
    [IA_GREY_COLOUR(230) set];
    dark_line = [NSBezierPath bezierPathWithRect:NSMakeRect(0.0, 0.0,
                                                            NSWidth(self.bounds), 1.0)];
    [dark_line fill];
  }
}

- (void)dealloc
{
  _tracking_area = nil;
}

- (void)setOpen:(BOOL)open
{
  _open = open;
  if (_open)
    self.show_note.image = [IAFunctions imageNamed:@"send-icon-hide-files"];
  else
    self.show_note.image = [IAFunctions imageNamed:@"send-icon-show-files"];
}

- (void)setLink_mode:(BOOL)link_mode
{
  _link_mode = link_mode;
  [self setNeedsDisplay:YES];
}

- (void)resetCursorRects
{
  [super resetCursorRects];
  [self addCursorRect:self.bounds cursor:[NSCursor arrowCursor]];
}

- (void)createTrackingArea
{
  _tracking_area = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                options:(NSTrackingMouseEnteredAndExited |
                                                         NSTrackingActiveAlways)
                                                  owner:self
                                               userInfo:nil];

  [self addTrackingArea:_tracking_area];

  NSPoint mouse_loc = self.window.mouseLocationOutsideOfEventStream;
  mouse_loc = [self convertPoint:mouse_loc fromView:nil];
  if (NSPointInRect(mouse_loc, self.bounds))
    [self mouseEntered:nil];
  else
    [self mouseExited:nil];
}

- (void)updateTrackingAreas
{
  [self removeTrackingArea:_tracking_area];
  [self createTrackingArea];
  [super updateTrackingAreas];
}

- (void)mouseEntered:(NSEvent*)theEvent
{

}

- (void)mouseExited:(NSEvent*)theEvent
{

}

- (void)mouseDown:(NSEvent*)theEvent
{
  [_delegate noteHeaderGotClick:self];
}

@end

//- View Controller --------------------------------------------------------------------------------

@interface InfinitSendNoteViewController ()
@end

@implementation InfinitSendNoteViewController
{
  id<InfinitSendNoteViewProtocol> _delegate;
  NSUInteger _note_limit;
  NSDictionary* _characters_attrs;
}

- (id)initWithDelegate:(id<InfinitSendNoteViewProtocol>)delegate
{
  if (self = [super initWithNibName:self.className bundle:nil])
  {
    _delegate = delegate;
    _note_limit = 100;
    NSFont* small_font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica"
                                                                    traits:NSUnboldFontMask
                                                                    weight:0
                                                                      size:10.0];
    NSMutableParagraphStyle* right_aligned =
    [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    right_aligned.alignment = NSRightTextAlignment;
    _characters_attrs = [IAFunctions textStyleWithFont:small_font
                                        paragraphStyle:right_aligned
                                                colour:IA_GREY_COLOUR(205)
                                                shadow:nil];
  }
  return self;
}

- (CGFloat)height
{
  return self.view.intrinsicContentSize.height;
}

- (void)awakeFromNib
{
  [self.header_view setDelegate:self];
  NSFont* font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica"
                                                            traits:NSUnboldFontMask
                                                            weight:3
                                                              size:12.0];
  NSDictionary* attrs = [IAFunctions textStyleWithFont:font
                                        paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                                colour:IA_GREY_COLOUR(190)
                                                shadow:nil];
  NSString* add_str = NSLocalizedString(@"Add note", nil);
  NSAttributedString* add_note = [[NSAttributedString alloc] initWithString:add_str
                                                                 attributes:attrs];
  self.header_view.message.attributedStringValue = add_note;
  self.characters_label.attributedStringValue =
    [[NSAttributedString alloc]initWithString:NSLocalizedString(@"100 chars left", nil)
                                   attributes:_characters_attrs];
}

- (void)setOpen:(BOOL)open
{
  _open = open;
  ((InfinitSendNoteView*)self.view).open = open;
}

- (void)setLink_mode:(BOOL)link_mode
{
  _link_mode = link_mode;
  self.header_view.link_mode = link_mode;
}

//- Note Handling ----------------------------------------------------------------------------------

- (NSString*)note
{
  return self.note_field.stringValue;
}

- (void)controlTextDidChange:(NSNotification*)aNotification
{
  NSControl* control = aNotification.object;
  if (control != self.note_field)
    return;

  if (self.note_field.stringValue.length > _note_limit)
  {
    self.note_field.stringValue = [self.note_field.stringValue
                                   substringWithRange:NSMakeRange(0, _note_limit)];
  }

  NSUInteger note_length = self.note_field.stringValue.length;

  NSString* characters_str;
  if (_note_limit - note_length == 1)
  {
    characters_str = NSLocalizedString(@"1 char left", @"1 char left");
  }
  else
  {
    characters_str = [NSString stringWithFormat:@"%lu %@", (_note_limit - note_length),
                      NSLocalizedString(@"chars left", @"chars left")];
  }

  self.characters_label.attributedStringValue = [[NSAttributedString alloc]
                                                 initWithString:characters_str
                                                 attributes:_characters_attrs];
}

- (BOOL)control:(NSControl*)control
       textView:(NSTextView*)textView
doCommandBySelector:(SEL)commandSelector
{
  if (control != self.note_field)
    return NO;

  if (commandSelector == @selector(insertTab:) || commandSelector == @selector(insertBacktab:))
  {
    [_delegate noteViewWantsLoseFocus:self];
    return YES;
  }
  if (commandSelector == @selector(insertNewline:))
  {
    return YES;
  }
  return NO;
}

//- Header Protocol --------------------------------------------------------------------------------

- (void)noteHeaderGotClick:(InfinitSendNoteHeaderView*)sender
{
  if (_open)
    [_delegate noteViewWantsHide:self];
  else
    [_delegate noteViewWantsShow:self];
}

@end
