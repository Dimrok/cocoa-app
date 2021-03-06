//
//  IANoConnectionViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 9/2/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IANoConnectionViewController.h"

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("OSX.NoConnectionViewController");

@interface IANoConnectionViewController ()

@end

@interface IANoConnectionView : IAMainView
@end

@implementation IANoConnectionView

- (void)drawRect:(NSRect)dirtyRect
{
  NSBezierPath* path = [NSBezierPath bezierPathWithRect:self.bounds];
  [IA_GREY_COLOUR(248.0) set];
  [path fill];
}

- (NSSize)intrinsicContentSize
{
  return self.bounds.size;
}

@end

@implementation IANoConnectionViewController
{
@private
  id<IANoConnectionViewProtocol> _delegate;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithDelegate:(id<IANoConnectionViewProtocol>)delegate
{
  if (self = [super initWithNibName:[self className] bundle:nil])
  {
    _delegate = delegate;
  }
  return self;
}

- (BOOL)closeOnFocusLost
{
  return YES;
}

- (void)awakeFromNib
{
  NSMutableParagraphStyle* style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
  style.alignment = NSCenterTextAlignment;
  NSFont* font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica"
                                                            traits:NSUnboldFontMask
                                                            weight:0
                                                              size:12.0];
  NSDictionary* message_attrs = [IAFunctions textStyleWithFont:font
                                                paragraphStyle:style
                                                        colour:IA_GREY_COLOUR(32.0)
                                                        shadow:nil];
  NSString* message = NSLocalizedString(@"Need an Internet connection to send...",
                                        @"need an internet connection to send");

  self.no_connection_message.attributedStringValue = [[NSAttributedString alloc]
                                                      initWithString:message
                                                      attributes:message_attrs];
}

- (void)loadView
{
  ELLE_TRACE("%s: loadview", self.description.UTF8String);
  [super loadView];
  [self.view layoutSubtreeIfNeeded];
}

//- User Interaction -------------------------------------------------------------------------------

- (IBAction)backButtonClicked:(NSButton*)sender
{
  [_delegate noConnectionViewWantsBack:self];
}

@end
