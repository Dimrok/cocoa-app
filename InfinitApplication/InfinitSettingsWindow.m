//
//  InfinitSettingsWindow.m
//  InfinitApplication
//
//  Created by Christopher Crone on 21/08/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitSettingsWindow.h"

@interface InfinitSettingsWindow ()

@end

@implementation InfinitSettingsWindow
{
@private
  __weak id<InfinitSettingsProtocol> _delegate;

  InfinitSettingsAccountView* _account_view;
  InfinitSettingsGeneralView* _general_view;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithDelegate:(id<InfinitSettingsProtocol>)delegate
{
  if (self = [super initWithWindowNibName:self.className])
  {
    _delegate = delegate;
    _account_view = [[InfinitSettingsAccountView alloc] initWithDelegate:self];
    _general_view = [[InfinitSettingsGeneralView alloc] initWithDelegate:self];
    self.window.level = NSFloatingWindowLevel;
  }
  return self;
}

- (void)windowDidLoad
{
  [self.window center];
  [super windowDidLoad];
  self.account_button.enabled = YES;
  self.general_button.enabled = YES;
  [self changeToViewController:_general_view withAnimation:NO];
  self.toolbar.selectedItemIdentifier = @"general_toolbar_item";
}

//- General Functions ------------------------------------------------------------------------------

- (void)show
{
  [_account_view loadData];
  self.toolbar.selectedItemIdentifier = @"general_toolbar_item";
  [self changeToViewController:_general_view withAnimation:NO];
  [self showWindow:self];
}

- (void)close
{
  if (self.window == nil)
    return;

  [self.window close];
}

//- View Change Handling ---------------------------------------------------------------------------

- (void)changeToViewController:(NSViewController*)controller
                 withAnimation:(BOOL)animate
{
  CGFloat d_height =
    [(InfinitSettingsViewController*)controller startSize].height - [self.window.contentView frame].size.height;
  self.window.contentView = controller.view;
  NSRect new_rect = NSMakeRect(self.window.frame.origin.x,
                               self.window.frame.origin.y - d_height,
                               self.window.frame.size.width, self.window.frame.size.height + d_height);
  [self.window setFrame:new_rect display:YES animate:YES];
}

- (IBAction)accountClicked:(NSToolbarItem*)sender
{
  [self changeToViewController:_account_view withAnimation:YES];
}

- (IBAction)generalClicked:(NSToolbarItem*)sender
{
  [self changeToViewController:_general_view withAnimation:YES];
}

//- Account View Protocol --------------------------------------------------------------------------

- (NSWindow*)getWindow:(InfinitSettingsAccountView*)sender
{
  return self.window;
}

//- General View Protocol --------------------------------------------------------------------------

- (BOOL)infinitInLoginItems:(InfinitSettingsGeneralView*)sender
{
  return [_delegate infinitInLoginItems:self];
}

- (void)setInfinitInLoginItems:(InfinitSettingsGeneralView*)sender
                            to:(BOOL)value
{
  [_delegate setInfinitInLoginItems:self to:value];
}

- (BOOL)uploadsScreenshots:(InfinitSettingsGeneralView*)sender
{
  return [_delegate uploadsScreenshots:self];
}

- (void)setUploadsScreenshots:(InfinitSettingsGeneralView*)sender
                           to:(BOOL)value
{
  [_delegate setUploadsScreenshots:self to:value];
}

- (BOOL)stayAwake:(InfinitSettingsGeneralView*)sender
{
  return [_delegate stayAwake:self];
}

- (void)setStayAwake:(InfinitSettingsGeneralView*)sender
                  to:(BOOL)value
{
  [_delegate setStayAwake:self to:value];
}

- (void)checkForUpdate:(InfinitSettingsGeneralView*)sender
{
  [_delegate checkForUpdate:self];
}

//- Window Delegate --------------------------------------------------------------------------------

- (BOOL)windowShouldClose:(id)sender
{
  return YES;
}

@end
