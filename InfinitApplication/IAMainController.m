//
//  IAMainController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 7/26/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAMainController.h"

@implementation IAMainController

static IAMainController* _instance;

//- Initiailisation --------------------------------------------------------------------------------

- (id)init
{
    if (self = [super init])
    {
        _status_item = [[NSStatusBar systemStatusBar] statusItemWithLength:34.0];
        _status_item.view = [[IAStatusBarIcon alloc] initWithDelegate:self statusItem:_status_item];
        _view_controller = [[IAMainViewController alloc] initWithDelegate:self];
    }
    return self;
}

+ (IAMainController*)instance
{
    if (_instance == nil)
    {
        _instance = [[IAMainController alloc] init];
    }
    return _instance;
}

//- Handle views -----------------------------------------------------------------------------------

- (void)showNotifications
{
    
}

- (void)showNotLoggedInView
{
    IANotLoggedInView* view_controller = [[IANotLoggedInView alloc] initWithDelegate:self];
    if ([_view_controller isOpen])
    {
    }
    else
    {
        [_view_controller openWithView:(NSView*)view_controller.view
                              onScreen:[self currentScreen]
                          withMidpoint:[self statusBarIconMiddle]];
    }
    
}

//- General functions ------------------------------------------------------------------------------

// Current screen to display content on
- (NSScreen*)currentScreen
{
    return _status_item.view.window.screen;
}

// Midpoint of status bar icon
- (NSPoint)statusBarIconMiddle
{
    NSRect frame = _status_item.view.window.frame;
    NSPoint result = NSMakePoint(floor(frame.origin.x + frame.size.width / 2.0),
                                 floor(frame.origin.y - 5.0));
    return result;
}


//- State machines ---------------------------------------------------------------------------------

- (void)statusBarIconClickStateMachine
{
    [self showNotLoggedInView];
}

//- Status bar icon protocol -----------------------------------------------------------------------

- (void)statusBarIconClicked:(IAStatusBarIcon*)status_bar_icon
{
    if ([status_bar_icon isHighlighted])
    {
        [status_bar_icon setHighlighted:NO];
        [_view_controller close];
    }
    else
    {
        [status_bar_icon setHighlighted:YES];
        [self statusBarIconClickStateMachine];
    }
}

- (void)statusBarIconDragEntered:(IAStatusBarIcon*)status_bar_icon
{
    
}

@end
