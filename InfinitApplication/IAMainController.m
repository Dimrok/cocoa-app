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
#import "IAPopoverViewController.h"
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
    IAPopoverViewController* _popover_controller;
    IAOnboardingViewController* _onboard_controller;
    IAReportProblemWindowController* _report_problem_controller;
    IAWindowController* _window_controller;
    
    // Managers
    IAMeManager* _me_manager;
    IATransactionManager* _transaction_manager;
    IAUserManager* _user_manager;
    
    // Other
    IADesktopNotifier* _desktop_notifier;
    BOOL _new_credentials;
    BOOL _update_credentials;
    BOOL _logging_in;
    BOOL _onboarding;
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
        
        [[IACrashReportManager sharedInstance] setupCrashReporter];
        
        _status_item = [[NSStatusBar systemStatusBar] statusItemWithLength:30.0];
        _status_bar_icon = [[IAStatusBarIcon alloc] initWithDelegate:self statusItem:_status_item];
        _status_item.view = _status_bar_icon;
        
        _window_controller = [[IAWindowController alloc] initWithDelegate:self];
        _current_view_controller = nil;
        
        _me_manager = [[IAMeManager alloc] initWithDelegate:self];
        _transaction_manager = [[IATransactionManager alloc] initWithDelegate:self];
        _user_manager = [IAUserManager sharedInstanceWithDelegate:self];
        
        _desktop_notifier = [[IADesktopNotifier alloc] initWithDelegate:self];
        
        _logging_in = NO;
        _onboarding = NO;
        _update_credentials = NO;
        _new_credentials = NO;
        
        if (![self tryAutomaticLogin])
        {
            IALog(@"%@ Autologin failed", self);
            // Need a delay, otherwise the popover draws in the wrong place
            [self performSelector:@selector(delayedLoginPopover) withObject:nil afterDelay:0.2];
        }
    }
    return self;
}

- (void)delayedLoginPopover
{
    if (_popover_controller == nil)
        _popover_controller = [[IAPopoverViewController alloc] init];
    NSString* heading = NSLocalizedString(@"Click the icon to login",
                                          @"click the icon to login");
    NSString* message = NSLocalizedString(@"Infinit has been installed. Click on the icon to login.",
                                          @"Infinit has been installed. Click on the icon to login");
    [_popover_controller showHeading:heading
                          andMessage:message
                           belowView:_status_item.view];
}

