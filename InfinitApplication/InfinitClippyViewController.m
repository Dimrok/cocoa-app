//
//  InfinitClippyViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 02/04/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitClippyViewController.h"

#import <QuartzCore/QuartzCore.h>

@interface InfinitClippyViewController ()
@end

//- Clippy Main View -------------------------------------------------------------------------------

@interface InfinitClippyView : IAMainView <NSDraggingDestination>

- (void)setDelegate:(id<InfinitClippyViewProtocol>)delegate;

@end

@protocol InfinitClippyViewProtocol <NSObject>

- (void)clippyViewGotDragEnter:(InfinitClippyView*)sender;
- (void)clippyViewGotDragExit:(InfinitClippyView*)sender;

@end

@implementation InfinitClippyView
{
@private
  id<InfinitClippyViewProtocol> _delegate;
  NSArray* _drag_types;
}

- (id)initWithFrame:(NSRect)frameRect
{
  if (self = [super initWithFrame:frameRect])
  {
    _drag_types = [NSArray arrayWithObjects:NSFilenamesPboardType, nil];
    [self registerForDraggedTypes:_drag_types];
  }
  return self;
}

- (void)setDelegate:(id<InfinitClippyViewProtocol>)delegate
{
  _delegate = delegate;
}

- (void)drawRect:(NSRect)dirtyRect
{
  NSBezierPath* bg = [IAFunctions roundedTopBezierWithRect:self.bounds cornerRadius:6.0];
  [IA_GREY_COLOUR(255) set];
  [bg fill];
}

//- Drag Handling ----------------------------------------------------------------------------------

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
  NSPasteboard* paste_board = sender.draggingPasteboard;
  if ([paste_board availableTypeFromArray:_drag_types])
  {
    [_delegate clippyViewGotDragEnter:self];
    return NSDragOperationCopy;
  }
  return NSDragOperationNone;
}

- (void)draggingExited:(id<NSDraggingInfo>)sender
{
  [_delegate clippyViewGotDragExit:self];
}

@end

@implementation InfinitClippyViewController
{
@private
  id<InfinitClippyProtocol> _delegate;
  NSMutableArray* _clippy_images;
  BOOL _animating;
  NSDictionary* _attrs;
  NSDictionary* _bold_attrs;
}

//- Initialisation ---------------------------------------------------------------------------------

@synthesize mode = _mode;

- (id)initWithDelegate:(id<InfinitClippyProtocol>)delegate
               andMode:(InfinitClippyMode)mode
{
  if (self = [super initWithNibName:self.className bundle:nil])
  {
    _delegate = delegate;
    _clippy_images = [NSMutableArray array];
    for (NSInteger i = 1; i <= 10; i++)
    {
      NSString* image_name = [NSString stringWithFormat:@"clippy_%ld", i];
      [_clippy_images addObject:[IAFunctions imageNamed:image_name]];
      _animating = NO;
      _mode = mode;
      NSFont* font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica"
                                                                traits:NSUnboldFontMask
                                                                weight:1
                                                                  size:13.0];
      NSFont* bold_font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica"
                                                                     traits:NSBoldFontMask
                                                                     weight:5
                                                                       size:13.0];
      
      _attrs = [IAFunctions textStyleWithFont:font
                               paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                       colour:IA_GREY_COLOUR(32.0)
                                       shadow:nil];
      _bold_attrs = [IAFunctions textStyleWithFont:bold_font
                                    paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                            colour:IA_GREY_COLOUR(32.0)
                                            shadow:nil];
    }
  }
  return self;
}

- (BOOL)closeOnFocusLost
{
  return NO;
}

- (void)setDoneButton
{
  NSMutableParagraphStyle* style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
  style.alignment = NSCenterTextAlignment;
  NSShadow* shadow = [IAFunctions shadowWithOffset:NSMakeSize(0.0, -1.0)
                                        blurRadius:1.0
                                            colour:[NSColor blackColor]];
  
  NSDictionary* button_style = [IAFunctions textStyleWithFont:[NSFont boldSystemFontOfSize:13.0]
                                               paragraphStyle:style
                                                       colour:[NSColor whiteColor]
                                                       shadow:shadow];
  self.done_button.attributedTitle =
    [[NSAttributedString alloc] initWithString:NSLocalizedString(@"GOT IT", nil)
                                    attributes:button_style];
  self.done_button.enabled = YES;
}

