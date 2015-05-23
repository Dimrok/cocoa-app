//
//  IAMainController.mm
//  InfinitApplication
//
//  Created by Christopher Crone on 7/26/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAMainController.h"

#import "IAAutoStartup.h"
#import "IAGeneralSendController.h"
#import "IANoConnectionViewController.h"
#import "IANotLoggedInViewController.h"
#import "IAReportProblemWindowController.h"
#import "IAStatusBarIcon.h"
#import "IAUserPrefs.h"
#import "IAViewController.h"
#import "IAWindowController.h"
#import "InfinitAddressBookManager.h"
#import "InfinitConversationViewController.h"
#import "InfinitDesktopNotifier.h"
#import "InfinitDownloadDestinationManager.h"
#import "InfinitFacebookWindowController.h"
#import "InfinitFeatureManager.h"
#import "InfinitKeychain.h"
#import "InfinitLoginViewController.h"
#import "InfinitMainViewController.h"
#import "InfinitMetricsManager.h"
#import "InfinitNetworkManager.h"
#import "InfinitOnboardingController.h"
#import "InfinitQuotaWindowController.h"
#import "InfinitScreenshotManager.h"
#import "InfinitSettingsWindow.h"
#import "InfinitStatusBarIcon.h"
#import "InfinitStayAwakeManager.h"
#import "InfinitTooltipViewController.h"

#import <Gap/InfinitConnectionManager.h>
#import <Gap/InfinitLinkTransactionManager.h>
#import <Gap/InfinitPeerTransactionManager.h>
#import <Gap/InfinitStateManager.h>
#import <Gap/InfinitStateResult.h>
#import <Gap/InfinitUser.h>
#import <Gap/InfinitUserManager.h>

#undef check
#import <elle/log.hh>
#import <surface/gap/enums.hh>

ELLE_LOG_COMPONENT("OSX.ApplicationController");

@interface IAMainController () <IAGeneralSendControllerProtocol,
                                IANoConnectionViewProtocol,
                                IANotLoggedInViewProtocol,
                                IAReportProblemProtocol,
                                IAStatusBarIconProtocol,
                                IAViewProtocol,
                                IAWindowControllerProtocol,
                                InfinitConversationViewProtocol,
                                InfinitDesktopNotifierProtocol,
                                InfinitFacebookWindowProtocol,
                                InfinitLoginViewControllerProtocol,
                                InfinitMainViewProtocol,
                                InfinitOnboardingProtocol,
                                InfinitSettingsProtocol,
                                InfinitStatusBarIconProtocol,
                                InfinitStayAwakeProtocol>

@property (nonatomic, readonly) InfinitConnectionManager* connection_manager;
@property (nonatomic, readonly) InfinitQuotaWindowController* quota_window;

@end

@implementation IAMainController
{
@private
  id<IAMainControllerProtocol> _delegate;

  // Old Status Bar Icon.
  NSStatusItem* _old_status_item;
  IAStatusBarIcon* _status_bar_icon;

  // New Status Bar Icon (10.10+).
  InfinitStatusBarIcon* _status_item;

  // View controllers
  IAViewController* _current_view_controller;
  InfinitConversationViewController* _conversation_view_controller;
  IAGeneralSendController* _general_send_controller;
  InfinitLoginViewController* _login_view_controller;
  IANoConnectionViewController* _no_connection_view_controller;
  IANotLoggedInViewController* _not_logged_view_controller;
  InfinitOnboardingController* _onboard_controller;
  IAReportProblemWindowController* _report_problem_controller;
  InfinitSettingsWindow* _settings_window;
  IAWindowController* _window_controller;
  InfinitMainViewController* _main_view_controller;
  InfinitTooltipViewController* _tooltip_controller;

  // Facebook Window
  InfinitFacebookWindowController* _facebook_window;
  
  // Infinit Link Handling
  NSURL* _infinit_link;

  // Contextual Send Files Handling
  NSArray* _contextual_send_files;
  NSArray* _contextual_link_files;
  
  // Managers
  InfinitStayAwakeManager* _stay_awake_manager;
  
  // Other
  NSSound* _sent_sound;
  
  // Login
  BOOL _logging_in;
  NSString* _password;
  BOOL _new_credentials;
  BOOL _update_credentials;
  NSString* _username;
  CGFloat _login_retry_cooldown;
  CGFloat _login_retry_cooldown_max;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithDelegate:(id<IAMainControllerProtocol>)delegate
{
  if (self = [super init])
  {
    _delegate = delegate;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(connectionStatusChanged:)
                                                 name:INFINIT_CONNECTION_STATUS_CHANGE
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(linkTransactionCreated:)
                                                 name:INFINIT_LINK_TRANSACTION_CREATED_NOTIFICATION
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(linkTransactionAdded:)
                                                 name:INFINIT_NEW_LINK_TRANSACTION_NOTIFICATION
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(linkTransactionUpdated:)
                                                 name:INFINIT_LINK_TRANSACTION_STATUS_NOTIFICATION
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(peerTransactionCreated:)
                                                 name:INFINIT_PEER_TRANSACTION_CREATED_NOTIFICATION
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(peerTransactionAdded:)
                                                 name:INFINIT_NEW_PEER_TRANSACTION_NOTIFICATION
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(peerTransactionUpdated:)
                                                 name:INFINIT_PEER_TRANSACTION_STATUS_NOTIFICATION
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(peerTransactionAccepted:)
                                                 name:INFINIT_PEER_TRANSACTION_ACCEPTED_NOTIFICATION
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(quotaExceeded)
                                                 name:INFINIT_LINK_QUOTA_EXCEEDED
                                               object:nil];

    _connection_manager = [InfinitConnectionManager sharedInstance];
    _stay_awake_manager = [InfinitStayAwakeManager setUpInstanceWithDelegate:self];


    if ([IAFunctions osxVersion] < INFINIT_OS_X_VERSION_10_10)
    {
      _old_status_item = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
      _status_bar_icon = [[IAStatusBarIcon alloc] initWithDelegate:self statusItem:_old_status_item];
      _old_status_item.view = _status_bar_icon;
    }
    else
    {
      _status_item = [[InfinitStatusBarIcon alloc] initWithDelegate:self];
    }
    
    _window_controller = [[IAWindowController alloc] initWithDelegate:self];
    _current_view_controller = nil;
    
    if ([IAFunctions osxVersion] != INFINIT_OS_X_VERSION_10_7)
      [InfinitDesktopNotifier sharedInstance].delegate = self;

    [InfinitAddressBookManager sharedInstance];
    
    _infinit_link = nil;
    _contextual_send_files = nil;
    _contextual_link_files = nil;
    
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
  }
  return self;
}