- (BOOL)tryAutomaticLogin
{
    NSString* username = [[IAUserPrefs sharedInstance] prefsForKey:@"user:email"];
    NSString* password = [self getPasswordForUsername:username];
    
    if (username.length > 0 && password.length > 0)
    {
        _logging_in = YES;
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
    if (_not_logged_view_controller == nil)
    {
        if (_logging_in)
        {
            _not_logged_view_controller = [[IANotLoggedInViewController alloc] initWithDelegate:self
                                                                                       withMode:LOGGING_IN];
        }
        else
        {
            _not_logged_view_controller = [[IANotLoggedInViewController alloc] initWithDelegate:self
                                                                                       withMode:LOGGED_OUT];
        }
    }
    else
    {
        if (_logging_in)
            [_not_logged_view_controller setMode:LOGGING_IN];
        else
            [_not_logged_view_controller setMode:LOGGED_OUT];
        
    }
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
    if (_no_connection_view_controller == nil)
        _no_connection_view_controller = [[IANoConnectionViewController alloc] init];
    [self openOrChangeViewController:_no_connection_view_controller];
}

- (void)showOnboardingView
{
    if (_onboard_controller == nil)
        _onboard_controller = [[IAOnboardingViewController alloc] initWithDelegate:self];
    [self openOrChangeViewController:_onboard_controller];
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
    _logging_in = YES;
    NSString* device_name = @"TODO"; // XXX use NSHost to get device name
    
    [[IAGapState instance] login:username
                    withPassword:password
                   andDeviceName:device_name
                 performSelector:@selector(loginCallback:)
                        onObject:self];
    if (![self credentialsInChain:username] || _update_credentials)
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
    
    [[IACrashReportManager sharedInstance] sendExistingCrashReports];
    
    if ([_login_view_controller loginWindowOpen])
        [_login_view_controller closeLoginWindow];
    
    if (_update_credentials && [[IAKeychainManager sharedInstance] credentialsInKeychain:_username])
    {
        [[IAKeychainManager sharedInstance] changeUser:_username password:_password];
        _password = @"";
        _password = nil;
    }
    else if (_new_credentials)
    {
        [self addCredentialsToKeychain];
    }
    
    if (![[[IAUserPrefs sharedInstance] prefsForKey:@"avatar_uploaded"] isEqualToString:@"1"])
    {
        [[IAGapState instance] updateAvatar:[IAFunctions addressBookUserAvatar]
                            performSelector:nil
                                   onObject:nil];
        [[IAUserPrefs sharedInstance] setPref:@"1" forKey:@"avatar_uploaded"];
    }
    // XXX We must find a better way to manage fetching of history per user
    [_transaction_manager getHistory];
    [[IAGapState instance] startPolling];
    [self updateStatusBarIcon];
    
    _login_view_controller = nil;
    
    if (![[[IAUserPrefs sharedInstance] prefsForKey:@"onboarded"] isEqualToString:@"3"])
    {
        [self showOnboardingView];
    }
}

- (void)loginCallback:(IAGapOperationResult*)result
{
    _logging_in = NO;
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
                error = [NSString stringWithFormat:@"%@ (%d)",
                         NSLocalizedString(@"Connection problem, check Internet connection",
                                           @"no route to internet"),
                         result.status];
                break;
                
            case gap_email_password_dont_match:
                error = [NSString stringWithFormat:@"%@ (%d)",
                         NSLocalizedString(@"Email or password incorrect",
                                           @"email or password wrong"),
                         result.status];
                break;
                
            case gap_already_logged_in:
                if ([_login_view_controller loginWindowOpen])
                    [_login_view_controller closeLoginWindow];
                _login_view_controller = nil;
                [[IAGapState instance] setLoggedIn:YES];
                return;
                
            case gap_deprecated:
                error = [NSString stringWithFormat:@"%@ (%d)",
                         NSLocalizedString(@"Please update Infinit", @"please update infinit."),
                         result.status];
                [_delegate mainControllerWantsCheckForUpdate:self];
                break;
                
            default:
                error = [NSString stringWithFormat:@"%@ (%d)",
                         NSLocalizedString(@"Unknown login error", @"unknown login error"),
                         result.status];
                break;
        }
        
        
        if (_login_view_controller == nil)
            _login_view_controller = [[IALoginViewController alloc] initWithDelegate:self];
        
        
        NSString* username = [[IAUserPrefs sharedInstance] prefsForKey:@"user:email"];
        NSString* password = [self getPasswordForUsername:username];
        
        if (password == nil)
            password = @"";
        
        _new_credentials = YES;
        _update_credentials = YES;
        
        [_login_view_controller showLoginWindowOnScreen:[self currentScreen]
                                              withError:error
                                           withUsername:username
                                            andPassword:password];
        password = @"";
        password = nil;
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

- (NSString*)getPasswordForUsername:(NSString*)username
{
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
            return nil;
        
        NSString* password = [[NSString alloc] initWithBytes:pwd_ptr
                                                      length:pwd_len
                                                    encoding:NSUTF8StringEncoding];
        if (password.length == 0)
            return nil;
        
        return password;
    }
    return nil;
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
    if (_onboarding)
        return;

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

- (void)loginViewClose:(IALoginViewController*)sender
{
    [_login_view_controller closeLoginWindow];
    _login_view_controller = nil;
}

- (void)loginViewCloseAndQuit:(IALoginViewController*)sender
{
    [_login_view_controller closeLoginWindow];
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
    if (status == gap_user_status_online)
        [IAUserManager resyncUserStatuses];
    else if (status == gap_user_status_offline)
        [IAUserManager setAllUsersOffline];
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

- (void)notificationListWantsReportProblem:(IANotificationListViewController*)sender
{
    [self closeNotificationWindow];
    if (_report_problem_controller == nil)
        _report_problem_controller = [[IAReportProblemWindowController alloc] initWithDelegate:self];
    
    [_report_problem_controller show];
}

- (void)notificationListWantsCheckForUpdate:(IANotificationListViewController*)sender
{
    [_delegate mainControllerWantsCheckForUpdate:self];
}

//- Not Logged In View Protocol --------------------------------------------------------------------

- (void)notLoggedInViewControllerWantsOpenLoginWindow:(IANotLoggedInViewController*)sender
{
    if (_login_view_controller == nil)
        _login_view_controller = [[IALoginViewController alloc] initWithDelegate:self];
    NSString* username = [[IAUserPrefs sharedInstance] prefsForKey:@"user:email"];
    NSString* password = [self getPasswordForUsername:username];
    if (!_logging_in)
    {
        [_login_view_controller showLoginWindowOnScreen:[self currentScreen]
                                              withError:@""
                                           withUsername:username
                                            andPassword:password];
    }
    else
    {
        [_login_view_controller showLoginWindowOnScreenAsLoggingIn:[self currentScreen]
                                                      withUsername:username
                                                       andPassword:password];
    }
    password = @"";
    password = nil;
    [self closeNotificationWindow];
}

//- Onboarding Protocol ----------------------------------------------------------------------------

- (void)onboardingControllerDone:(IAOnboardingViewController*)sender
{
    _onboarding = NO;
    [self closeNotificationWindow];
    _onboard_controller = nil;
    [[IAUserPrefs sharedInstance] setPref:@"3" forKey:@"onboarded"];
}

- (void)onboardingControllerStarted:(IAOnboardingViewController*)sender
{
    _onboarding = YES;
}

//- Report Problem Protocol ------------------------------------------------------------------------

- (void)reportProblemController:(IAReportProblemWindowController*)sender
               wantsSendMessage:(NSString*)message
                        andFile:(NSString*)file_path
{
    [_report_problem_controller close];
    [[IACrashReportManager sharedInstance] sendUserReportWithMessage:message andFile:file_path];
    _report_problem_controller = nil;
}

- (void)reportProblemControllerWantsCancel:(IAReportProblemWindowController*)sender
{
    [_report_problem_controller close];
    _report_problem_controller = nil;
}

//- Status Bar Icon Protocol -----------------------------------------------------------------------

- (void)statusBarIconClicked:(IAStatusBarIcon*)sender
{
    if (_onboarding)
        return;

    if (_popover_controller != nil)
    {
        [_popover_controller hidePopover];
        _popover_controller = nil;
    }
    
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
    if (![[IAGapState instance] logged_in] || _onboarding)
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

    [_desktop_notifier transactionAdded:transaction];
    
    if (_current_view_controller == nil)
        return;
    
    [_current_view_controller transactionAdded:transaction];
}

- (void)transactionManager:(IATransactionManager*)sender
        transactionUpdated:(IATransaction*)transaction
{
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
    
    [_desktop_notifier transactionUpdated:transaction];
    
    if (_current_view_controller == nil)
        return;
    
    [_current_view_controller transactionUpdated:transaction];
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

- (void)transactionManager:(IATransactionManager*)sender
   needsShowInvitedHeading:(NSString*)heading
                andMessage:(NSString*)message
{
    if (_popover_controller == nil)
        _popover_controller = [[IAPopoverViewController alloc] init];
    [_popover_controller showHeading:heading
                          andMessage:message
                           belowView:_status_item.view];
}

//- User Manager Protocol --------------------------------------------------------------------------

- (void)userManager:(IAUserManager*)sender
    hasNewStatusFor:(IAUser*)user
{
    [_transaction_manager updateTransactionsForUser:user];
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