- (void)animateClippy
{
  CAKeyframeAnimation* kfa = [CAKeyframeAnimation animation];
  kfa.values = _clippy_images;
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
   {
     context.duration = 1.0;
     _clippy_image.animations = @{@"image": kfa};
     _clippy_image.animator.image = _clippy_images[_clippy_images.count - 1];
   }
                      completionHandler:^
   {
     if (_animating)
       [self animateClippy];
   }];
}

- (void)configureTransferPending
{
  NSString* line_1_str = NSLocalizedString(@"You have", nil);
  NSString* line_2_str = NSLocalizedString(@"1 transfer", nil);
  NSString* line_3_str = NSLocalizedString(@"pending.", nil);
  _line_1.attributedStringValue = [[NSAttributedString alloc] initWithString:line_1_str
                                                                  attributes:_attrs];
  _line_2.attributedStringValue = [[NSAttributedString alloc] initWithString:line_2_str
                                                                  attributes:_bold_attrs];
  _line_3.attributedStringValue = [[NSAttributedString alloc] initWithString:line_3_str
                                                                  attributes:_attrs];
}

- (void)configureDragAndDrop
{
  NSString* line_1_str = NSLocalizedString(@"Drag & Drop", nil);
  NSString* line_2_str = NSLocalizedString(@"on the icon", nil);
  NSString* line_3_str = NSLocalizedString(@"to send a file.", nil);
  _line_1.attributedStringValue = [[NSAttributedString alloc] initWithString:line_1_str
                                                                  attributes:_attrs];
  _line_2.attributedStringValue = [[NSAttributedString alloc] initWithString:line_2_str
                                                                  attributes:_bold_attrs];
  _line_3.attributedStringValue = [[NSAttributedString alloc] initWithString:line_3_str
                                                                  attributes:_attrs];
  if (self.view.window.alphaValue < 1.0)
  {
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
     {
       [self.view.window.animator setAlphaValue:1.0];
     }
                        completionHandler:^
     {
       self.view.window.alphaValue = 1.0;
     }];
  }
}

- (void)configureHigher
{
  NSString* line_1_str = NSLocalizedString(@"", nil);
  NSString* line_2_str = NSLocalizedString(@"Higher", nil);
  NSString* line_3_str = NSLocalizedString(@".", nil);
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
   {
     _line_1.attributedStringValue = [[NSAttributedString alloc] initWithString:line_1_str
                                                                     attributes:_attrs];
     _line_2.attributedStringValue = [[NSAttributedString alloc] initWithString:line_2_str
                                                                     attributes:_bold_attrs];
     _line_3.attributedStringValue = [[NSAttributedString alloc] initWithString:line_3_str
                                                                     attributes:_attrs];
     [self.view.window.animator setAlphaValue:0.6];
   }
                      completionHandler:^
   {
     self.view.window.alphaValue = 0.6;
   }];
  
}

- (void)awakeFromNib
{
  [self setDoneButton];
  switch (_mode)
  {
    case INFINIT_CLIPPY_TRANSFER_PENDING:
      [self configureTransferPending];
      break;
      
    case INFINIT_CLIPPY_DRAG_AND_DROP:
      [self configureDragAndDrop];
      break;
      
    case INFINIT_CLIPPY_HIGHER:
      [self configureHigher];
      break;
      
    default:
      break;
  }
}

- (void)loadView
{
  [super loadView];
  [self.clippy_view setDelegate:self];
  _animating = YES;
  [self animateClippy];
  [self.line_1 unregisterDraggedTypes];
  [self.line_2 unregisterDraggedTypes];
  [self.line_3 unregisterDraggedTypes];
  [self.clippy_image unregisterDraggedTypes];
  [self.arrow_image unregisterDraggedTypes];
}

//- Button Handling --------------------------------------------------------------------------------

- (IBAction)doneButtonClicked:(NSButton*)sender
{
  [_delegate clippyViewGotDoneClicked:self];
}

//- View Handling ----------------------------------------------------------------------------------

- (void)aboutToChangeView
{
  _animating = NO;
}

//- Clippy View Protocol ---------------------------------------------------------------------------

- (void)clippyViewGotDragEnter:(InfinitClippyView*)sender
{
  if (_mode == INFINIT_CLIPPY_DRAG_AND_DROP)
  {
    _mode = INFINIT_CLIPPY_HIGHER;
    [self configureHigher];
  }
}

- (void)clippyViewGotDragExit:(InfinitClippyView*)sender
{
  if (_mode == INFINIT_CLIPPY_HIGHER)
  {
    _mode = INFINIT_CLIPPY_DRAG_AND_DROP;
    [self configureDragAndDrop];
  }
}

@end
