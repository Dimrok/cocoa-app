//
//  IAMainViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 7/26/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAMainViewController.h"

@interface IAMainViewController ()

@end

@implementation IAMainWindow

- (BOOL)canBecomeKeyWindow
{
    return YES;
}

@end

@implementation IAMainViewController

@synthesize isOpen = _is_open;

+ (IAMainWindow*)windowWithFrame:(NSRect)frame screen:(NSScreen*)screen
{
    IAMainWindow* result = [[IAMainWindow alloc] initWithContentRect:frame
                                                           styleMask:NSBorderlessWindowMask
                                                             backing:NSBackingStoreBuffered
                                                               defer:YES
                                                              screen:screen];
    result.backgroundColor = [NSColor clearColor];
    result.alphaValue = 1.0;
    return result;
}

- (id)initWithDelegate:(id<IAMainViewControllerProtocol>)delegate
{
    if (self = [super initWithNibName:[self className] bundle:nil])
    {
        _delegate = delegate;
    }
    return self;
}

- (void)openWithView:(NSView*)view onScreen:(NSScreen*)screen withMidpoint:(NSPoint)midpoint
{
    if (view == nil)
        return;
    
    _is_open = YES;
    
    NSRect frame;
    frame.size = view.frame.size;
    frame.origin = NSMakePoint(floor(midpoint.x - view.frame.size.width / 2.0),
                               floor(midpoint.y - view.frame.size.height));
    
    _window = [IAMainViewController windowWithFrame:frame screen:screen];
    _window.delegate = self;
    _window.alphaValue = 0.0;
    _window.contentView = view;
    [_window makeKeyAndOrderFront:nil];
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
     {
         context.duration = 0.25;
         [(NSWindow*)_window.animator setAlphaValue:1.0];
     }
                        completionHandler:^
     {
     }];
    
}

- (void)switchToView:(NSView*)view onScreen:(NSScreen*)screen
{
    
}

- (void)close
{
    if (_window == nil)
        return;
    
    _is_open = NO;
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
     {
         context.duration = 0.25;
         [(NSWindow*)_window.animator setAlphaValue:0.0];
     }
                        completionHandler:^
     {
         [_window orderOut:nil];
         _window = nil;
     }];
    
}

@end
