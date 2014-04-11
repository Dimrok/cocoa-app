//
//  IAMainController.mm
//  InfinitApplication
//
//  Created by Christopher Crone on 7/26/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAMainController.h"

#import <Gap/IAGapState.h>

#import "IAAutoStartup.h"
#import "IACrashReportManager.h"
#import "IAGap.h"
#import "IAKeychainManager.h"
#import "IAPopoverViewController.h"
#import "IAUserPrefs.h"
#import "InfinitMetricsManager.h"

#undef check
#import <elle/log.hh>
#import <surface/gap/enums.hh>

ELLE_LOG_COMPONENT("OSX.MainController");

@implementation IAMainController
{
@private
  id<IAMainControllerProtocol> _delegate;
  
  NSStatusItem* _status_item;
  IAStatusBarIcon* _status_bar_icon;
  
  // View controllers
  IAViewController* _current_view_controller;
  InfinitClippyViewController* _clippy_view_controller;
  InfinitConversationViewController* _conversation_view_controller;
  IAGeneralSendController* _general_send_controller;
  InfinitLoginViewController* _login_view_controller;
  IANoConnectionViewController* _no_connection_view_controller;
  IANotificationListViewController* _notification_view_controller;
  IANotLoggedInViewController* _not_logged_view_controller;
  IAPopoverViewController* _popover_controller;
  InfinitOnboardingController* _onboard_controller;
  IAReportProblemWindowController* _report_problem_controller;
  IAWindowController* _window_controller;
  
  // Infinit Link Handling
  NSURL* _infinit_link;
  
  // Managers
  IAMeManager* _me_manager;
  InfinitStayAwakeManager* _stay_awake_manager;
  IATransactionManager* _transaction_manager;
  IAUserManager* _user_manager;
  
  // Other
  IADesktopNotifier* _desktop_notifier;
  NSSound* _sent_sound;
  
  // Login
  BOOL _logging_in;
  NSString* _password;
  BOOL _new_credentials;
  BOOL _update_credentials;
  NSString* _username;
  BOOL _autologin_cooling_down;
  CGFloat _login_retry_cooldown;
  CGFloat _login_retry_cooldown_max;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithDelegate:(id<IAMainControllerProtocol>)delegate
{
  if (self = [super init])
  {
    _delegate = delegate;
    
    IAGap* state = [[IAGap alloc] init];
    [IAGapState setupWithProtocol:state];
    
    // NB: Can only use elle logger after state has been initialised. i.e.: After this point.
    
    [[IACrashReportManager sharedInstance] setupCrashReporter];
    
    _stay_awake_manager = [InfinitStayAwakeManager setUpInstanceWithDelegate:self];
    
    _status_item = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    _status_bar_icon = [[IAStatusBarIcon alloc] initWithDelegate:self statusItem:_status_item];
    _status_item.view = _status_bar_icon;
    
    _window_controller = [[IAWindowController alloc] initWithDelegate:self];
    _current_view_controller = nil;
    
    _me_manager = [[IAMeManager alloc] initWithDelegate:self];
    _transaction_manager = [[IATransactionManager alloc] initWithDelegate:self];
    _user_manager = [IAUserManager sharedInstanceWithDelegate:self];
    
    if ([IAFunctions osxVersion] != INFINIT_OS_X_VERSION_10_7)
      _desktop_notifier = [[IADesktopNotifier alloc] initWithDelegate:self];
    
    _infinit_link = nil;
    _autologin_cooling_down = NO;
    _login_retry_cooldown = 3.0;
    _login_retry_cooldown_max = 60.0;
    
    _sent_sound = [NSSound soundNamed:@"sound_sent"];
    
    if (![[[IAUserPrefs sharedInstance] prefsForKey:@"first_launch"] isEqualToString:@"0"])
    {
      [self addToLoginItems];
      [[IAUserPrefs sharedInstance] setPref:@"0" forKey:@"first_launch"];
    }
    
    if (![self tryAutomaticLogin])
    {
      ELLE_LOG("%s: autologin failed", self.description.UTF8String);
      // WORKAROUND: Need delay before showing window, otherwise status bar icon midpoint
      // is miscalculated
      [self performSelector:@selector(delayedLoginViewOpen) withObject:nil afterDelay:0.3];
    }
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(kickedOutCallback)
                                               name:IA_GAP_EVENT_KICKED_OUT
                                             object:nil];
  }
  return self;
}

- (void)dealloc
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  [NSNotificationCenter.defaultCenter removeObserver:self];
}