- (void)dealloc
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

//- Check Server Connectivity ----------------------------------------------------------------------

- (void)delayedLoginViewOpen
{
  if (_login_view_controller == nil)
  {
    _login_view_controller =
      [[InfinitLoginViewController alloc] initWithDelegate:self
                                                  withMode:InfinitLoginViewModeRegister];
  }
  [self openOrChangeViewController:_login_view_controller];
}

- (BOOL)tryAutomaticLogin
{
  if ([_delegate applicationUpdating])
    return NO;
  if ([[[IAUserPrefs sharedInstance] prefsForKey:@"facebook_connect"] isEqualToString:@"1"])
  {
    _facebook_window = [[InfinitFacebookWindowController alloc] initWithDelegate:self];
    [_facebook_window showWindow:self];
    return YES;
  }
  else
  {
    NSString* username = [[IAUserPrefs sharedInstance] prefsForKey:@"user:email"];
    NSString* password = [[InfinitKeychain sharedInstance] passwordForAccount:username];
    if (username && username.length > 0 && password && password.length > 0)
    {
      _logging_in = YES;
      [self loginWithUsername:username password:password];
      password = @"";
      password = nil;
      return YES;
    }
  }
  return NO;
}

//- Handle Infinit Link ----------------------------------------------------------------------------

- (void)handleInfinitLink:(NSURL*)link
{
  // If we're not logged in, store the link and activate it when we are.
  if (![InfinitConnectionManager sharedInstance].connected)
  {
    _infinit_link = link;
    return;
  }

  NSString* scheme = link.scheme;
  if (![scheme isEqualToString:@"infinit"])
  {
    ELLE_WARN("%s: unknown scheme in link: %s", self.description.UTF8String,
              link.description.UTF8String);
    return;
  }
  NSString* action = link.host;
  if ([action isEqualToString:@"send"])
  {
    [self openSendViewForLink:link];
  }
  else if ([action isEqualToString:@"open"])
  {
    [self showNotifications];
  }
  else
  {
    ELLE_WARN("%s: unknown action in link: %s", self.description.UTF8String,
              link.description.UTF8String);
    return;
  }
}

- (void)linkHandleUserCallback:(InfinitStateResult*)result
{
  if (!result.success)
  {
    ELLE_WARN("%s: problem checking for link user id", self.description.UTF8String);
    return;
  }
  NSDictionary* dict = result.data;
  NSNumber* user_id = dict[kInfinitUserId];
  if (user_id.unsignedIntValue == 0)
  {
    ELLE_WARN("%s: link user not on Infinit: %s", self.description.UTF8String,
              [[dict valueForKey:@"handle"] description].UTF8String);
    return;
  }
  InfinitUser* user = [[InfinitUserManager sharedInstance] userWithId:user_id];

  _general_send_controller = [[IAGeneralSendController alloc] initWithDelegate:self];
  [_general_send_controller openWithFiles:nil forUser:user];
}

- (void)openSendViewForLink:(NSURL*)link
{
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
  NSMutableDictionary* handle_check = [NSMutableDictionary dictionary];
  [[InfinitStateManager sharedInstance] userByHandle:handle
                                     performSelector:@selector(linkHandleUserCallback:)
                                            onObject:self
                                            withData:handle_check];
  _infinit_link = nil;
}

