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
        
        _login_view_controller = [[IALoginViewController alloc] initWithDelegate:self];
        
        [_login_view_controller showLoginWindowOnScreen:[self currentScreen]];
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
        
        NSString* password = [[NSString alloc] initWithBytes:pwd_ptr
                                                      length:pwd_len
                                                    encoding:NSUTF8StringEncoding];
        if (password.length == 0)
            return NO;
        
        [self loginWithUsername:login_email password:password];
        
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

//- Login and Logout -------------------------------------------------------------------------------

- (void)loginWithUsername:(NSString*)username password:(NSString*)password
{
    NSString* device_name = @"TODO"; // XXX use NSHost to get device name
    
    [[IAGapState instance] login:username
                    withPassword:password
                   andDeviceName:device_name
                 performSelector:@selector(loginCallback:)
                        onObject:self];
    password = @"";
    password = nil;
}

- (void)loginCallback:(IAGapOperationResult*)result
{
    if (result.success)
    {
        IALog(@"%@ Logged in", self);
        if ([_login_view_controller loginWindowOpen])
            [_login_view_controller closeLoginWindow];
    }
    else
    {
        IALog(@"%@ ERROR: Couldn't login with status: %d", self, result.status);
        NSString* error;
        switch (result.status)
        {
            case gap_network_error:
                error = NSLocalizedString(@"Connection problem", @"no route to internet");
                break;
            case gap_email_password_dont_match:
                error = NSLocalizedString(@"Username or password incorrect",
                                          @"username or password wrong");
                break;
            default:
                error = NSLocalizedString(@"Unknown login error", @"unknown login error");
                break;
        }
        [_login_view_controller showLoginWindowOnScreen:[self currentScreen]
                                              withError:error];
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

//- General Functions ------------------------------------------------------------------------------

// Current screen to display content on
- (NSScreen*)currentScreen
{
    return [[NSScreen screens] objectAtIndex:0];
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

//- Login window protocol --------------------------------------------------------------------------

- (void)tryLogin:(IALoginViewController*)sender
        username:(NSString*)username
        password:(NSString*)password
{
    if (sender == _login_view_controller)
    {
        [self loginWithUsername:username password:password];
    }
}

@end