//- Check Server Connectivity ----------------------------------------------------------------------

- (void)delayedLoginViewOpen
{
  [self showLoginView];
}

- (BOOL)tryAutomaticLogin
{
  _autologin_cooling_down = NO;
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

//- Handle Infinit Link ----------------------------------------------------------------------------

- (void)handleInfinitLink:(NSURL*)link
{
  // If we're not logged in, store the link and activate it when we are.
  if (![[IAGapState instance] logged_in])
  {
    _infinit_link = link;
    return;
  }
  [self openSendViewForLink:link];
}

- (void)linkHandleUserCallback:(IAGapOperationResult*)result
{
  if (!result.success)
  {
    ELLE_WARN("%s: problem checking for link user id", self.description.UTF8String);
    return;
  }
  NSDictionary* dict = result.data;
  NSNumber* user_id = [dict valueForKey:@"user_id"];
  
  if (user_id.integerValue != 0 &&
      user_id.integerValue != [[[IAGapState instance] self_id] integerValue])
  {
    IAUser* user = [IAUserManager userWithId:user_id];
    if (_general_send_controller == nil)
      _general_send_controller = [[IAGeneralSendController alloc] initWithDelegate:self];
    [_general_send_controller openWithFiles:nil forUser:user];
  }
  else if (user_id.integerValue == 0)
  {
    ELLE_WARN("%s: link user not on Infinit: %s", self.description.UTF8String,
              [[dict valueForKey:@"handle"] description].UTF8String);
  }
}

- (void)openSendViewForLink:(NSURL*)link
{
  NSString* scheme = link.scheme;
  if (![scheme isEqualToString:@"infinit"])
  {
    ELLE_WARN("%s: unknown scheme in link: %s", self.description.UTF8String,
              link.description.UTF8String);
    return;
  }
  NSString* action = link.host;
  if (![action isEqualToString:@"send"])
  {
    ELLE_WARN("%s: unknown action in link: %s", self.description.UTF8String,
              link.description.UTF8String);
    return;
  }
  NSMutableArray* components = [NSMutableArray arrayWithArray:[link pathComponents]];
  NSArray* temp = [NSArray arrayWithArray:components];
  for (NSString* component in temp)
  {
    if ([component isEqualToString:@"/"])
      [components removeObject:component];
  }
  if (components.count != 2)
  {
    ELLE_WARN("%s: unknown link type: %s", self.description.UTF8String,
              link.description.UTF8String);
    return;
  }
  NSString* destination = components[0];
  if (![destination isEqualToString:@"user"])
  {
    ELLE_WARN("%s: unknown destination in link: %s", self.description.UTF8String,
              link.description.UTF8String);
    return;
  }
  NSString* handle = components[1];
  NSMutableDictionary* handle_check = [NSMutableDictionary
                                       dictionaryWithDictionary:@{@"handle": handle}];
  [[IAGapState instance] getUserIdfromHandle:handle
                             performSelector:@selector(linkHandleUserCallback:)
                                    onObject:self
                                    withData:handle_check];
  _infinit_link = nil;
}

//- Handle Views -----------------------------------------------------------------------------------

- (void)openOrChangeViewController:(IAViewController*)view_controller
{
  if (view_controller.class != InfinitClippyViewController.class)
    [_status_bar_icon setHighlighted:YES];
  else
    [_status_bar_icon setHighlighted:NO];
  if ([_window_controller windowIsOpen])
  {
    if (_current_view_controller.class == InfinitClippyViewController.class)
    {
      [self closeNotificationWindow];
      [self performSelector:@selector(openOrChangeViewController:)
                 withObject:view_controller
                 afterDelay:0.4];
    }
    [_window_controller changeToViewController:view_controller];
  }
  else
  {
    [_window_controller openWithViewController:view_controller
                                  withMidpoint:[self statusBarIconMiddle]];
  }
}

- (void)showClippyViewWithMode:(InfinitClippyMode)mode
{
  _clippy_view_controller = nil;
  _clippy_view_controller = [[InfinitClippyViewController alloc] initWithDelegate:self
                                                                          andMode:mode];
  [self openOrChangeViewController:_clippy_view_controller];
}

- (void)showConversationViewForUser:(IAUser*)user
{
  NSArray* user_transactions = [_transaction_manager transactionsForUser:user];
  _conversation_view_controller =
  [[InfinitConversationViewController alloc] initWithDelegate:self
                                                      forUser:user
                                             withTransactions:user_transactions];
  [self openOrChangeViewController:_conversation_view_controller];
}

- (void)showNotifications
{
  if ([IAFunctions osxVersion] != INFINIT_OS_X_VERSION_10_7)
    [_desktop_notifier clearAllNotifications];
  _notification_view_controller =
    [[IANotificationListViewController alloc] initWithDelegate:self
                                           andConnectionStatus:_me_manager.connection_status];
  [self openOrChangeViewController:_notification_view_controller];
}

- (void)showLoginView
{
  if (_login_view_controller == nil)
  {
    _login_view_controller = [[InfinitLoginViewController alloc] initWithDelegate:self
                                                                         withMode:LOGIN_VIEW_NOT_LOGGED_IN];
  }
  else
  {
    [_login_view_controller setLoginViewMode:LOGIN_VIEW_NOT_LOGGED_IN];
  }
  [self openOrChangeViewController:_login_view_controller];
}

- (void)showNotLoggedInView
{
  if (_autologin_cooling_down)
  {
    if (_not_logged_view_controller == nil)
    {
      _not_logged_view_controller = [[IANotLoggedInViewController alloc]
                                     initWithMode:INFINIT_WAITING_FOR_CONNECTION
                                     andDelegate:self];
    }
    else
    {
      [_not_logged_view_controller setMode:INFINIT_WAITING_FOR_CONNECTION];
    }
    [self openOrChangeViewController:_not_logged_view_controller];
  }
  else if (_logging_in)
  {
    if (_not_logged_view_controller == nil)
    {
      _not_logged_view_controller = [[IANotLoggedInViewController alloc]
                                     initWithMode:INFINIT_LOGGING_IN andDelegate:self];
    }
    else
    {
      [_not_logged_view_controller setMode:INFINIT_LOGGING_IN];
    }
    [self openOrChangeViewController:_not_logged_view_controller];
  }
  else
  {
    [self showLoginView];
  }
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
    _no_connection_view_controller = [[IANoConnectionViewController alloc] initWithDelegate:self];
  [self openOrChangeViewController:_no_connection_view_controller];
}

//- Window Handling --------------------------------------------------------------------------------

- (void)closeNotificationWindow
{
  if ([IAFunctions osxVersion] != INFINIT_OS_X_VERSION_10_7)
    [_desktop_notifier clearAllNotifications];
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
  [_status_bar_icon setLoggingIn:YES];
  if (_current_view_controller == _not_logged_view_controller)
    [_not_logged_view_controller setMode:INFINIT_LOGGING_IN];
  
  [[IAGapState instance] login:username
                  withPassword:password
               performSelector:@selector(loginCallback:)
                      onObject:self];
  if (_new_credentials)
  {
    _username = username;
    _password = password;
  }
  password = @"";
  password = nil;
}

- (void)onSuccessfulLogin
{
  ELLE_LOG("%s: completed login", self.description.UTF8String);
  
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
  
  if (_username != nil && _username.length > 0)
    [[IAUserPrefs sharedInstance] setPref:_username forKey:@"user:email"];
  
  [self updateStatusBarIcon];
  
  _login_view_controller = nil;
  
  // XXX We must find a better way to manage fetching of history per user
  [_transaction_manager getHistory];
  
  if (![[[IAUserPrefs sharedInstance] prefsForKey:@"onboarded"] isEqualToString:@"4"])
  {
    [self closeNotificationWindow];
    [self startOnboarding];
  }
  else if (_current_view_controller != nil &&
           _current_view_controller != _notification_view_controller)
  {
    [self showNotifications];
  }
  [[IACrashReportManager sharedInstance] sendExistingCrashReports];
  
  [[IAGapState instance] startPolling];
  
  [self updateStatusBarIcon];
  
  // If we've got an unhandled link, handle it now
  if (_infinit_link != nil)
    [self openSendViewForLink:_infinit_link];
}

- (void)loginCallback:(IAGapOperationResult*)result
{
  _logging_in = NO;
  [_status_bar_icon setLoggingIn:NO];
  if (result.success)
  {
    [self onSuccessfulLogin];
  }
  else
  {
    ELLE_ERR("%s: couldn't login with status: %d", self.description.UTF8String, result.status);
    NSString* error;
    switch (result.status)
    {
      case gap_network_error:
      case gap_meta_unreachable:
        if (_new_credentials)
        {
          error = [NSString stringWithFormat:@"%@",
                   NSLocalizedString(@"Connection problem, check Internet connection.",
                                     @"no route to internet")];
          break;
        }
        else
        {
          _autologin_cooling_down = YES;
          [self performSelector:@selector(tryAutomaticLogin)
                     withObject:nil
                     afterDelay:_login_retry_cooldown];
          _login_retry_cooldown = _login_retry_cooldown * 2;
          if (_login_retry_cooldown > _login_retry_cooldown_max)
            _login_retry_cooldown = _login_retry_cooldown_max;
          if (_current_view_controller == _not_logged_view_controller)
            [_not_logged_view_controller setMode:INFINIT_WAITING_FOR_CONNECTION];
          return;
        }
        
      case gap_email_password_dont_match:
        error = [NSString stringWithFormat:@"%@",
                 NSLocalizedString(@"Email or password incorrect.",
                                   @"email or password wrong")];
        
        if ([[[IAUserPrefs sharedInstance] prefsForKey:@"user:email"] isEqualToString:_username])
          _update_credentials = YES;
        
        break;
        
      case gap_already_logged_in:
        if (_current_view_controller == _login_view_controller)
          [self closeNotificationWindow];
        _login_view_controller = nil;
        [[IAGapState instance] setLoggedIn:YES];
        return;
        
      case gap_deprecated:
        error = [NSString stringWithFormat:@"%@",
                 NSLocalizedString(@"Please update Infinit.", @"please update infinit.")];
        [_delegate mainControllerWantsCheckForUpdate:self];
        break;
        
      case gap_email_not_confirmed:
        error = [NSString stringWithFormat:@"%@",
                 NSLocalizedString(@"Check your email to confirm your account.", nil)];
        break;
        
      case gap_meta_down_with_message:
        error = [NSString stringWithFormat:@"%@",
                 NSLocalizedString(@"Infinit is currently unavailable, try again later.",
                                   @"infinit is currently unavailable")];
        // XXX display actual Meta message
        break;
        
      case gap_trophonius_unreachable:
        if (_new_credentials)
        {
          error = [NSString stringWithFormat:@"%@",
                   NSLocalizedString(@"Unable to contact our servers, please contact support.",
                                     @"unable to contact our servers")];
          break;
        }
        else
        {
          _autologin_cooling_down = YES;
          [self performSelector:@selector(tryAutomaticLogin)
                     withObject:nil
                     afterDelay:_login_retry_cooldown];
          _login_retry_cooldown = _login_retry_cooldown * 2;
          if (_login_retry_cooldown > _login_retry_cooldown_max)
            _login_retry_cooldown = _login_retry_cooldown_max;
          if (_current_view_controller == _not_logged_view_controller)
            [_not_logged_view_controller setMode:INFINIT_WAITING_FOR_CONNECTION];
          return;
        }
        
      default:
        error = [NSString stringWithFormat:@"%@ (%d).",
                 NSLocalizedString(@"Unknown login error", @"unknown login error"),
                 result.status];
        break;
    }
    
    
    if (_login_view_controller == nil)
    {
      _login_view_controller = [[InfinitLoginViewController alloc] initWithDelegate:self
                                                                           withMode:LOGIN_VIEW_NOT_LOGGED_IN_WITH_CREDENTIALS];
    }
    else
    {
      [_login_view_controller setLoginViewMode:LOGIN_VIEW_NOT_LOGGED_IN_WITH_CREDENTIALS];
    }
    
    NSString* username = [[IAUserPrefs sharedInstance] prefsForKey:@"user:email"];
    NSString* password = [self getPasswordForUsername:username];
    
    if (password == nil)
      password = @"";
    
    if (_current_view_controller != _login_view_controller)
      [self showLoginView];
    
    [_login_view_controller showWithError:error
                                 username:username
                              andPassword:password];
    
    password = @"";
    password = nil;
  }
}

- (void)logoutCallback:(IAGapOperationResult*)result
{
  if (result.success)
    ELLE_LOG("%s: logged out", self.description.UTF8String);
  else
    ELLE_WARN("%s: logout failed", self.description.UTF8String);
  [_status_bar_icon setNumberOfItems:0];
}

- (void)logoutAndQuitCallback:(IAGapOperationResult*)result
{
  [self logoutCallback:result];
  [self performSelector:@selector(delayedClose) withObject:nil afterDelay:0.2];
}

- (void)delayedClose
{
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
  if (![self credentialsInChain:_username])
  {
    OSStatus add_status;
    add_status = [[IAKeychainManager sharedInstance] addPasswordKeychain:_username
                                                                password:_password];
    if (add_status != noErr)
    {
      ELLE_ERR("%s: unable to add credentials to keychain", self.description.UTF8String);
    }
  }
  else
  {
    OSStatus replace_status;
    replace_status = [[IAKeychainManager sharedInstance] changeUser:_username password:_password];
    if (replace_status != noErr)
    {
      ELLE_ERR("%s: unable to change credentials in keychain", self.description.UTF8String);
    }
  }
  _password = @"";
  _password = nil;
}

- (NSString*)getPasswordForUsername:(NSString*)username
{
  if (username == nil ||
      [username isEqualToString:@""] ||
      ![self credentialsInChain:username])
  {
    return nil;
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

- (void)logoutAndShowLoginCallback:(IAGapOperationResult*)result
{
  if (result.success)
  {
    ELLE_LOG("%s: logged out", self.description.UTF8String);
    [self performSelector:@selector(showLoginView) withObject:nil afterDelay:0.3];
  }
  else
  {
    ELLE_WARN("%s: logout failed", self.description.UTF8String);
  }
}

- (void)handleLogout
{
  [self closeNotificationWindow];
  [self updateStatusBarIcon];
  [[IAGapState instance] logout:@selector(logoutAndShowLoginCallback:) onObject:self];
}

- (void)handleQuit
{
  if (_onboard_controller != nil && _onboard_controller.receive_onboarding_done)
  {
    [self doneOnboarding];
  }
  _stay_awake_manager = nil;
  if ([_window_controller windowIsOpen])
  {
    [_status_bar_icon setHidden:YES];
    [self closeNotificationWindow];
  }
  if ([[IAGapState instance] logged_in])
  {
    [[IAGapState instance] logout:@selector(logoutAndQuitCallback:) onObject:self];
  }
  else
  {
    if (!_logging_in)
    {
      [[IAGapState instance] freeGap];
    }
    [_delegate terminateApplication:self];
  }
}

- (void)updateStatusBarIcon
{
  if ([_transaction_manager hasTransferringTransaction])
    [_status_bar_icon setTransferring:YES];
  else
    [_status_bar_icon setTransferring:NO];
  [_status_bar_icon setNumberOfItems:[_transaction_manager totalActiveTransactions]];
  [_status_bar_icon setFire:[_transaction_manager haveUnreadConversations]];
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

//- Onboarding -------------------------------------------------------------------------------------

- (void)startOnboarding
{
  // XXX We need to check if it's a file that's been sent by someone or if we need to do the fake
  // transfer.
  IATransaction* fake_transaction = [_transaction_manager makeOnboardingTransaction];
  if (fake_transaction == nil)
    return;
  _onboard_controller = [[InfinitOnboardingController alloc] initWithDeleage:self
                                                       andReceiveTransaction:fake_transaction];
  [self performSelector:@selector(waitForUserToClickNotification) withObject:nil afterDelay:10.0];
}

- (void)waitForUserToClickNotification
{
  // The user didn't react to the desktop notification so follow track for didn't do anything.
  if (_current_view_controller == nil)
    _onboard_controller.state = INFINIT_ONBOARDING_RECEIVE_NO_ACTION;
}

- (IATransaction*)receiveOnboardingTransaction:(IAViewController*)sender;
{
  return _onboard_controller.receive_transaction;
}

- (IATransaction*)sendOnboardingTransaction:(InfinitConversationViewController*)sender
{
  return _onboard_controller.send_transaction;
}

//- Conversation View Protocol ---------------------------------------------------------------------

- (void)conversationView:(InfinitConversationViewController*)sender
wantsMarkTransactionsReadForUser:(IAUser*)user
{
  [_transaction_manager markTransactionsReadForUser:user];
}

- (void)conversationView:(InfinitConversationViewController*)sender
    wantsTransferForUser:(IAUser*)user
{
  if (_general_send_controller == nil)
    _general_send_controller = [[IAGeneralSendController alloc] initWithDelegate:self];
  [_general_send_controller openWithFiles:nil forUser:user];
}

- (void)conversationViewWantsBack:(InfinitConversationViewController*)sender
{
  [self showNotifications];
}

- (void)conversationView:(InfinitConversationViewController*)sender
  wantsAcceptTransaction:(IATransaction*)transaction
{
  [_transaction_manager acceptTransaction:transaction];
}

- (void)conversationView:(InfinitConversationViewController*)sender
  wantsCancelTransaction:(IATransaction*)transaction
{
  [_transaction_manager cancelTransaction:transaction];
}

- (void)conversationView:(InfinitConversationViewController*)sender
  wantsRejectTransaction:(IATransaction*)transaction
{
  [_transaction_manager rejectTransaction:transaction];
}

//- Desktop Notifier Protocol ----------------------------------------------------------------------

- (void)desktopNotifier:(IADesktopNotifier*)sender
hadClickNotificationForTransactionId:(NSNumber*)transaction_id
{
  if (_onboard_controller.state == INFINIT_ONBOARDING_RECEIVE_NOTIFICATION ||
      _onboard_controller.state == INFINIT_ONBOARDING_RECEIVE_NO_ACTION)
  {
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(waitForUserToClickNotification)
                                               object:nil];
    _onboard_controller.state = INFINIT_ONBOARDING_RECEIVE_IN_CONVERSATION_VIEW;
  }
  
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

- (NSArray*)sendController:(IAGeneralSendController*)sender
            wantsSendFiles:(NSArray*)files
                   toUsers:(NSArray*)users
               withMessage:(NSString*)message
{
  return [_transaction_manager sendFiles:files
                                 toUsers:users
                             withMessage:message];
}

- (NSArray*)sendControllerWantsFavourites:(IAGeneralSendController*)sender
{
  return [IAUserManager favouritesList];
}

- (NSArray*)sendControllerWantsSwaggers:(IAGeneralSendController*)sender
{
  return [IAUserManager swaggerList];
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

- (void)sendController:(IAGeneralSendController*)sender
wantsSetOnboardingSendTransactionId:(NSNumber*)transaction_id
{
  if (_onboard_controller == nil)
    return;
  
  _onboard_controller.send_transaction = [_transaction_manager transactionWithId:transaction_id];
}

//- Login Items ------------------------------------------------------------------------------------

- (void)addToLoginItems
{
#ifdef BUILD_PRODUCTION
  if (![[IAAutoStartup sharedInstance] appInLoginItemList])
    [[IAAutoStartup sharedInstance] addAppAsLoginItem];
#endif
}

- (BOOL)appInLoginItems
{
  return [[IAAutoStartup sharedInstance] appInLoginItemList];
}

- (void)removeFromLoginItems
{
#ifdef BUILD_PRODUCTION
  if ([[IAAutoStartup sharedInstance] appInLoginItemList])
    [[IAAutoStartup sharedInstance] removeAppFromLoginItem];
#endif
}

//- Login Window Protocol --------------------------------------------------------------------------

- (void)tryLogin:(InfinitLoginViewController*)sender
        username:(NSString*)username
        password:(NSString*)password
{
  if (sender == _login_view_controller)
  {
    _new_credentials = YES;
    [self loginWithUsername:username password:password];
  }
}

- (void)loginViewWantsClose:(InfinitLoginViewController*)sender
{
  [self closeNotificationWindow];
  _login_view_controller = nil;
}

- (void)loginViewWantsCloseAndQuit:(InfinitLoginViewController*)sender
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
  if ([_current_view_controller isKindOfClass:IANotificationListViewController.class])
  {
    [_notification_view_controller setConnected:status];
  }
  if (status == gap_user_status_online)
    [IAUserManager resyncUserStatuses];
  else if (status == gap_user_status_offline)
    [IAUserManager setAllUsersOffline];
}

//- No Connection View Protocol --------------------------------------------------------------------

- (void)noConnectionViewWantsBack:(IANoConnectionViewController*)sender
{
  [self showNotifications];
}

//- Notification List Protocol ---------------------------------------------------------------------

- (void)notificationListWantsLogout:(IANotificationListViewController*)sender
{
  [self handleLogout];
}

- (void)notificationListWantsQuit:(IANotificationListViewController*)sender
{
  [self handleQuit];
}

- (void)notificationList:(IANotificationListViewController*)sender
wantsMarkTransactionRead:(IATransaction*)transaction
{
  [_transaction_manager markTransactionAsRead:transaction];
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

- (NSUInteger)notificationList:(IANotificationListViewController*)sender
     unreadTransactionsForUser:(IAUser*)user
{
  return [_transaction_manager unreadAndNeedingActionTransactionsForUser:user];
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

- (BOOL)notificationListWantsAutoStartStatus:(IANotificationListViewController*)sender
{
  return [self appInLoginItems];
}

- (void)notificationList:(IANotificationListViewController*)sender
            setAutoStart:(BOOL)state
{
  if (state)
  {
    [self addToLoginItems];
  }
  else
  {
    [self removeFromLoginItems];
  }
}

//- Not Logged In Protocol -------------------------------------------------------------------------

- (void)notLoggedInViewWantsQuit:(IANotLoggedInViewController*)sender
{
  [self handleQuit];
}

//- Clippy Protocol --------------------------------------------------------------------------------

- (void)clippyViewGotDoneClicked:(InfinitClippyViewController*)sender
{
  if (_clippy_view_controller.mode == INFINIT_CLIPPY_TRANSFER_PENDING)
  {
    _onboard_controller.state = INFINIT_ONBOARDING_RECEIVE_CLICKED_ICON;
  }
  else if (_clippy_view_controller.mode == INFINIT_CLIPPY_DRAG_AND_DROP)
  {
    _onboard_controller.state = INFINIT_ONBOARDING_SEND_NO_FILES_NO_DESTINATION;
  }
  [self closeNotificationWindow];
}

//- Onboarding Protocol ----------------------------------------------------------------------------

- (void)doneOnboarding
{
  [[IAUserPrefs sharedInstance] setPref:@"4" forKey:@"onboarded"];
}

- (void)onboardingStateChanged:(InfinitOnboardingController*)sender
                       toState:(InfinitOnboardingState)state
{
  switch (state)
  {
    case INFINIT_ONBOARDING_RECEIVE_NO_ACTION:
      [self showClippyViewWithMode:INFINIT_CLIPPY_TRANSFER_PENDING];
      return;
      
    case INFINIT_ONBOARDING_RECEIVE_VIEW_DOWNLOAD:
      _onboard_controller.state = INFINIT_ONBOARDING_RECEIVE_DONE;
      [self performSelector:@selector(delayShowClippyDragAndDrop) withObject:nil afterDelay:145.0];
      return;
      
    case INFINIT_ONBOARDING_RECEIVE_CONVERSATION_VIEW_DONE:
      _onboard_controller.state = INFINIT_ONBOARDING_RECEIVE_DONE;
      [self performSelector:@selector(delayShowClippyDragAndDrop) withObject:nil afterDelay:3.0];
      return;
      
    case INFINIT_ONBOARDING_DONE:
      [self doneOnboarding];
      
    default:
      return;
  }
}

- (void)delayShowClippyDragAndDrop
{
  if (_current_view_controller == nil)
    [self showClippyViewWithMode:INFINIT_CLIPPY_DRAG_AND_DROP];
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
  if (_onboard_controller.state == INFINIT_ONBOARDING_RECEIVE_NO_ACTION)
  {
    _onboard_controller.state = INFINIT_ONBOARDING_RECEIVE_CLICKED_ICON;
    [self showNotifications];
  }
  else if (_onboard_controller.state == INFINIT_ONBOARDING_RECEIVE_DONE)
  {
    _onboard_controller.state = INFINIT_ONBOARDING_SEND_NO_FILES_NO_DESTINATION;
    [self showNotifications];
  }
  
  if (_popover_controller != nil)
  {
    [_popover_controller hidePopover];
    _popover_controller = nil;
  }
  
  if ([_window_controller windowIsOpen])
  {
    [self closeNotificationWindow];
  }
  else
  {
    [self selectView];
  }
}

- (void)delayedOpenSendView:(NSArray*)files
{
  if (_general_send_controller == nil)
    _general_send_controller = [[IAGeneralSendController alloc] initWithDelegate:self];
  [_general_send_controller openWithFiles:files forUser:nil];
}


- (void)statusBarIconDragDrop:(IAStatusBarIcon*)sender
                    withFiles:(NSArray*)files
{
  if (![[IAGapState instance] logged_in])
    return;
  
  if (_onboard_controller.state == INFINIT_ONBOARDING_RECEIVE_DONE ||
      _onboard_controller.state == INFINIT_ONBOARDING_SEND_NO_FILES_NO_DESTINATION)
  {
    _onboard_controller.state = INFINIT_ONBOARDING_SEND_FILES_NO_DESTINATION;
    [self closeNotificationWindow];
    [self performSelector:@selector(delayedOpenSendView:) withObject:files afterDelay:0.4];
  }
  else
  {
    if (_general_send_controller == nil)
      _general_send_controller = [[IAGeneralSendController alloc] initWithDelegate:self];
    [_general_send_controller openWithFiles:files forUser:nil];
  }
}

- (void)statusBarIconDragEntered:(IAStatusBarIcon*)sender
{
  if (![[IAGapState instance] logged_in] ||
      [_me_manager connection_status] != gap_user_status_online ||
      [self onboardingState:nil] != INFINIT_ONBOARDING_DONE)
  {
    return;
  }
  
  if (_general_send_controller == nil)
    _general_send_controller = [[IAGeneralSendController alloc] initWithDelegate:self];
  [_general_send_controller filesOverStatusBarIcon];
}

//- Stay Awake Manager Protocol --------------------------------------------------------------------

- (BOOL)stayAwakeManagerWantsActiveTransactions:(InfinitStayAwakeManager*)sender
{
  return  [_transaction_manager hasTransferringTransaction];
}

//- Transaction Manager Protocol -------------------------------------------------------------------

- (BOOL)notificationViewOpen
{
  if ([_current_view_controller isKindOfClass:IANotificationListViewController.class])
    return YES;
  return NO;
}

- (BOOL)conversationViewOpen
{
  if ([_current_view_controller isKindOfClass:InfinitConversationViewController.class])
    return YES;
  return NO;
}

- (void)markTransactionReadIfNeeded:(IATransaction*)transaction
{
  if ([self notificationViewOpen])
  {
    if ([_transaction_manager activeTransactionsForUser:transaction.other_user] == 0 &&
        [_transaction_manager unreadAndNeedingActionTransactionsForUser:transaction.other_user] == 1)
    {
      [_transaction_manager markTransactionAsRead:transaction];
    }
  }
  else if ([self conversationViewOpen])
  {
    if ([transaction.other_user isEqual:[(InfinitConversationViewController*)_current_view_controller user]])
    {
      [_transaction_manager markTransactionAsRead:transaction];
    }
  }
}

- (void)transactionManager:(IATransactionManager*)sender
          transactionAdded:(IATransaction*)transaction
{
  [self markTransactionReadIfNeeded:transaction];
  
  if ([IAFunctions osxVersion] != INFINIT_OS_X_VERSION_10_7)
    [_desktop_notifier desktopNotificationForTransaction:transaction];
  
  if (_current_view_controller == nil)
    return;
  
  [_current_view_controller transactionAdded:transaction];
}

- (void)transactionManager:(IATransactionManager*)sender
        transactionUpdated:(IATransaction*)transaction
{
  [self markTransactionReadIfNeeded:transaction];
  
  if ([IAFunctions osxVersion] != INFINIT_OS_X_VERSION_10_7)
    [_desktop_notifier desktopNotificationForTransaction:transaction];
  
  if (_onboard_controller.state == INFINIT_ONBOARDING_SEND_FILE_SENDING &&
      _onboard_controller.send_transaction == transaction &&
      transaction.is_done)
  {
    _onboard_controller.state = INFINIT_ONBOARDING_SEND_FILE_SENT;
  }
  
  if (_current_view_controller == nil)
    return;
  
  [_current_view_controller transactionUpdated:transaction];
}

- (void)transactionManagerHasGotHistory:(IATransactionManager*)sender
{
  if (_current_view_controller == nil)
    return;
  [_me_manager setConnection_status:gap_user_status_online];
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

- (void)transactionManagerHadFileSent:(IATransactionManager*)sender
{
  [_sent_sound play];
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

//- View Controller Protocol -----------------------------------------------------------------------

- (InfinitOnboardingState)onboardingState:(IAViewController*)sender
{
  if (_onboard_controller == nil)
    return INFINIT_ONBOARDING_DONE;
  
  return _onboard_controller.state;
}

- (BOOL)onboardingSend:(IAViewController*)sender
{
  return [_onboard_controller inSendOnboarding];
}

- (void)setOnboardingState:(InfinitOnboardingState)state
{
  _onboard_controller.state = state;
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

//- Kicked Out Callback ----------------------------------------------------------------------------

- (void)delayedRetryLogin
{
  if (![self tryAutomaticLogin])
  {
    ELLE_WARN("%s: autologin failed", self.description.UTF8String);
    // WORKAROUND: Need delay before showing window, otherwise status bar icon midpoint
    // is miscalculated
    [self performSelector:@selector(delayedLoginViewOpen) withObject:nil afterDelay:0.3];
  }
}

- (void)kickedOutCallback
{
  // Try to automatically login after a couple of seconds
  [self performSelector:@selector(delayedRetryLogin) withObject:nil afterDelay:3.0];
}

@end
