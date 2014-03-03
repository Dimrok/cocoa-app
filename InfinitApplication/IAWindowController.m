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

@interface IANotificationWindow : NSWindow
@end

@implementation IANotificationWindow

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

@end

//- Content View -----------------------------------------------------------------------------------

@interface IANotificationContentView : NSView
@end

@implementation IANotificationContentView

@end

//- Window Controller ------------------------------------------------------------------------------

@implementation IAWindowController
{
@private
    id<IAWindowControllerProtocol> _delegate;
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
    if (!_window_is_open || _animating)
        return;
    
    _window_is_open = NO;
    _animating = YES;
    
    [self.window.contentView removeConstraints:_view_constraints];
    
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
         [_delegate windowController:self
            hasCurrentViewController:nil];
         _animating = NO;
     }];
}

- (void)openWindow
{
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    [self.window makeKeyAndOrderFront:nil];
    [self.window setLevel:NSFloatingWindowLevel];
     
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
     {
         context.duration = 0.15;
         [(NSWindow*)self.window.animator setAlphaValue:1.0];
     }
                        completionHandler:^
     {
         self.window.alphaValue = 1.0;
         [_delegate windowController:self
            hasCurrentViewController:_current_controller];
         _animating = NO;
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
    [new_controller viewChanged];
    
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
     [_delegate windowController:self
        hasCurrentViewController:_current_controller];
     
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
    
    [controller viewChanged];
    
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

@end
