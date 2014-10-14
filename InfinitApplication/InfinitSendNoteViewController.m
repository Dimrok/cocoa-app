//
//  InfinitSendNoteViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 10/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitSendNoteViewController.h"

//- Note Field -------------------------------------------------------------------------------------

@implementation InfinitSendNoteField

- (BOOL)becomeFirstResponder
{
  [(id<InfinitSendNoteProtocol>)_delegate gotFocus:self];
  return [super becomeFirstResponder];
}

@end

//- View -------------------------------------------------------------------------------------------

@interface InfinitSendNoteView : NSView
@property (nonatomic, readwrite) BOOL link_mode;
@end

@implementation InfinitSendNoteView

- (void)drawRect:(NSRect)dirtyRect
{
  [IA_GREY_COLOUR(255) set];
  NSRectFill(self.bounds);
  NSBezierPath* line = [NSBezierPath bezierPathWithRect:NSMakeRect(0.0, 1.0,
                                                                   NSWidth(self.bounds), 1.0)];
  [IA_GREY_COLOUR(230) set];
  [line fill];
}

@end

//- View Controller --------------------------------------------------------------------------------

@interface InfinitSendNoteViewController ()
@end

@implementation InfinitSendNoteViewController
{
  // WORKAROUND: 10.7 doesn't allow weak references to certain classes (like NSViewController)
  __unsafe_unretained id<InfinitSendNoteViewProtocol> _delegate;
  NSUInteger _note_limit;
  NSDictionary* _norm_characters_attrs;
  NSDictionary* _done_characters_attrs;

  NSString* _last_note; // Hack to add files when dropping on the selected note field.
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
    _norm_characters_attrs = [IAFunctions textStyleWithFont:small_font
                                             paragraphStyle:right_aligned
                                                     colour:IA_GREY_COLOUR(205)
                                                     shadow:nil];

    _done_characters_attrs = [IAFunctions textStyleWithFont:small_font
                                             paragraphStyle:right_aligned
                                                     colour:IA_RGB_COLOUR(255, 0, 0)
                                                     shadow:nil];
  }
  return self;
}

- (void)awakeFromNib
{
  // WORKAROUND older versions of OS X don't handle setting of placeholder string well.
  if ([IAFunctions osxVersion] == INFINIT_OS_X_VERSION_10_9)
  {
    NSFont* font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica"
                                                              traits:NSUnboldFontMask
                                                              weight:3
                                                                size:12.0];
    NSDictionary* attrs = [IAFunctions textStyleWithFont:font
                                          paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                                  colour:IA_GREY_COLOUR(190)
                                                  shadow:nil];
    NSString* add_str = NSLocalizedString(@"Optional message...", nil);
    NSAttributedString* add_note = [[NSAttributedString alloc] initWithString:add_str
                                                                   attributes:attrs];
    [self.note_field.cell setPlaceholderAttributedString:add_note];
  }
  self.characters_label.attributedStringValue =
    [[NSAttributedString alloc]initWithString:@"100" attributes:_norm_characters_attrs];
  self.characters_label.hidden = YES;
  _last_note = @"";
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

  // Nasty hack to check if we got a file dropped in the note field while it's active.
  NSString* string_diff =
    [self.note_field.stringValue stringByReplacingOccurrencesOfString:_last_note withString:@""];
  if (string_diff.length > 1)
  {
    NSMutableArray* files =
      [NSMutableArray arrayWithArray:[string_diff componentsSeparatedByString:@"\n"]];
    // Only check the first one as it's unlikely that it will be a file and the others won't.
    if ([[NSFileManager defaultManager] fileExistsAtPath:files[0]])
    {
      self.note_field.stringValue = _last_note;
      [_delegate noteView:self gotFilesDropped:files];
    }
  }

  if (self.note_field.stringValue.length > _note_limit)
  {
    self.note_field.stringValue = [self.note_field.stringValue
                                   substringWithRange:NSMakeRange(0, _note_limit)];
  }

  NSInteger chars_left = _note_limit - self.note_field.stringValue.length;

  if (chars_left > 0)
  {
    self.characters_label.attributedStringValue =
      [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld", chars_left]
                                      attributes:_norm_characters_attrs];
  }
  else
  {
    self.characters_label.attributedStringValue =
      [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld", chars_left]
                                      attributes:_done_characters_attrs];
  }
  _last_note = self.note_field.stringValue;
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

- (void)controlTextDidEndEditing:(NSNotification*)obj
{
  if (obj.object != self.note_field)
    return;
  self.characters_label.hidden = YES;
}

- (void)gotFocus:(InfinitSendNoteField*)sender
{
  self.characters_label.hidden = NO;
}

@end
