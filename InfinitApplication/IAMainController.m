//
//  IAMainController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 7/26/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAMainController.h"

#import <Gap/IAGapState.h>
#import "IAGap.h"
#import "IAKeychainManager.h"
#import "IAUserPrefs.h"

@implementation IAMainController

static IAMainController* _instance;

//- Initiailisation --------------------------------------------------------------------------------

- (id)initWithDelegate:(id<IAMainControllerProtocol>)delegate
{
    if (self = [super init])
    {
        _delegate = delegate;
        _status_item = [[NSStatusBar systemStatusBar] statusItemWithLength:34.0];
        _status_item.view = [[IAStatusBarIcon alloc] initWithDelegate:self statusItem:_status_item];
        _view_controller = [[IAMainViewController alloc] initWithDelegate:self];
        
        IAGap* state = [[IAGap alloc] init];
        [IAGapState setupWithProtocol:state];
    }
    return self;
}

- (NSString*)description
{
    NSString* res = [NSString stringWithFormat:@"[MainController]"];
    return res;
}

- (BOOL)tryAutomaticLogin
{
    NSString* login_email = [[IAUserPrefs sharedInstance] prefsForKey:@"user:email"];
    
    if (login_email == nil ||
        [login_email isEqualToString:@""] ||
        [[IAKeychainManager sharedInstance] CredentialsInKeychain:login_email])
    {
        return NO;
    }
    
    void* pwd_ptr = NULL;
    UInt32 pwd_len = 0;
    OSStatus status;
    status = [[IAKeychainManager sharedInstance] GetPasswordKeychain:login_email
                                                        passwordData:&pwd_ptr
                                                      passwordLength:&pwd_len
                                                             itemRef:NULL];
    if (status == noErr)
    {
        if (pwd_ptr == NULL)
            return NO;
        
        NSString* device_name = @"TODO"; // XXX use NSHost to get device name
        NSString* password = [[NSString alloc] initWithBytes:pwd_ptr
                                                      length:pwd_len
                                                    encoding:NSUTF8StringEncoding];
        if (password.length == 0)
            return NO;
        
        [[IAGapState instance] login:login_email
                        withPassword:password
                       andDeviceName:device_name
                     performSelector:@selector(loginCallback:)
                            onObject:self];
        password = @"";
        password = nil;
        return YES;
    }
    return NO;
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

- (void)openLoginWindow
{
    
}

//- General functions ------------------------------------------------------------------------------

- (void)loginCallback:(IAGapOperationResult*)result
{
    if (result.success)
    {
        IALog(@"%@ Logged in", self);
    }
    else
    {
        [self openLoginWindow];
    }
}

- (void)logoutCallback:(IAGapOperationResult*)result
{
    if (result.success)
        IALog(@"%@ Logged out", self);
    else
        IALog(@"%@ WARNING: Logout failed", self);
}

- (void)logoutAndQuitCallback:(IAGapOperationResult*)result
{
    [self logoutCallback:result];
    [[IAGapState instance] freeGap];
    [_delegate quitApplication:self];
}

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

- (void)handleQuit
{
    if ([[IAGapState instance] logged_in])
    {
        [[IAGapState instance] logout:@selector(logoutAndQuitCallback:)
                             onObject:self];
    }
    else
    {
        [[IAGapState instance] freeGap];
        [_delegate quitApplication:self];
    }
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
