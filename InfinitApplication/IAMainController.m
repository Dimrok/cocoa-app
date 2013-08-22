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
    IAViewController* _current_view_controller;
    IAConversationViewController* _conversation_view_controller;
    IAGeneralSendController* _general_send_controller;
    IALoginViewController* _login_view_controller;
    IANotificationListViewController* _notification_view_controller;
    IANotLoggedInViewController* _not_logged_view_controller;
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
        
        _window_controller = [[IAWindowController alloc] initWithDelegate:self];
        _current_view_controller = nil;
        
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

- (void)openOrChangeViewController:(IAViewController*)view_controller
{
    if ([_window_controller windowIsOpen])
    {
        [_window_controller changeToViewController:view_controller];
    }
    else
    {
        [_window_controller openWithViewController:view_controller
                                      withMidpoint:[self statusBarIconMiddle]];
    }
}

- (void)showConversationViewForUser:(IAUser*)user
{
    _conversation_view_controller = [[IAConversationViewController alloc] initWithDelegate:self
                                                                                  andUser:user];
    [self openOrChangeViewController:_conversation_view_controller];
}

- (void)showNotifications
{
    _notification_view_controller = [[IANotificationListViewController alloc] initWithDelegate:self];
    [self openOrChangeViewController:_notification_view_controller];
}

- (void)showNotLoggedInView
{
    _not_logged_view_controller = [[IANotLoggedInViewController alloc] initWithDelegate:self];
    [self openOrChangeViewController:_not_logged_view_controller];
}

- (void)showSendView:(IAViewController*)controller
{
    [self openOrChangeViewController:controller];
}

//- Window Handling --------------------------------------------------------------------------------

- (void)closeNotificationWindow
{
    [_window_controller closeWindow];
    [_status_bar_icon setHighlighted:NO];
    _conversation_view_controller = nil;
    _notification_view_controller = nil;
    _general_send_controller = nil;
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
        
        // XXX Should allow changing of avatar in settings, not upload every successful login
        [[IAGapState instance] updateAvatar:[IAFunctions addressBookUserAvatar]
                            performSelector:nil
                                   onObject:nil];
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

//- Conversation View Protocol ---------------------------------------------------------------------

- (NSArray*)conversationView:(IAConversationViewController*)sender
wantsReversedTransactionsForUser:(IAUser*)user
{
    NSMutableArray* reversed_transactions = [NSMutableArray array];
    for (IATransaction* transaction in [_transaction_manager transactionsForUser:user])
         [reversed_transactions insertObject:transaction atIndex:0];
    return reversed_transactions;
}

- (void)conversationView:(IAConversationViewController*)sender
    wantsTransferForUser:(IAUser*)user
{
    if (_general_send_controller == nil)
        _general_send_controller = [[IAGeneralSendController alloc] initWithDelegate:self];
    [_general_send_controller openWithFiles:nil forUser:user];
}

- (void)conversationViewWantsBack:(IAConversationViewController*)sender
{
    [self showNotifications];
}

//- General Send Controller Protocol ---------------------------------------------------------------

- (void)sendController:(IAGeneralSendController*)sender
 wantsActiveController:(IAViewController*)controller
{
    if (controller == nil)
        return;
    
    [_status_bar_icon setHighlighted:YES];
    [self showSendView:controller];
}

- (void)sendControllerWantsClose:(IAGeneralSendController*)sender
{
    [self closeNotificationWindow];
}

- (NSPoint)sendControllerWantsMidpoint:(IAGeneralSendController*)sender
{
    return [self statusBarIconMiddle];
}

- (void)sendController:(IAGeneralSendController*)sender
        wantsSendFiles:(NSArray*)files
               toUsers:(NSArray*)users
           withMessage:(NSString*)message
{
    [_transaction_manager sendFiles:files
                            toUsers:users
                        withMessage:message];
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
    if (_general_send_controller == nil)
        _general_send_controller = [[IAGeneralSendController alloc] initWithDelegate:self];
    [_general_send_controller openWithNoFile];
}

- (NSArray*)notificationListWantsLastTransactions:(IANotificationListViewController*)sender
{
    return [_transaction_manager latestTransactionPerUser];
}

- (void)notificationList:(IANotificationListViewController*)sender
          gotClickOnUser:(IAUser*)user
{
    [self showConversationViewForUser:user];
}

- (NSUInteger)notificationList:(IANotificationListViewController*)sender
     activeTransactionsForUser:(IAUser*)user
{
    return [_transaction_manager activeTransactionsForUser:user];
}

- (BOOL)notificationList:(IANotificationListViewController*)sender
transferringTransactionsForUser:(IAUser*)user
{
    return [_transaction_manager transferringTransactionsForUser:user];
}

- (CGFloat)notificationList:(IANotificationListViewController*)sender
transactionsProgressForUser:(IAUser*)user
{
    return [_transaction_manager transactionsProgressForUser:user];
}

- (void)notificationList:(IANotificationListViewController*)sender
       acceptTransaction:(IATransaction*)transaction
{
    [_transaction_manager acceptTransaction:transaction];
}

- (void)notificationList:(IANotificationListViewController*)sender
       cancelTransaction:(IATransaction*)transaction
{
    [_transaction_manager cancelTransaction:transaction];
}

- (void)notificationList:(IANotificationListViewController*)sender
       rejectTransaction:(IATransaction*)transaction
{
    [_transaction_manager rejectTransaction:transaction];
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
        [self closeNotificationWindow];
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
    if (_general_send_controller == nil)
        _general_send_controller = [[IAGeneralSendController alloc] initWithDelegate:self];
    [_general_send_controller openWithFiles:files forUser:nil];
}

- (void)statusBarIconDragEntered:(IAStatusBarIcon*)sender
{
    if (_general_send_controller == nil)
        _general_send_controller = [[IAGeneralSendController alloc] initWithDelegate:self];
    [_general_send_controller filesOverStatusBarIcon];
}

//- Transaction Manager Protocol -------------------------------------------------------------------

- (void)transactionManager:(IATransactionManager*)sender
          transactionAdded:(IATransaction*)transaction
{
    if (_current_view_controller == nil)
        return;
    [_current_view_controller transactionAdded:transaction];
}

- (void)transactionManager:(IATransactionManager*)sender
        transactionUpdated:(IATransaction*)transaction
{
    if (_current_view_controller == nil)
        return;
    [_current_view_controller transactionUpdated:transaction];
}

//- User Manager Protocol --------------------------------------------------------------------------

- (void)userManager:(IAUserManager*)sender
    hasNewStatusFor:(IAUser*)user
{
    if (_current_view_controller == nil)
        return;
    [_current_view_controller userUpdated:user];
}

//- Window Controller Protocol ---------------------------------------------------------------------

- (void)windowControllerWantsCloseWindow:(IAWindowController*)sender
{
    [self closeNotificationWindow];
}

- (void)windowController:(IAWindowController*)sender
hasCurrentViewController:(IAViewController*)controller
{
    _current_view_controller = controller;
}

@end
