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
{
@private
    id<IAMainControllerProtocol> _delegate;
    
    NSStatusItem* _status_item;
    IAStatusBarIcon* _status_bar_icon;
    
    // View controllers
    IALoginViewController* _login_view_controller;
    IANotificationListViewController* _notification_view_controller;
    IANotLoggedInViewController* _not_logged_view_controller;
    IAGeneralSendController* _general_send_controller;
    IAWindowController* _window_controller;
    
    // Managers
    IATransactionManager* _transaction_manager;
    IAUserManager* _user_manager;
    
    // Other
    BOOL _new_credentials;
    NSString* _username;
    NSString* _password;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithDelegate:(id<IAMainControllerProtocol>)delegate
{
    if (self = [super init])
    {
        _delegate = delegate;
        
        IAGap* state = [[IAGap alloc] init];
        [IAGapState setupWithProtocol:state];
        
        _status_item = [[NSStatusBar systemStatusBar] statusItemWithLength:34.0];
        _status_bar_icon = [[IAStatusBarIcon alloc] initWithDelegate:self statusItem:_status_item];
        _status_item.view = _status_bar_icon;
        
        _general_send_controller = [[IAGeneralSendController alloc] initWithDelegate:self];
        
        _window_controller = [[IAWindowController alloc] initWithDelegate:self];
        
        _transaction_manager = [[IATransactionManager alloc] initWithDelegate:self];
        _user_manager = [[IAUserManager alloc] initWithDelegate:self];
        
        if (![self tryAutomaticLogin])
        {
            IALog(@"%@ Autologin failed", self);
            _login_view_controller = [[IALoginViewController alloc] initWithDelegate:self];
            [_login_view_controller showLoginWindowOnScreen:[self currentScreen]];
        }
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
    NSString* username = [[IAUserPrefs sharedInstance] prefsForKey:@"user:email"];
    
    if (username == nil ||
        [username isEqualToString:@""] ||
        ![self credentialsInChain:username])
    {
        return NO;
    }
    
    void* pwd_ptr = NULL;
    UInt32 pwd_len = 0;
    OSStatus status;
    status = [[IAKeychainManager sharedInstance] GetPasswordKeychain:username
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
        
        [self loginWithUsername:username password:password];
        
        password = @"";
        password = nil;
        return YES;
    }
    return NO;
}

//- Handle Views -----------------------------------------------------------------------------------

- (void)showNotifications
{
    _notification_view_controller = [[IANotificationListViewController alloc] initWithDelegate:self];
    
    if ([_window_controller windowIsOpen])
    {
        [_window_controller changeToViewController:_notification_view_controller];
    }
    else
    {
        [_window_controller openWithViewController:_notification_view_controller
                                      withMidpoint:[self statusBarIconMiddle]];
    }
}

- (void)showNotLoggedInView
{
    _not_logged_view_controller = [[IANotLoggedInViewController alloc] initWithDelegate:self];
    if ([_window_controller windowIsOpen])
    {
        [_window_controller changeToViewController:_not_logged_view_controller];
    }
    else
    {
        [_window_controller openWithViewController:_not_logged_view_controller
                                  withMidpoint:[self statusBarIconMiddle]];
    }
}

- (void)showSendView:(IAViewController*)controller
{
    if ([_window_controller windowIsOpen])
    {
        [_window_controller changeToViewController:controller];
    }
    else
    {
        [_window_controller openWithViewController:controller
                                      withMidpoint:[self statusBarIconMiddle]];
    }
}

//- Window Handling --------------------------------------------------------------------------------

- (void)closeNotificationWindow
{
    [_window_controller closeWindow];
    [_status_bar_icon setHighlighted:NO];
    _not_logged_view_controller = nil;
    _not_logged_view_controller = nil;
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
    if (![self credentialsInChain:username])
    {
        _new_credentials = YES;
        _username = username;
        _password = password;
    }
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
        
        if (_new_credentials)
            [self addCredentialsToKeychain];
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
        if (_login_view_controller == nil)
            _login_view_controller = [[IALoginViewController alloc] initWithDelegate:self];
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

- (BOOL)credentialsInChain:(NSString*)username
{
    if ([[IAKeychainManager sharedInstance] CredentialsInKeychain:username])
        return YES;
    else
        return NO;
}

- (void)addCredentialsToKeychain
{
    [[IAUserPrefs sharedInstance] setPref:_username forKey:@"user:email"];
    OSStatus add_status;
    add_status = [[IAKeychainManager sharedInstance] AddPasswordKeychain:_username
                                                                password:_password];
    if (add_status != noErr)
        IALog(@"%@ Error adding credentials to keychain");
    _password = @"";
    _password = nil;
}

//- General Functions ------------------------------------------------------------------------------

// Current screen to display content on
- (NSScreen*)currentScreen
{
    return [NSScreen mainScreen];
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

//- View Logic -------------------------------------------------------------------------------------

- (void)selectView
{
    if (![[IAGapState instance] logged_in])
    {
        [self showNotLoggedInView];
        return;
    }
    [self showNotifications];
}

//- General Send Controller Protocol ---------------------------------------------------------------

- (void)sendController:(IAGeneralSendController*)sender
 wantsActiveController:(IAViewController*)controller
{
    if (controller == nil)
        return;
    
    [self showSendView:controller];
}

//- Login Window Protocol --------------------------------------------------------------------------

- (void)tryLogin:(IALoginViewController*)sender
        username:(NSString*)username
        password:(NSString*)password
{
    if (sender == _login_view_controller)
    {
        [self loginWithUsername:username password:password];
    }
}

//- Notification List Protocol ---------------------------------------------------------------------

- (void)notificationListWantsQuit:(IANotificationListViewController*)sender
{
    [_delegate quitApplication:self];
}

- (void)notificationListGotTransferClick:(IANotificationListViewController*)sender
{
    [self showNotLoggedInView];
}

//- Not Logged In View Protocol --------------------------------------------------------------------

- (void)notLoggedInViewControllerWantsOpenLoginWindow:(IANotLoggedInViewController*)sender
{
    if (_login_view_controller == nil)
        _login_view_controller = [[IALoginViewController alloc] initWithDelegate:self];
    [_login_view_controller showLoginWindowOnScreen:[self currentScreen]];
    [self closeNotificationWindow];
}

//- Status Bar Icon Protocol -----------------------------------------------------------------------

- (void)statusBarIconClicked:(IAStatusBarIcon*)sender
{
    if ([_window_controller windowIsOpen])
    {
        [sender setHighlighted:NO];
        [_window_controller closeWindow];
    }
    else
    {
        [sender setHighlighted:YES];
        [self selectView];
    }
}

- (void)statusBarIconDragDrop:(IAStatusBarIcon*)sender
                    withFiles:(NSArray*)files
{
    [_general_send_controller simpleFileDrop];
}

- (void)statusBarIconDragEntered:(IAStatusBarIcon*)sender
{
    
}

//- Transaction Manager Protocol -------------------------------------------------------------------

- (void)transactionManager:(IATransactionManager*)sender
          transactionAdded:(IATransaction*)transaction
{
    
}

//- User Manager Protocol --------------------------------------------------------------------------

- (void)userManager:(IAUserManager*)sender
    hasNewStatusFor:(IAUser*)user
{
    [_transaction_manager newUserStatusFor:user];
}

//- Window Controller Protocol ---------------------------------------------------------------------

- (void)windowControllerWantsCloseWindow:(IAWindowController*)sender
{
    [self closeNotificationWindow];
}

@end
