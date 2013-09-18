//
//  IAMainController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 7/26/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAMainController.h"

#import <Gap/IAGapState.h>

#import "IACrashReportManager.h"
#import "IAGap.h"
#import "IAKeychainManager.h"
#import "IANoConnectionViewController.h"
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
    IANoConnectionViewController* _no_connection_view_controller;
    IANotificationListViewController* _notification_view_controller;
    IANotLoggedInViewController* _not_logged_view_controller;
    IAOnboardingViewController* _onboard_controller;
    IAWindowController* _window_controller;
    
    // Managers
    IAMeManager* _me_manager;
    IATransactionManager* _transaction_manager;
    IAUserManager* _user_manager;
    
    // Other
    IADesktopNotifier* _desktop_notifier;
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
        
        [IACrashReportManager setupCrashReporter];
        
        _status_item = [[NSStatusBar systemStatusBar] statusItemWithLength:34.0];
        _status_bar_icon = [[IAStatusBarIcon alloc] initWithDelegate:self statusItem:_status_item];
        _status_item.view = _status_bar_icon;
        
        _window_controller = [[IAWindowController alloc] initWithDelegate:self];
        _current_view_controller = nil;
        
        _me_manager = [[IAMeManager alloc] initWithDelegate:self];
        _transaction_manager = [[IATransactionManager alloc] initWithDelegate:self];
        _user_manager = [IAUserManager sharedInstanceWithDelegate:self];
        
        _desktop_notifier = [[IADesktopNotifier alloc] initWithDelegate:self];
        
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
    status = [[IAKeychainManager sharedInstance] getPasswordKeychain:username
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
        
        [self loginWithUsername:username
                       password:password];
        
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
    [_desktop_notifier clearAllNotifications];
    [_transaction_manager markTransactionsRead];
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
    if ([_me_manager connection_status] != gap_user_status_online)
    {
        [self showNotConnectedView];
        return;
    }
    [self openOrChangeViewController:controller];
}