//- Handle Contextual ------------------------------------------------------------------------------

- (void)handleContextualSendFiles:(NSArray*)files
{
  // If we're not logged in, store files and open view when we're ready.
  if (!self.connection_manager.connected)
  {
    _contextual_send_files = files;
    return;
  }

  [self openSendViewForFiles:files];
  _contextual_send_files = nil;
  [InfinitMetricsManager sendMetric:INFINIT_METRIC_CONTEXTUAL_SEND];
}

- (void)openSendViewForFiles:(NSArray*)files
{
  if (![_current_view_controller isKindOfClass:InfinitSendViewController.class])
  {
    if ([IAFunctions osxVersion] < INFINIT_OS_X_VERSION_10_10)
      [_status_bar_icon setHighlighted:YES];
    else
      _status_item.open = YES;
    _general_send_controller = [[IAGeneralSendController alloc] initWithDelegate:self];
  }
  [_general_send_controller openWithFiles:files forUser:nil];
  _contextual_send_files = nil;
}

- (void)handleContextualCreateLink:(NSArray*)files
{
  if (!self.connection_manager.connected)
  {
    _contextual_link_files = files;
    return;
  }
  [self createLinkWithFiles:files andMessage:@"" forScreenshot:NO];
  _contextual_link_files = nil;
  [InfinitMetricsManager sendMetric:INFINIT_METRIC_CONTEXTUAL_LINK];
}

- (NSNumber*)createLinkWithFiles:(NSArray*)files
                      andMessage:(NSString*)message
                   forScreenshot:(BOOL)screenshot
{
  InfinitLinkTransactionManager* manager = [InfinitLinkTransactionManager sharedInstance];
  if (screenshot)
    return [manager createScreenshotLink:files.firstObject];
  else
    return [manager createLinkWithFiles:files withMessage:message];
}

//- Handle Views -----------------------------------------------------------------------------------

