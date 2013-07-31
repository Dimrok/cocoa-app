//
//  IAMainViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 7/26/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol IAMainViewControllerProtocol;

@interface IAMainWindow : NSWindow
@end

@interface IAMainViewController : NSViewController <NSWindowDelegate>
{
@private
    id<IAMainViewControllerProtocol> _delegate;
    IAMainWindow* _window;
    NSView* _main_view;
    BOOL _is_open;
}

@property(nonatomic, readonly) BOOL isOpen;

- (id)initWithDelegate:(id<IAMainViewControllerProtocol>)delegate;

- (void)close;

- (void)openWithView:(NSView*)view
            onScreen:(NSScreen*)screen
        withMidpoint:(NSPoint)midpoint;

- (void)switchToView:(NSView*)view
            onScreen:(NSScreen*)screen;

@end

@protocol IAMainViewControllerProtocol <NSObject>
@end