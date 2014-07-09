//
//  IAWindowController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/1/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAWindowController.h"

@interface IAWindowController ()
@end

//- Notification Window ----------------------------------------------------------------------------

@protocol IANotificationWindowProtocol <NSObject>

- (void)notificationWindowGotEscapePressed:(IANotificationWindow*)sender;

@end

@interface IANotificationWindow : NSWindow

@property (nonatomic, readwrite) id <IANotificationWindowProtocol> keyboard_delegate;

@end

@implementation IANotificationWindow

@synthesize keyboard_delegate = _keyboard_delegate;

- (id)initWithContentRect:(NSRect)contentRect
                styleMask:(NSUInteger)aStyle
                  backing:(NSBackingStoreType)bufferingType
                    defer:(BOOL)flag
{
  if (self = [super initWithContentRect:contentRect
                              styleMask:NSBorderlessWindowMask
                                backing:NSBackingStoreBuffered
                                  defer:YES])
  {
    self.alphaValue = 0.0;
    self.backgroundColor = [NSColor clearColor];
    self.opaque = NO;
  }
  return self;
}


- (BOOL)canBecomeKeyWindow
{
  return YES;
}

- (void)cancelOperation:(id)sender
{
  [_keyboard_delegate notificationWindowGotEscapePressed:self];
}

@end

//- Content View -----------------------------------------------------------------------------------

@interface IANotificationContentView : NSView
@end

@implementation IANotificationContentView

- (BOOL)wantsUpdateLayer
{
  return NO;
}

@end

//- Window Controller ------------------------------------------------------------------------------

@implementation IAWindowController
{
@private
  // WORKAROUND: 10.7 doesn't allow weak references to certain classes (like NSViewController)
  __unsafe_unretained id<IAWindowControllerProtocol> _delegate;
  BOOL _window_is_open;
  IAViewController* _current_controller;
  NSMutableArray* _view_constraints;
  BOOL _animating;
}

//- Initialisation ---------------------------------------------------------------------------------

@synthesize windowIsOpen = _window_is_open;

- (id)initWithDelegate:(id<IAWindowControllerProtocol>)delegate
{
  if (self = [super initWithWindowNibName:self.className])
  {
    _delegate = delegate;
    _window_is_open = NO;
  }
  return self;
}

- (void)windowDidLoad
{
  [super windowDidLoad];
}

//- Window Handling --------------------------------------------------------------------------------

- (void)closeWindow
{
  [self closeWindowWithAnimation:YES];
  NSPoint mouse_loc = [NSEvent mouseLocation];
  for (NSScreen* screen in [NSScreen screens])
  {
    if (mouse_loc.y > NSHeight(screen.frame) - [[NSStatusBar systemStatusBar] thickness])
      return;
  }
  for (NSRunningApplication* app in [[NSWorkspace sharedWorkspace] runningApplications])
  {
    if (app.ownsMenuBar)
    {
      [app activateWithOptions:NSApplicationActivateAllWindows];
    }
  }
}

- (void)closeWindowWithoutLosingFocus
{
  [self closeWindowWithAnimation:YES];
}

- (void)closeWindowWithAnimation:(BOOL)animate
{
  if (!animate)
  {
    [self.window close];
    return;
  }

  if (!_window_is_open || _animating)
    return;
  
  _window_is_open = NO;
  _animating = YES;
  
  [_current_controller aboutToChangeView];
  
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
   {
     context.duration = 0.15;
     [(NSWindow*)self.window.animator setAlphaValue:0.0];
   }
                      completionHandler:^
   {
     self.window.alphaValue = 0.0;
     [self.window orderOut:nil];
     [self.window close];
     [_current_controller.view removeFromSuperview];
     _animating = NO;
     _current_controller = nil;
     [_delegate windowController:self hasCurrentViewController:_current_controller];
   }];
}

- (void)openWindow
{
  [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
  [self.window makeKeyAndOrderFront:nil];
  [self.window setLevel:NSFloatingWindowLevel];
  
  [(IANotificationWindow*)self.window setKeyboard_delegate:self];
  
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
   {
     context.duration = 0.15;
     [(NSWindow*)self.window.animator setAlphaValue:1.0];
   }
                      completionHandler:^
   {
     self.window.alphaValue = 1.0;
     [_delegate windowController:self hasCurrentViewController:_current_controller];
     _animating = NO;
     [_current_controller viewActive];
   }];
}

- (void)windowDidResignKey:(NSNotification*)notification
{
  if (self.window != notification.object)
    return;
  if ([_current_controller closeOnFocusLost] && !_animating)
    [_delegate windowControllerWantsCloseWindow:self];
}

- (void)windowDidResize:(NSNotification*)notification
{
  [self.window display];
  [self.window invalidateShadow];
}

//- View Handling ----------------------------------------------------------------------------------

- (void)changeToViewController:(IAViewController*)new_controller
{
  if (!_window_is_open || _animating)
    return;
  
  _animating = YES;
  
  [_current_controller aboutToChangeView];
  
  [self.window.contentView replaceSubview:_current_controller.view
                                     with:new_controller.view];
  
  _view_constraints = [NSMutableArray arrayWithArray:
                       [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|"
                                                               options:NSLayoutFormatDirectionLeadingToTrailing
                                                               metrics:nil
                                                                 views:@{@"view": new_controller.view}]];
  
  [_view_constraints addObjectsFromArray:
   [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|"
                                           options:NSLayoutFormatDirectionLeadingToTrailing
                                           metrics:nil
                                             views:@{@"view": new_controller.view}]];
  
  [self.window.contentView addConstraints:_view_constraints];
  _current_controller = nil;
  _current_controller = new_controller;
  [_delegate windowController:self hasCurrentViewController:_current_controller];
  [_current_controller viewActive];
  
  _animating = NO;
}

- (void)openWithViewController:(IAViewController*)controller
                  withMidpoint:(NSPoint)midpoint
{
  if (controller == nil || _window_is_open || _animating)
    return;
  
  _window_is_open = YES;
  _animating = YES;
  
  _current_controller = controller;
  
  NSRect frame;
  frame.size = controller.view.frame.size;
  frame.origin = NSMakePoint(floor(midpoint.x - controller.view.frame.size.width / 2.0),
                             floor(midpoint.y - controller.view.frame.size.height));
  [self.window setFrame:frame display:NO animate:NO];
  
  [self.window.contentView addSubview:controller.view];
  
  _view_constraints = [NSMutableArray arrayWithArray:
                       [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|"
                                                               options:NSLayoutFormatDirectionLeadingToTrailing
                                                               metrics:nil
                                                                 views:@{@"view": controller.view}]];
  [_view_constraints addObjectsFromArray:[NSLayoutConstraint
                                          constraintsWithVisualFormat:@"H:|[view]|"
                                          options:NSLayoutFormatDirectionLeadingToTrailing
                                          metrics:nil
                                          views:@{@"view": controller.view}]];

  [self.window.contentView addConstraints:_view_constraints];
  
  [self openWindow];
}

//- Window Keyboard Protocol -----------------------------------------------------------------------

- (void)notificationWindowGotEscapePressed:(IANotificationWindow*)sender
{
  [_delegate windowControllerWantsCloseWindow:self];
}

@end