- (void)openOrChangeViewController:(IAViewController*)view_controller
{
  bool open = YES;
  if ([IAFunctions osxVersion] < INFINIT_OS_X_VERSION_10_10)
    [_status_bar_icon setHighlighted:open];
  else
    _status_item.open = open;
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

- (void)showConversationViewForUser:(InfinitUser*)user
{
  _conversation_view_controller =
    [[InfinitConversationViewController alloc] initWithDelegate:self
                                                        forUser:user];
  [self openOrChangeViewController:_conversation_view_controller];
}

- (void)showNotifications
{
  if ([IAFunctions osxVersion] != INFINIT_OS_X_VERSION_10_7)
    [[InfinitDesktopNotifier sharedInstance] clearAllNotifications];
  _main_view_controller = [[InfinitMainViewController alloc] initWithDelegate:self
                                                                forPeopleView:YES];
  [self openOrChangeViewController:_main_view_controller];
}

- (void)showLinks
{
  if ([IAFunctions osxVersion] != INFINIT_OS_X_VERSION_10_7)
    [[InfinitDesktopNotifier sharedInstance] clearAllNotifications];
  _main_view_controller = [[InfinitMainViewController alloc] initWithDelegate:self
                                                                forPeopleView:NO];
  [self openOrChangeViewController:_main_view_controller];
}

- (void)showLoginView
{
  [self showLoginViewForMode:InfinitLoginViewModeRegister];
}

- (void)showLoginViewForMode:(InfinitLoginViewMode)mode
{
  if (_login_view_controller == nil)
  {
    _login_view_controller =
    [[InfinitLoginViewController alloc] initWithDelegate:self withMode:mode];
  }
  [self openOrChangeViewController:_login_view_controller];
}

- (void)showNotLoggedInView
{
  if (self.connection_manager.still_trying)
  {
    if (_not_logged_view_controller == nil)
    {
      _not_logged_view_controller =
        [[IANotLoggedInViewController alloc] initWithMode:INFINIT_WAITING_FOR_CONNECTION
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
      _not_logged_view_controller =
        [[IANotLoggedInViewController alloc] initWithMode:INFINIT_LOGGING_IN andDelegate:self];
    }
    else
    {
      [_not_logged_view_controller setMode:INFINIT_LOGGING_IN];
    }
    [self openOrChangeViewController:_not_logged_view_controller];
  }
  else
  {
    [self showLoginViewForMode:InfinitLoginViewModeLogin];
  }
}

- (void)showSendView:(IAViewController*)controller
{
  if (![InfinitConnectionManager sharedInstance].connected)
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
    [[InfinitDesktopNotifier sharedInstance] clearAllNotifications];
  [_window_controller closeWindow];
  if ([IAFunctions osxVersion] < INFINIT_OS_X_VERSION_10_10)
    [_status_bar_icon setHighlighted:NO];
  else
    _status_item.open = NO;
}

- (void)closeNotificationWindowWithoutLosingFocus
{
  if ([IAFunctions osxVersion] != INFINIT_OS_X_VERSION_10_7)
    [[InfinitDesktopNotifier sharedInstance] clearAllNotifications];
  [_window_controller closeWindowWithoutLosingFocus];
  if ([IAFunctions osxVersion] < INFINIT_OS_X_VERSION_10_10)
    [_status_bar_icon setHighlighted:NO];
  else
    _status_item.open = NO;
}

//- Login and Logout -------------------------------------------------------------------------------

- (void)loginWithUsername:(NSString*)username
                 password:(NSString*)password
{
  _logging_in = YES;
  if (_current_view_controller == _not_logged_view_controller)
    [_not_logged_view_controller setMode:INFINIT_LOGGING_IN];

  [[InfinitNetworkManager sharedInstance] checkProxySettings];
  
  [[InfinitStateManager sharedInstance] login:username
                                     password:password
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
  [InfinitScreenshotManager sharedInstance];

  if ([[[IAUserPrefs sharedInstance] prefsForKey:@"updated"] isEqualToString:@"1"])
  {
    [[IAUserPrefs sharedInstance] setPref:@"0" forKey:@"updated"];
    [[InfinitDesktopNotifier sharedInstance] desktopNotificationForApplicationUpdated];
  }

  _login_view_controller = nil;

  if (![[[IAUserPrefs sharedInstance] prefsForKey:@"onboarded"] isEqualToString:@"4"])
  {
    [self closeNotificationWindow];
    [self startOnboarding];
    [self saveOnboardingDone];
  }
  else if (_current_view_controller != nil &&
           _current_view_controller != _main_view_controller)
  {
    [self showNotifications];
  }
}

- (void)onUnsuccessfulLogin:(InfinitStateResult*)result
{
  ELLE_ERR("%s: couldn't login with status: %d", self.description.UTF8String, result.status);
  NSString* error;
  switch (result.status)
  {
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
      return;

    case gap_deprecated:
      error = [NSString stringWithFormat:@"%@",
               NSLocalizedString(@"Please update Infinit.", @"please update infinit.")];
      [_delegate mainControllerWantsCheckForUpdate:self];
      break;

    case gap_email_not_confirmed:
      error = [NSString stringWithFormat:@"%@",
               NSLocalizedString(@"You need to confirm your email, check your inbox.", nil)];
      break;

    case gap_meta_down_with_message:
      error = [NSString stringWithFormat:@"%@",
               NSLocalizedString(@"Infinit is currently unavailable.",
                                 @"infinit is currently unavailable")];
      // XXX display actual Meta message
      break;

    default:
      error = [NSString stringWithFormat:@"%@.",
               NSLocalizedString(@"Unknown login error", @"unknown login error")];
      break;
  }


  if (_login_view_controller == nil)
  {
    _login_view_controller =
      [[InfinitLoginViewController alloc] initWithDelegate:self
                                                  withMode:InfinitLoginViewModeLoginCredentials];
  }
  else
  {
    _login_view_controller.mode = InfinitLoginViewModeLoginCredentials;
  }

  NSString* username = [[IAUserPrefs sharedInstance] prefsForKey:@"user:email"];
  NSString* password = [[InfinitKeychain sharedInstance] passwordForAccount:username];

  if (username == nil)
    username = @"";
  if (password == nil)
    password = @"";

  if (_current_view_controller != _login_view_controller)
    [self showLoginViewForMode:InfinitLoginViewModeLoginCredentials];

  [_login_view_controller showWithError:error
                               username:username
                            andPassword:password];

  password = @"";
  password = nil;
}

- (void)loginCallback:(InfinitStateResult*)result
{
  _logging_in = NO;
  if (result.success)
  {
    [self onSuccessfulLogin];
    [_delegate mainControllerWantsBackgroundUpdateChecks:self];
  }
  else
  {
    [self onUnsuccessfulLogin:result];
  }
}

- (void)facebookConnectCallback:(InfinitStateResult*)result
{
  _logging_in = NO;
  if (result.success)
  {
    [self onSuccessfulLogin];
    [_delegate mainControllerWantsBackgroundUpdateChecks:self];
  }
  else
  {
    [self onUnsuccessfulLogin:result];
  }
}

- (void)logoutCallback:(InfinitStateResult*)result
{
  if (result.success)
    ELLE_LOG("%s: logged out", self.description.UTF8String);
  else
    ELLE_WARN("%s: logout failed", self.description.UTF8String);
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
  NSRect frame;
  if ([IAFunctions osxVersion] < INFINIT_OS_X_VERSION_10_10)
  {
    frame = _old_status_item.view.window.frame;
  }
  else
  {
    frame = _status_item.frame;
  }
  NSPoint result = NSMakePoint(floor(frame.origin.x + frame.size.width / 2.0),
                               floor(frame.origin.y - 5.0));
  CGFloat x_screen_edge =
    [NSScreen mainScreen].frame.origin.x + [NSScreen mainScreen].frame.size.width;
  if (result.x + (_window_controller.window.frame.size.width / 2.0) > x_screen_edge)
    result.x = x_screen_edge - (_window_controller.window.frame.size.width / 2.0) - 10.0;
  return result;
}

- (void)showLoginViewForLogout
{
  [self showLoginViewForMode:InfinitLoginViewModeLogin];
}

- (void)logoutAndShowLoginCallback:(InfinitStateResult*)result
{
  _settings_window = nil;
  if (result.success)
  {
    ELLE_LOG("%s: logged out", self.description.UTF8String);
    [self performSelector:@selector(showLoginViewForLogout) withObject:nil afterDelay:0.3];
  }
  else
  {
    ELLE_WARN("%s: logout failed", self.description.UTF8String);
  }
}

- (void)handleLogout
{
  [[IAUserPrefs sharedInstance] setPref:@"0" forKey:@"facebook_connect"];
  NSString* username = [[IAUserPrefs sharedInstance] prefsForKey:@"user:email"];
  if (username.length)
    [[InfinitKeychain sharedInstance] removeAccount:username];
  [_settings_window close];
  [self closeNotificationWindow];
  [[InfinitStateManager sharedInstance] logoutPerformSelector:@selector(logoutAndShowLoginCallback:)
                                                     onObject:self];
}

- (void)handleQuit
{
  _stay_awake_manager = nil;

  if ([IAFunctions osxVersion] < INFINIT_OS_X_VERSION_10_10)
  {
    [_status_bar_icon setHighlighted:NO];
    [_status_bar_icon setHidden:YES];
  }
  else
  {
    _status_item.open = NO;
    _status_item.hidden = YES;
  }
  [_window_controller closeWindowWithAnimation:NO];


  if ([NSApp modalWindow] != nil)
    [NSApp abortModal];
  [InfinitStateManager stopState];
  [_delegate terminateApplication:self];
}

- (BOOL)transfersInProgress
{
  InfinitLinkTransactionManager* link_manager = [InfinitLinkTransactionManager sharedInstance];
  InfinitPeerTransactionManager* peer_manager = [InfinitPeerTransactionManager sharedInstance];
  if (!link_manager.running_transactions && !peer_manager.running_transactions)
    return NO;
  return YES;
}

- (BOOL)canUpdate
{
  if (!_logging_in && _current_view_controller == nil && ![self transfersInProgress])
  {
    ELLE_LOG("%s: can update", self.description.UTF8String);
    return YES;
  }
  else
  {
    ELLE_LOG("%s: preventing update", self.description.UTF8String);
    return NO;
  }
}

//- View Logic -------------------------------------------------------------------------------------

- (void)selectView
{
  if (![InfinitConnectionManager sharedInstance].was_logged_in)
  {
    [self showNotLoggedInView];
    return;
  }
  [self showNotifications];
}

//- Onboarding -------------------------------------------------------------------------------------

- (void)startOnboarding
{
  _onboard_controller = [[InfinitOnboardingController alloc] initForSendOnboardingWithDelegate:self];
}

- (InfinitPeerTransaction*)receiveOnboardingTransaction:(IAViewController*)sender;
{
  return _onboard_controller.receive_transaction;
}

- (InfinitPeerTransaction*)sendOnboardingTransaction:(IAViewController*)sender
{
  return _onboard_controller.send_transaction;
}

//- Conversation View Protocol ---------------------------------------------------------------------

- (void)conversationView:(InfinitConversationViewController*)sender
    wantsTransferForUser:(InfinitUser*)user
{
  if (![InfinitConnectionManager sharedInstance].connected)
  {
    [self showNotConnectedView];
  }
  else
  {
    _general_send_controller = [[IAGeneralSendController alloc] initWithDelegate:self];
    [_general_send_controller openWithFiles:nil forUser:user];
  }
}

- (void)conversationViewWantsBack:(InfinitConversationViewController*)sender
{
  [self showNotifications];
}

//- Desktop Notifier Protocol ----------------------------------------------------------------------

- (void)desktopNotifier:(InfinitDesktopNotifier*)sender
hadClickNotificationForTransactionId:(NSNumber*)id_
{
  InfinitPeerTransaction* transaction =
    [[InfinitPeerTransactionManager sharedInstance] transactionWithId:id_];
  if (transaction == nil)
    return;

  [self showConversationViewForUser:transaction.other_user];
}

- (void)desktopNotifier:(InfinitDesktopNotifier*)sender
hadAcceptTransaction:(NSNumber*)id_
{
  InfinitPeerTransaction* transaction =
    [[InfinitPeerTransactionManager sharedInstance] transactionWithId:id_];
  if (transaction == nil)
    return;
  [[InfinitDownloadDestinationManager sharedInstance] ensureDownloadDestination];
  [[InfinitPeerTransactionManager sharedInstance] acceptTransaction:transaction withError:nil];
}

- (void)desktopNotifier:(InfinitDesktopNotifier*)sender
hadClickNotificationForLinkId:(NSNumber*)id_
{
  [self showLinks];
}

- (void)desktopNotifierHadClickApplicationUpdatedNotification:(InfinitDesktopNotifier*)sender
{
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

- (void)sendControllerWantsClose:(IAGeneralSendController*)sender
{
  [self closeNotificationWindow];
}

- (void)sendControllerWantsBack:(IAGeneralSendController*)sender
{
  [self showNotifications];
}

- (NSPoint)sendControllerWantsMidpoint:(IAGeneralSendController*)sender
{
  return [self statusBarIconMiddle];
}

- (void)sendController:(IAGeneralSendController*)sender
wantsSetOnboardingSendTransactionId:(NSNumber*)id_
{
  if (_onboard_controller == nil)
    return;
  
  _onboard_controller.send_transaction =
    [[InfinitPeerTransactionManager sharedInstance] transactionWithId:id_];
}

- (void)sendControllerGotDropOnFavourite:(IAGeneralSendController*)sender
{
  if ([_onboard_controller inSendOnboarding])
    _onboard_controller.state = INFINIT_ONBOARDING_SEND_FILE_SENDING;
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

//- Link Manager Protocol --------------------------------------------------------------------------

- (void)_copyLinkToClipboard:(InfinitLinkTransaction*)link
            withNotification:(BOOL)notify
{
  NSPasteboard* paste_board = [NSPasteboard generalPasteboard];
  [paste_board declareTypes:@[NSStringPboardType] owner:nil];
  [paste_board setString:link.link forType:NSStringPboardType];
  if (notify)
  {
    [self closeNotificationWindow];
    [[InfinitDesktopNotifier sharedInstance] desktopNotificationForLinkCopied:link];
  }
}

- (void)linkTransactionCreated:(NSNotification*)notification
{
  [_sent_sound play];
}

- (void)linkTransactionUpdated:(NSNotification*)notification
{
  NSNumber* id_ = notification.userInfo[kInfinitTransactionId];
  InfinitLinkTransaction* link =
    [[InfinitLinkTransactionManager sharedInstance] transactionWithId:id_];
  if (link.status == gap_transaction_transferring)
    [self _copyLinkToClipboard:link withNotification:NO];
}

- (void)linkTransactionAdded:(NSNotification*)notification
{
  NSNumber* id_ = notification.userInfo[kInfinitTransactionId];
  InfinitLinkTransaction* link =
    [[InfinitLinkTransactionManager sharedInstance] transactionWithId:id_];
  if (link.status == gap_transaction_transferring)
    [self _copyLinkToClipboard:link withNotification:NO];
}

- (void)copyLinkToClipboard:(InfinitLinkTransaction*)link
{
  [self _copyLinkToClipboard:link withNotification:YES];
}

//- Login Window Protocol --------------------------------------------------------------------------

- (void)loginViewDoneLogin:(InfinitLoginViewController*)sender
{
  [self onSuccessfulLogin];
}

- (void)loginViewDoneRegister:(InfinitLoginViewController*)sender
{
  [self showNotifications];
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

- (void)loginViewWantsReportProblem:(InfinitLoginViewController*)sender
{
  [self closeNotificationWindowWithoutLosingFocus];
  if (_report_problem_controller == nil)
    _report_problem_controller = [[IAReportProblemWindowController alloc] initWithDelegate:self];

  [_report_problem_controller show];
}

- (void)loginViewWantsCheckForUpdate:(InfinitLoginViewController*)sender
{
  [_delegate mainControllerWantsCheckForUpdate:self];
}

- (void)registered:(InfinitLoginViewController*)sender
         withEmail:(NSString*)email
{
  _username = email;
  [self onSuccessfulLogin];
  [_delegate mainControllerWantsBackgroundUpdateChecks:self];
  [self performSelector:@selector(showNotifications) withObject:nil afterDelay:0.5];
}

- (void)alreadyLoggedIn:(InfinitLoginViewController*)sender
{
  [_delegate mainControllerWantsBackgroundUpdateChecks:self];
  [self performSelector:@selector(showNotifications) withObject:nil afterDelay:0.5];
}

//- Main View Protocol -----------------------------------------------------------------------------

- (void)userGotClicked:(InfinitUser*)user
{
  [self showConversationViewForUser:user];
}

- (void)reportAProblem:(InfinitMainViewController*)sender
{
  [self closeNotificationWindowWithoutLosingFocus];
  if (_report_problem_controller == nil)
    _report_problem_controller = [[IAReportProblemWindowController alloc] initWithDelegate:self];

  [_report_problem_controller show];
}

- (void)settings:(InfinitMainViewController*)sender
{
  [self openPreferences];
  [InfinitMetricsManager sendMetric:INFINIT_METRIC_PREFERENCES];
}

- (void)logout:(InfinitMainViewController*)sender
{
  [self handleLogout];
}

- (void)quit:(InfinitMainViewController*)sender
{
  [self handleQuit];
}

- (void)sendGotClicked:(InfinitMainViewController*)sender
{
   _general_send_controller = [[IAGeneralSendController alloc] initWithDelegate:self];
  [_general_send_controller openWithNoFileForLink:NO];
}

- (void)makeLinkGotClicked:(InfinitMainViewController*)sender
{
  _general_send_controller = [[IAGeneralSendController alloc] initWithDelegate:self];
  [_general_send_controller openWithNoFileForLink:YES];
}

#pragma mark - Connection Status Handling

- (void)connectionStatusChanged:(NSNotification*)notification
{
  InfinitConnectionStatus* connection_status = notification.object;
  if (!connection_status.status && !connection_status.still_trying)
  {
    [self performSelectorOnMainThread:@selector(kickedOut) withObject:nil waitUntilDone:YES];
    return;
  }
  BOOL status = connection_status.status;

  if ([_current_view_controller isKindOfClass:IANoConnectionViewController.class] && status)
  {
    [self showNotifications];
  }
  if (status)
  {
    // If we've got unhandled link or service
    if (_infinit_link != nil)
      [self handleInfinitLink:_infinit_link];

    if (_contextual_send_files != nil)
    {
      [self handleContextualSendFiles:_contextual_send_files];
    }

    if (_contextual_link_files != nil)
      [self handleContextualCreateLink:_contextual_link_files];
  }
}

//- No Connection View Protocol --------------------------------------------------------------------

- (void)noConnectionViewWantsBack:(IANoConnectionViewController*)sender
{
  [self showNotifications];
}

//- Not Logged In Protocol -------------------------------------------------------------------------

- (void)notLoggedInViewWantsQuit:(IANotLoggedInViewController*)sender
{
  [self handleQuit];
}

//- Onboarding Protocol ----------------------------------------------------------------------------

- (void)saveOnboardingDone
{
  [[IAUserPrefs sharedInstance] setPref:@"4" forKey:@"onboarded"];
}

//- Report Problem Protocol ------------------------------------------------------------------------

- (void)reportProblemControllerDone:(IAReportProblemWindowController*)sender
{
  [_report_problem_controller close];
  _report_problem_controller = nil;
}

//- Settings Protocol ------------------------------------------------------------------------------

- (void)openPreferences
{
  if (![InfinitConnectionManager sharedInstance].connected)
    return;

  [self closeNotificationWindowWithoutLosingFocus];
  if (_settings_window == nil)
    _settings_window = [[InfinitSettingsWindow alloc] initWithDelegate:self];

  [_settings_window show];
}

- (BOOL)infinitInLoginItems:(InfinitSettingsWindow*)sender
{
  return [self appInLoginItems];
}

- (void)setInfinitInLoginItems:(InfinitSettingsWindow*)sender
                            to:(BOOL)value
{
  if (value && ![self appInLoginItems])
  {
    [self addToLoginItems];
  }
  else if (!value && [self appInLoginItems])
  {
    [self removeFromLoginItems];
  }
}

- (BOOL)stayAwake:(InfinitSettingsWindow*)sender
{
  return [InfinitStayAwakeManager stayAwake];
}

- (void)setStayAwake:(InfinitSettingsWindow*)sender
                  to:(BOOL)value
{
  [InfinitStayAwakeManager setStayAwake:value];
}

- (void)checkForUpdate:(InfinitSettingsWindow*)sender
{
  [_delegate mainControllerWantsCheckForUpdate:self];
}

//- Status Bar Icon Protocol (Old) -----------------------------------------------------------------

- (void)statusBarIconClicked:(id)sender
{
  if (_onboard_controller.state == INFINIT_ONBOARDING_RECEIVE_DONE)
  {
    _onboard_controller.state = INFINIT_ONBOARDING_SEND_NO_FILES_NO_DESTINATION;
    [self showNotifications];
  }
  
  if (_tooltip_controller != nil)
  {
    [_tooltip_controller close];
    _tooltip_controller = nil;
  }
  
  if ([_window_controller windowIsOpen])
  {
    [self closeNotificationWindow];
  }
  else
  {
    [self selectView];
    [InfinitMetricsManager sendMetric:INFINIT_METRIC_OPEN_PANEL];
  }
}

- (void)delayedOpenSendView:(NSArray*)files
{
  if (![_current_view_controller isKindOfClass:InfinitSendViewController.class])
    _general_send_controller = [[IAGeneralSendController alloc] initWithDelegate:self];
  [_general_send_controller openWithFiles:files forUser:nil];
}


- (void)statusBarIconDragDrop:(id)sender
                    withFiles:(NSArray*)files
{
  if (![InfinitConnectionManager sharedInstance].connected)
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
    if (![_current_view_controller isKindOfClass:InfinitSendViewController.class])
      _general_send_controller = [[IAGeneralSendController alloc] initWithDelegate:self];
    [_general_send_controller openWithFiles:files forUser:nil];
  }
}

- (void)statusBarIconLinkDrop:(IAStatusBarIcon*)sender
                    withFiles:(NSArray*)files
{
  [self createLinkWithFiles:files andMessage:@"" forScreenshot:NO];
}

- (void)statusBarIconDragEntered:(id)sender
{
  InfinitConnectionManager* manager = [InfinitConnectionManager sharedInstance];
  if (!manager.connected ||
      _current_view_controller.class == InfinitSendViewController.class ||
      [self onboardingState:nil] != INFINIT_ONBOARDING_DONE)
  {
    return;
  }
  if (![_current_view_controller isKindOfClass:InfinitSendViewController.class])
  {
    _general_send_controller = [[IAGeneralSendController alloc] initWithDelegate:self];
    [_general_send_controller filesOverStatusBarIcon];
  }
}

//- Stay Awake Manager Protocol --------------------------------------------------------------------

- (BOOL)stayAwakeManagerWantsActiveTransactions:(InfinitStayAwakeManager*)sender
{
  InfinitLinkTransactionManager* link_manager = [InfinitLinkTransactionManager sharedInstance];
  InfinitPeerTransactionManager* peer_manager = [InfinitPeerTransactionManager sharedInstance];
  return (link_manager.running_transactions || peer_manager.running_transactions);
}

//- Transaction Manager Protocol -------------------------------------------------------------------

- (BOOL)notificationViewOpen
{
  if ([_current_view_controller isKindOfClass:InfinitMainViewController.class])
    return YES;
  return NO;
}

- (BOOL)conversationViewOpen
{
  if ([_current_view_controller isKindOfClass:InfinitConversationViewController.class])
    return YES;
  return NO;
}

- (void)markTransactionReadIfNeeded:(InfinitPeerTransaction*)transaction
{
  InfinitPeerTransactionManager* manager = [InfinitPeerTransactionManager sharedInstance];
  if ([self notificationViewOpen])
  {
    if ([manager incompleteTransactionsWithUser:transaction.other_user] == 0 &&
        [manager unreadTransactionsWithUser:transaction.other_user] == 1)
    {
      [manager markTransactionRead:transaction];
    }
  }
  else if ([self conversationViewOpen])
  {
    if ([transaction.other_user isEqual:[(InfinitConversationViewController*)_current_view_controller user]])
    {
      [manager markTransactionRead:transaction];
    }
  }
}

- (void)peerTransactionCreated:(NSNotification*)notification
{
  [_sent_sound play];
}

- (void)peerTransactionAdded:(NSNotification*)notification
{
  NSNumber* id_ = notification.userInfo[kInfinitTransactionId];
  InfinitPeerTransaction* transaction =
    [[InfinitPeerTransactionManager sharedInstance] transactionWithId:id_];
  [self markTransactionReadIfNeeded:transaction];
}

- (void)peerTransactionUpdated:(NSNotification*)notification
{
  NSNumber* id_ = notification.userInfo[kInfinitTransactionId];
  InfinitPeerTransaction* transaction =
    [[InfinitPeerTransactionManager sharedInstance] transactionWithId:id_];
  [self markTransactionReadIfNeeded:transaction];
  
  if (_onboard_controller.state == INFINIT_ONBOARDING_SEND_FILE_SENDING &&
      _onboard_controller.send_transaction == transaction &&
      (transaction.done || transaction.status == gap_transaction_cloud_buffered))
  {
    _onboard_controller.state = INFINIT_ONBOARDING_SEND_FILE_SENT;
  }
}

- (void)peerTransactionAccepted:(NSNotification*)notification
{
  if ([IAFunctions osxVersion] != INFINIT_OS_X_VERSION_10_7)
  {
    NSNumber* id_ = notification.userInfo[kInfinitTransactionId];
    InfinitPeerTransaction* transaction =
      [[InfinitPeerTransactionManager sharedInstance] transactionWithId:id_];
    [[InfinitDesktopNotifier sharedInstance] desktopNotificationForTransactionAccepted:transaction];
  }
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

//- Kicked Out -------------------------------------------------------------------------------------

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

- (void)kickedOut
{
  ELLE_LOG("%s: user kicked out", self.description.UTF8String);
  // Try to automatically login after a couple of seconds
  [[IAUserPrefs sharedInstance] setPref:@"0" forKey:@"facebook_connect"];
  [self performSelector:@selector(delayedRetryLogin) withObject:nil afterDelay:3.0];
}

#pragma mark - Facebook Window Delegate

- (void)facebookWindow:(InfinitFacebookWindowController*)sender
              gotError:(NSString*)error
{

}

- (void)facebookWindow:(InfinitFacebookWindowController*)sender
              gotToken:(NSString*)token
{
  _logging_in = YES;
  [[InfinitStateManager sharedInstance] facebookConnect:token
                                           emailAddress:nil
                                        performSelector:@selector(facebookConnectCallback:)
                                               onObject:self];
}

#pragma mark - Quota

- (void)quotaExceeded
{
  NSString* class_name = NSStringFromClass(InfinitQuotaWindowController.class);
  _quota_window = [[InfinitQuotaWindowController alloc] initWithWindowNibName:class_name];
  [self.quota_window showWindow:self];
}

@end
