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

@interface IANotificationWindow : NSWindow
@end

@implementation IANotificationWindow

- (id)initWithContentRect:(NSRect)contentRect
                styleMask:(NSUInteger)aStyle
                  backing:(NSBackingStoreType)bufferingType
                    defer:(BOOL)flag
{
    if (self = [super initWithContentRect:contentRect
                                styleMask:aStyle
                                  backing:bufferingType
                                    defer:flag])
    {
        self.alphaValue = 0.0;
        self.backgroundColor = [NSColor clearColor];
        self.hasShadow = YES;
        self.opaque = NO;
    }
    return self;
}


- (BOOL)canBecomeKeyWindow
{
    return YES;
}


@end

@implementation IAWindowController
{
@private
    id<IAWindowControllerProtocol> _delegate;
    BOOL _window_is_open;
    IAViewController* _current_controller;
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
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (NSString*)description
{
    return @"[WindowController]";
}

//- Window Handling --------------------------------------------------------------------------------

- (void)closeWindow
{
    if (!_window_is_open)
        return;
    
    _window_is_open = NO;
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
     {
         context.duration = 0.25;
         [(NSWindow*)self.window.animator setAlphaValue:0.0];
     }
                        completionHandler:^
     {
         self.window.alphaValue = 0.0;
         [self.window orderOut:nil];
         [_current_controller.view removeFromSuperview];
     }];
}

- (void)openWindow
{
    if (_window_is_open)
        return;
    
    _window_is_open = YES;
    [self.window makeKeyAndOrderFront:nil];
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
     {
         context.duration = 0.25;
         [(NSWindow*)self.window.animator setAlphaValue:1.0];
     }
                        completionHandler:^
     {
         self.window.alphaValue = 1.0;
     }];
}

- (void)windowDidResignKey:(NSNotification*)notification
{
    if (self.window != notification.object)
        return;
    [_delegate windowControllerWantsCloseWindow:self];
}

//- View Handling ----------------------------------------------------------------------------------

- (void)changeToViewController:(IAViewController*)new_controller
{
    NSSize new_size = new_controller.view.frame.size;
    CGFloat y_diff = _current_controller.view.frame.size.height -
                     new_controller.view.frame.size.height;
    NSPoint midpoint = NSMakePoint(self.window.frame.origin.x,
                                   self.window.frame.origin.y + y_diff);
    [self.window setFrame:NSMakeRect(midpoint.x, midpoint.y, new_size.width, new_size.height)
                  display:YES
                  animate:YES];
    [self.window.contentView addSubview:new_controller.view];
    [_current_controller.view removeFromSuperview];
    _current_controller = nil;
    _current_controller = new_controller;
}

- (void)openWithViewController:(IAViewController*)controller
                  withMidpoint:(NSPoint)midpoint
{
    if (controller == nil)
        return;
    
    _current_controller = controller;
    
    NSRect frame;
    frame.size = controller.view.frame.size;
    frame.origin = NSMakePoint(floor(midpoint.x - controller.view.frame.size.width / 2.0),
                               floor(midpoint.y - controller.view.frame.size.height));
    [self.window setFrame:frame display:NO animate:NO];
    
    [self.window.contentView addSubview:controller.view];
    
    [self openWindow];
    
}


@end
