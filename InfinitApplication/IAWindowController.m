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
    NSMutableArray* _view_constraints;
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

- (NSString*)description
{
    return @"[WindowController]";
}

//- Window Handling --------------------------------------------------------------------------------

- (void)closeWindow
{
    if (!_window_is_open)
        return;
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
     {
         context.duration = 0.25;
         [(NSWindow*)self.window.animator setAlphaValue:0.0];
     }
                        completionHandler:^
     {
         _window_is_open = NO;
         self.window.alphaValue = 0.0;
         [self.window orderOut:nil];
         [self.window close];
         [_current_controller.view removeFromSuperview];
     }];
}

- (void)openWindow
{
    if (_window_is_open)
        return;
    
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    [self.window makeKeyAndOrderFront:nil];
    [self.window setLevel:NSFloatingWindowLevel];
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
     {
         context.duration = 0.25;
         [(NSWindow*)self.window.animator setAlphaValue:1.0];
     }
                        completionHandler:^
     {
         _window_is_open = YES;
         self.window.alphaValue = 1.0;
     }];
}

- (void)windowDidResignKey:(NSNotification*)notification
{
    if (self.window != notification.object)
        return;
    if ([_current_controller closeOnFocusLost])
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
    NSSize new_size = new_controller.view.frame.size;
    NSSize old_size = _current_controller.view.frame.size;
    CGFloat x_diff = new_size.width - old_size.width;
                                 
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
    {
        context.duration = 0.2;
        if (x_diff != 0)
        {
            [self.window.animator setFrameOrigin:
                                     NSMakePoint(self.window.frame.origin.x - (x_diff / 2.0),
                                                 self.window.frame.origin.y)];
        }
        if (new_size.height != old_size.height)
            [_current_controller.content_height_constraint.animator setConstant:new_size.height];
        if (new_size.width != old_size.width)
            [_current_controller.content_width_constraint.animator setConstant:new_size.width];
    }
                        completionHandler:^
     {
         [[self.window.contentView animator] replaceSubview:_current_controller.view
                                                       with:new_controller.view];
         [self.window.contentView removeConstraints:_view_constraints];
         
         [self.window display];
         [self.window invalidateShadow];
         
         _view_constraints = [NSMutableArray arrayWithArray:
                              [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|"
                                                 options:NSLayoutFormatDirectionLeadingToTrailing
                                                 metrics:nil
                                                   views:@{@"view": new_controller.view}]];
         
         [_view_constraints addObjectsFromArray:[NSLayoutConstraint
                                                 constraintsWithVisualFormat:@"H:|[view]|"
                                                 options:NSLayoutFormatDirectionLeadingToTrailing
                                                 metrics:nil
                                                 views:@{@"view": new_controller.view}]];
         
         [self.window.contentView addConstraints:_view_constraints];
         _current_controller = nil;
         _current_controller = new_controller;         
     }];
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