- (void)showNotConnectedView
{
    _no_connection_view_controller = [[IANoConnectionViewController alloc] init];
    [self openOrChangeViewController:_no_connection_view_controller];
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

- (void)loginWithUsername:(NSString*)username
                 password:(NSString*)password
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

- (void)onSuccessfulLogin
{
    IALog(@"%@ Logged in", self);
    
    [IACrashReportManager sendExistingCrashReports];
    
    if ([_login_view_controller loginWindowOpen])
        [_login_view_controller closeLoginWindow];
    
    if (_new_credentials)
        [self addCredentialsToKeychain];
    
    // XXX Should allow changing of avatar in settings, not upload every successful login
    [[IAGapState instance] updateAvatar:[IAFunctions addressBookUserAvatar]
                        performSelector:nil
                               onObject:nil];
    // XXX We must find a better way to manage fetching of history per user
    [_transaction_manager getHistory];
    [[IAGapState instance] startPolling];
    [self updateStatusBarIcon];
    
    _login_view_controller = nil;
    
    if (![[[IAUserPrefs sharedInstance] prefsForKey:@"onboarded"] isEqualToString:@"2"])
    {
        _onboard_controller = [[IAOnboardingViewController alloc] initWithDelegate:self];
        [_onboard_controller startOnboarding];
    }
}

- (void)loginCallback:(IAGapOperationResult*)result
{
    if (result.success)
    {
        [self onSuccessfulLogin];
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
                
            case gap_already_logged_in:
                if ([_login_view_controller loginWindowOpen])
                    [_login_view_controller closeLoginWindow];
                _login_view_controller = nil;
                return;
                
            default:
                error = NSLocalizedString(@"Unknown login error", @"unknown login error");
                break;
        }
        
        
        if (_login_view_controller == nil)
            _login_view_controller = [[IALoginViewController alloc] initWithDelegate:self];
        
        
        NSString* username = [[IAUserPrefs sharedInstance] prefsForKey:@"user:email"];
        BOOL had_error = NO;
        
        if (username == nil || username.length == 0 || ![self credentialsInChain:username])
        {
            username = @"";
        }
        else
        {
            void* pwd_ptr = NULL;
            UInt32 pwd_len = 0;
            OSStatus status;
            status = [[IAKeychainManager sharedInstance] getPasswordKeychain:username
                                                                passwordData:&pwd_ptr
                                                              passwordLength:&pwd_len
                                                                     itemRef:NULL];
            if (status == noErr)
            {
                if (pwd_ptr == NULL)
                {
                    IALog(@"%@ WARNING: Problem getting password pointer", self);
                    had_error = YES;
                }
                
                NSString* password = [[NSString alloc] initWithBytes:pwd_ptr
                                                              length:pwd_len
                                                            encoding:NSUTF8StringEncoding];
                if (password.length == 0)
                {
                    IALog(@"%@ WARNING: Password length of zero", self);
                    had_error = YES;
                }
                
                [_login_view_controller showLoginWindowOnScreen:[self currentScreen]
                                                      withError:error
                                                   withUsername:username
                                                    andPassword:password];
                password = @"";
                password = nil;
            }
        }
        
        [_login_view_controller showLoginWindowOnScreen:[self currentScreen]
                                              withError:error
                                           withUsername:username
                                            andPassword:@""];
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
    [_delegate terminateApplication:self];
}

- (BOOL)credentialsInChain:(NSString*)username
{
    if ([[IAKeychainManager sharedInstance] credentialsInKeychain:username])
        return YES;
    else
        return NO;
}

- (void)addCredentialsToKeychain
{
    [[IAUserPrefs sharedInstance] setPref:_username forKey:@"user:email"];
    OSStatus add_status;
    add_status = [[IAKeychainManager sharedInstance] addPasswordKeychain:_username
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
    if ([_window_controller windowIsOpen])
    {
        [_status_bar_icon setHidden:YES];
        [self closeNotificationWindow];
    }
    if ([[IAGapState instance] logged_in])
    {
        [[IAGapState instance] logout:@selector(logoutAndQuitCallback:)
                             onObject:self];
    }
    else
    {
        [[IAGapState instance] freeGap];
        [_delegate terminateApplication:self];
    }
}

- (void)updateStatusBarIcon
{
    [_status_bar_icon setNumberOfItems:[_transaction_manager totalUntreatedAndUnreadTransactions]];
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
    wantsTransactionsForUser:(IAUser*)user
{
    return [_transaction_manager transactionsForUser:user];
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

- (void)conversationView:(IAConversationViewController*)sender
  wantsAcceptTransaction:(IATransaction*)transaction
{
    [_transaction_manager acceptTransaction:transaction];
}

- (void)conversationView:(IAConversationViewController*)sender
  wantsCancelTransaction:(IATransaction*)transaction
{
    [_transaction_manager cancelTransaction:transaction];
}

- (void)conversationView:(IAConversationViewController*)sender
  wantsRejectTransaction:(IATransaction*)transaction
{
    [_transaction_manager rejectTransaction:transaction];
}

- (void)conversationView:(IAConversationViewController*)sender
       wantsAddFavourite:(IAUser*)user
{
    [IAUserManager addFavourite:user];
}

- (void)conversationView:(IAConversationViewController*)sender
    wantsRemoveFavourite:(IAUser*)user
{
    [IAUserManager removeFavourite:user];
}

//- Desktop Notifier Protocol ----------------------------------------------------------------------

- (void)desktopNotifier:(IADesktopNotifier*)sender
hadClickNotificationForTransactionId:(NSNumber*)transaction_id
{
    [_status_bar_icon setHighlighted:YES];
    IATransaction* transaction = [_transaction_manager transactionWithId:transaction_id];
    if (transaction == nil)
        return;
    
    [self showConversationViewForUser:transaction.other_user];
    [_transaction_manager markTransactionAsRead:transaction];
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

- (NSArray*)sendControllerWantsFavourites:(IAGeneralSendController*)sender
{
    return [IAUserManager favouritesList];
}

- (void)sendController:(IAGeneralSendController*)sender
     wantsAddFavourite:(IAUser*)user
{
    [IAUserManager addFavourite:user];
}

- (void)sendController:(IAGeneralSendController*)sender
  wantsRemoveFavourite:(IAUser*)user
{
    [IAUserManager removeFavourite:user];
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

- (void)loginViewCloseButtonClicked:(IALoginViewController*)sender
{
    [self handleQuit];
}

//- Me Manager Protocol ----------------------------------------------------------------------------

- (void)meManager:(IAMeManager*)sender
hadConnectionStateChange:(gap_UserStatus)status
{
    [_status_bar_icon setConnected:status];
    if ([_current_view_controller isKindOfClass:IANoConnectionViewController.class] &&
        status == gap_user_status_online)
    {
        [self showNotifications];
    }
}

//- Notification List Protocol ---------------------------------------------------------------------

- (void)notificationListWantsQuit:(IANotificationListViewController*)sender
{
    [self handleQuit];
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
    return [_transaction_manager activeAndUnreadTransactionsForUser:user];
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

//- Onboarding Protocol ----------------------------------------------------------------------------

- (NSPoint)onboardingViewWantsInfinitIconPosition:(IAOnboardingViewController*)sender
{
    return [self statusBarIconMiddle];
}

- (void)onboardingComplete:(IAOnboardingViewController*)sender
{
    [_onboard_controller closeOnboarding];
    _onboard_controller = nil;
    [[IAUserPrefs sharedInstance] setPref:@"2" forKey:@"onboarded"];
}

- (void)onboardingViewWantsStartPulseStatusBarIcon:(IAOnboardingViewController*)sender
{
    [_status_bar_icon startPulse];
}

- (void)onboardingViewWantsStopPulseStatusBarIcon:(IAOnboardingViewController*)sender
{
    [_status_bar_icon stopPulse];
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
    if (![[IAGapState instance] logged_in])
        return;
    
    if (_general_send_controller == nil)
        _general_send_controller = [[IAGeneralSendController alloc] initWithDelegate:self];
    [_general_send_controller openWithFiles:files forUser:nil];
}

- (void)statusBarIconDragEntered:(IAStatusBarIcon*)sender
{
    if (![[IAGapState instance] logged_in] ||
        [_me_manager connection_status] != gap_user_status_online)
        return;
    
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
    
    if ([_current_view_controller isKindOfClass:IANotificationListViewController.class])
    {
        [_transaction_manager markTransactionsRead];
    }
    else if ([_current_view_controller isKindOfClass:IAConversationViewController.class])
    {
        if ([transaction.other_user isEqual:[(IAConversationViewController*)_current_view_controller user]])
        {
            [_transaction_manager markTransactionAsRead:transaction];
        }
    }
    else
    {
        [_desktop_notifier transactionAdded:transaction];
    }
}

- (void)transactionManager:(IATransactionManager*)sender
        transactionUpdated:(IATransaction*)transaction
{
    if (_current_view_controller == nil)
        return;
    
    [_current_view_controller transactionUpdated:transaction];
    
    if ([_current_view_controller isKindOfClass:IANotificationListViewController.class])
    {
        [_transaction_manager markTransactionsRead];
    }
    else if ([_current_view_controller isKindOfClass:IAConversationViewController.class])
    {
        if ([transaction.other_user isEqual:[(IAConversationViewController*)_current_view_controller user]])
        {
            [_transaction_manager markTransactionAsRead:transaction];
        }
    }
    else
    {
        [_desktop_notifier transactionUpdated:transaction];
    }
}

- (void)transactionManagerHasGotHistory:(IATransactionManager*)sender
{
    if (_current_view_controller == nil)
        return;
    [self showNotifications];
}

- (void)transactionManagerUpdatedReadTransactions:(IATransactionManager*)sender
{
    [self updateStatusBarIcon];
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
