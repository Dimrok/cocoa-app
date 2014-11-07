//
//  IANotLoggedInView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 7/26/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IANotLoggedInViewController.h"

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("OSX.NotLoggedInViewController");

@interface IANotLoggedInViewController ()
@end

@interface NSButtonCell(Private)
- (void)_updateMouseTracking;
@end

@implementation InfinitNotLoggedInButtonCell
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

- (void)drawImage:(NSImage*)image
        withFrame:(NSRect)frame
           inView:(NSView*)controlView
{
  [super drawImage:image withFrame:frame inView:controlView];
  NSBezierPath* bg = [IAFunctions roundedBottomBezierWithRect:frame cornerRadius:3.0];
  if ([self isEnabled] && _hover && ![self isHighlighted])
    [IA_RGBA_COLOUR(255, 255, 255, 0.1) set];
  else if ([self isEnabled] && [self isHighlighted])
    [IA_RGBA_COLOUR(0, 0, 0, 0.1) set];
  else
    [[NSColor clearColor] set];
  [bg fill];
}

@end

@interface IANotLoggedInView : NSView
@end

@implementation IANotLoggedInView

- (void)drawRect:(NSRect)dirtyRect
{
  NSBezierPath* path = [NSBezierPath bezierPathWithRect:self.bounds];
  [IA_GREY_COLOUR(248.0) set];
  [path fill];
}

@end

@implementation IANotLoggedInViewController
{
@private
  id<IANotLoggedInViewProtocol> _delegate;
  NSDictionary* _link_attrs;
  NSDictionary* _link_hover_attrs;
  NSDictionary* _message_attrs;
  NSDictionary* _button_style;
}

//- Initialisation ---------------------------------------------------------------------------------

@synthesize mode = _mode;

- (id)initWithMode:(IANotLoggedInViewMode)mode
       andDelegate:(id<IANotLoggedInViewProtocol>)delegate;
{
  if (self = [super initWithNibName:[self className] bundle:nil])
  {
    _delegate = delegate;
    _mode = mode;
    NSMutableParagraphStyle* style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    style.alignment = NSCenterTextAlignment;
    NSFont* message_font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica"
                                                                      traits:NSUnboldFontMask
                                                                      weight:0
                                                                        size:12.0];
    _message_attrs = [IAFunctions textStyleWithFont:message_font
                                     paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                             colour:IA_GREY_COLOUR(32.0)
                                             shadow:nil];

    NSShadow* shadow = [IAFunctions shadowWithOffset:NSMakeSize(0.0, -1.0)
                                          blurRadius:1.0
                                              colour:[NSColor blackColor]];

    _button_style = [IAFunctions textStyleWithFont:[NSFont boldSystemFontOfSize:13.0]
                                    paragraphStyle:style
                                            colour:[NSColor whiteColor]
                                            shadow:shadow];

    NSFont* link_font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica"
                                                                   traits:NSUnboldFontMask
                                                                   weight:0
                                                                     size:11.0];
    _link_attrs = [IAFunctions  textStyleWithFont:link_font
                                   paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                           colour:IA_RGB_COLOUR(103.0, 181.0, 214.0)
                                           shadow:nil];

    _link_hover_attrs = [IAFunctions textStyleWithFont:link_font
                                        paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                                colour:IA_RGB_COLOUR(11.0, 117.0, 162)
                                                shadow:nil];
  }
  return self;
}

- (void)awakeFromNib
{
  [self configureForMode:_mode];
}

- (void)configureForMode:(IANotLoggedInViewMode)mode
{
  NSString* message;
  NSString* button_text;
  NSString* problem = NSLocalizedString(@"Problem?", nil);
  [self.spinner startAnimation:nil];
  self.problem_button.attributedTitle = [[NSAttributedString alloc] initWithString:problem
                                                                        attributes:_link_attrs];
  [self.problem_button setHoverTextAttributes:_link_hover_attrs];
  [self.problem_button setNormalTextAttributes:_link_attrs];
  [self.problem_button setToolTip:NSLocalizedString(@"Click to tell us!", @"click to tell us")];
  button_text = NSLocalizedString(@"QUIT", nil);
  [self.bottom_button setEnabled:YES];
  if (_mode == INFINIT_LOGGING_IN)
    message = NSLocalizedString(@"Logging in...", nil);
  else if (_mode == INFINIT_WAITING_FOR_CONNECTION)
    message = NSLocalizedString(@"Trying to login...", nil);
  self.not_logged_message.attributedStringValue = [[NSAttributedString alloc]
                                                   initWithString:message
                                                   attributes:_message_attrs];

  self.bottom_button.attributedTitle = [[NSAttributedString alloc]
                                        initWithString:button_text
                                        attributes:_button_style];
}

- (BOOL)closeOnFocusLost
{
  return YES;
}

- (void)loadView
{
  ELLE_TRACE("%s: loadview for mode: %d", self.description.UTF8String, _mode);
  [super loadView];
}

//- General Functions ------------------------------------------------------------------------------

- (void)setMode:(IANotLoggedInViewMode)mode
{
  _mode = mode;
  [self configureForMode:mode];
}

//- User Interaction -------------------------------------------------------------------------------

- (IBAction)bottomButtonClicked:(NSButton*)sender
{
  [_delegate notLoggedInViewWantsQuit:self];
}

- (IBAction)onProblemClick:(NSButton*)sender
{
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"mailto:support@infinit.io?Subject=Login%20Connection%20Problem"]];
}

@end