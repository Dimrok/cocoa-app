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
#import "IAUserPrefs.h"
#import "InfinitDownloadDestinationManager.h"
#import "InfinitFeatureManager.h"
#import "InfinitMetricsManager.h"
#import "InfinitTooltipViewController.h"

#undef check
#import <elle/log.hh>
#import <surface/gap/enums.hh>

ELLE_LOG_COMPONENT("OSX.ApplicationController");

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
  
  // Infinit Link Handling
  NSURL* _infinit_link;

  // Contextual Send Files Handling
  NSArray* _contextual_send_files;
  NSArray* _contextual_link_files;
  
  // Managers
  IAMeManager* _me_manager;
  InfinitStayAwakeManager* _stay_awake_manager;
  IATransactionManager* _transaction_manager;
  InfinitLinkManager* _link_manager;
  InfinitNetworkManager* _network_manager;
  InfinitScreenshotManager* _screenshot_manager;
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
    
    _me_manager = [[IAMeManager alloc] initWithDelegate:self];
    _transaction_manager = [[IATransactionManager alloc] initWithDelegate:self];
    _link_manager = [[InfinitLinkManager alloc] initWithDelegate:self];
    _network_manager = [[InfinitNetworkManager alloc] initWithDelegate:self];
    _user_manager = [IAUserManager sharedInstanceWithDelegate:self];
    
    if ([IAFunctions osxVersion] != INFINIT_OS_X_VERSION_10_7)
      _desktop_notifier = [[IADesktopNotifier alloc] initWithDelegate:self];
    
    _infinit_link = nil;
    _contextual_send_files = nil;
    _contextual_link_files = nil;

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
  if (_login_view_controller == nil)
    _login_view_controller = [[InfinitLoginViewController alloc] initWithDelegate:self
                                                                         withMode:INFINIT_LOGIN_VIEW_REGISTER];
  [self openOrChangeViewController:_login_view_controller];
}

- (BOOL)tryAutomaticLogin
{
  if ([_delegate applicationUpdating])
    return NO;
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
  if ([_me_manager connection_status] != gap_user_status_online)
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

//- Handle Contextual ------------------------------------------------------------------------------

- (void)handleContextualSendFiles:(NSArray*)files
{
  // If we're not logged in, store files and open view when we're ready.
  if ([_me_manager connection_status] != gap_user_status_online)
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
  if ([_me_manager connection_status] != gap_user_status_online)
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
  [_sent_sound play];
  return [_link_manager createLinkWithFiles:files withMessage:message forScreenshot:screenshot];
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
  NSArray* transaction_list = [_transaction_manager latestTransactionPerUser];
  NSArray* link_list = [_link_manager reversedLinkList];
  _main_view_controller =
    [[InfinitMainViewController alloc] initWithDelegate:self
                                     andTransactionList:transaction_list
                                            andLinkList:link_list
                                          forPeopleView:YES];
  [self openOrChangeViewController:_main_view_controller];
}

- (void)showLinks
{
  if ([IAFunctions osxVersion] != INFINIT_OS_X_VERSION_10_7)
    [_desktop_notifier clearAllNotifications];
  NSArray* transaction_list = [_transaction_manager latestTransactionPerUser];
  NSArray* link_list = [_link_manager reversedLinkList];
  _main_view_controller =
    [[InfinitMainViewController alloc] initWithDelegate:self
                                     andTransactionList:transaction_list
                                            andLinkList:link_list
                                          forPeopleView:NO];
  [self openOrChangeViewController:_main_view_controller];
}

- (void)showLoginView
{
  [self showLoginViewForMode:INFINIT_LOGIN_VIEW_REGISTER];
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
    [self showLoginViewForMode:INFINIT_LOGIN_VIEW_NOT_LOGGED_IN];
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
  if ([IAFunctions osxVersion] < INFINIT_OS_X_VERSION_10_10)
    [_status_bar_icon setHighlighted:NO];
  else
    _status_item.open = NO;
}

- (void)closeNotificationWindowWithoutLosingFocus
{
  if ([IAFunctions osxVersion] != INFINIT_OS_X_VERSION_10_7)
    [_desktop_notifier clearAllNotifications];
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
  if ([IAFunctions osxVersion] < INFINIT_OS_X_VERSION_10_10)
  {
    [_status_bar_icon setLoggingIn:YES];
  }
  if (_current_view_controller == _not_logged_view_controller)
    [_not_logged_view_controller setMode:INFINIT_LOGGING_IN];

  [_network_manager checkProxySettings];
  
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

  [[InfinitFeatureManager sharedInstance] fetchFeatures];
  // Instantiate screenshot manager after we've got the features as we're AB testing the first
  // screenshot modal.
  if (_screenshot_manager == nil)
    _screenshot_manager = [[InfinitScreenshotManager alloc] initWithDelegate:self];

  if ([[[IAUserPrefs sharedInstance] prefsForKey:@"updated"] isEqualToString:@"1"])
  {
    [[IAUserPrefs sharedInstance] setPref:@"0" forKey:@"updated"];
    [_desktop_notifier desktopNotificationForApplicationUpdated];
  }
  
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

  
  // XXX We must find a better way to manage fetching of history per user
  [_transaction_manager getHistory];
  [_link_manager getHistory];

  [[IACrashReportManager sharedInstance] sendExistingCrashReports];
  
  [[IAGapState instance] startPolling];

  [self updateStatusBarIcon];
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

- (void)loginCallback:(IAGapOperationResult*)result
{
  _logging_in = NO;
  if ([IAFunctions osxVersion] < INFINIT_OS_X_VERSION_10_10)
  {
    [_status_bar_icon setLoggingIn:NO];
  }
  if (result.success)
  {
    [self onSuccessfulLogin];
    [_delegate mainControllerWantsBackgroundUpdateChecks:self];
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
                 NSLocalizedString(@"You need to confirm your email, check your inbox.", nil)];
        break;

      case gap_meta_down_with_message:
        error = [NSString stringWithFormat:@"%@",
                 NSLocalizedString(@"Infinit is currently unavailable.",
                                   @"infinit is currently unavailable")];
        // XXX display actual Meta message
        break;

      case gap_trophonius_unreachable:
        if (_new_credentials)
        {
          error = [NSString stringWithFormat:@"%@",
                   NSLocalizedString(@"Unable to contact our servers, contact support.",
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
        error = [NSString stringWithFormat:@"%@.",
                 NSLocalizedString(@"Unknown login error", @"unknown login error")];
        break;
    }
    
    
    if (_login_view_controller == nil)
    {
      _login_view_controller =
        [[InfinitLoginViewController alloc] initWithDelegate:self
                                                    withMode:INFINIT_LOGIN_VIEW_NOT_LOGGED_IN_WITH_CREDENTIALS];
    }
    else
    {
      _login_view_controller.mode = INFINIT_LOGIN_VIEW_NOT_LOGGED_IN_WITH_CREDENTIALS;
    }
    
    NSString* username = [[IAUserPrefs sharedInstance] prefsForKey:@"user:email"];
    NSString* password = [self getPasswordForUsername:username];
    
    if (password == nil)
      password = @"";
    
    if (_current_view_controller != _login_view_controller)
      [self showLoginViewForMode:INFINIT_LOGIN_VIEW_NOT_LOGGED_IN_WITH_CREDENTIALS];
    
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
    free(pwd_ptr);
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
  [self showLoginViewForMode:INFINIT_LOGIN_VIEW_NOT_LOGGED_IN];
}

- (void)logoutAndShowLoginCallback:(IAGapOperationResult*)result
{
  _settings_window = nil;
  if (result.success)
  {
    if ([IAFunctions osxVersion] < INFINIT_OS_X_VERSION_10_10)
    {
      [_status_bar_icon setNumberOfItems:0];
    }
    else
    {
      _status_item.number = 0;
    }
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
  [_settings_window close];
  [self closeNotificationWindow];
  [self updateStatusBarIcon];
  [_network_manager checkProxySettings];
  [[IAGapState instance] logout:@selector(logoutAndShowLoginCallback:) onObject:self];
}

- (void)handleQuit
{
  _stay_awake_manager = nil;
  _network_manager = nil;
  _screenshot_manager = nil;

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
  [[IAGapState instance] freeGap];
  [_delegate terminateApplication:self];
}

- (BOOL)canUpdate
{
  if (!_logging_in && ![_transaction_manager hasTransferringTransaction] &&
      ![_link_manager hasTransferringLink] && _current_view_controller == nil)
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

- (void)updateStatusBarIcon
{
  BOOL transferring =
    [_transaction_manager hasTransferringTransaction] || [_link_manager hasTransferringLink];
  if ([IAFunctions osxVersion] < INFINIT_OS_X_VERSION_10_10)
  {
    [_status_bar_icon setTransferring:transferring];
    [_status_bar_icon setNumberOfItems:[_transaction_manager transactionsNeedingAccept]];
    [_status_bar_icon setFire:[_transaction_manager haveUnreadConversations]];
  }
  else
  {
    _status_item.transferring = transferring;
    _status_item.number = [_transaction_manager transactionsNeedingAccept];
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

//- Onboarding -------------------------------------------------------------------------------------

- (void)startOnboarding
{
  _onboard_controller = [[InfinitOnboardingController alloc] initForSendOnboardingWithDelegate:self];
}

- (IATransaction*)receiveOnboardingTransaction:(IAViewController*)sender;
{
  return _onboard_controller.receive_transaction;
}

- (IATransaction*)sendOnboardingTransaction:(IAViewController*)sender
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
  if ([_me_manager connection_status] != gap_user_status_online)
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
  IATransaction* transaction = [_transaction_manager transactionWithId:transaction_id];
  if (transaction == nil)
    return;
  
  [self showConversationViewForUser:transaction.other_user];
  [_transaction_manager markTransactionAsRead:transaction];
}

- (void)desktopNotifier:(IADesktopNotifier*)sender
hadAcceptTransaction:(NSNumber*)transaction_id
{
  IATransaction* transaction = [_transaction_manager transactionWithId:transaction_id];
  if (transaction == nil)
    return;
  [_transaction_manager acceptTransaction:transaction];
}

- (void)desktopNotifier:(IADesktopNotifier*)sender
hadClickNotificationForLinkId:(NSNumber*)transaction_id
{
  [self showLinks];
}

- (void)desktopNotifierHadClickApplicationUpdatedNotification:(IADesktopNotifier*)sender
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

- (NSArray*)sendController:(IAGeneralSendController*)sender
            wantsSendFiles:(NSArray*)files
                   toUsers:(NSArray*)users
               withMessage:(NSString*)message
{
  return [_transaction_manager sendFiles:files
                                 toUsers:users
                             withMessage:message];
}

- (NSNumber*)sendController:(IAGeneralSendController*)sender
            wantsCreateLink:(NSArray*)files
                withMessage:(NSString*)message
{
  [_sent_sound play];
  return [_link_manager createLinkWithFiles:files withMessage:message forScreenshot:NO];
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

- (void)sendControllerGotDropOnFavourite:(IAGeneralSendController*)sender
{
  if ([_onboard_controller inSendOnboarding])
    _onboard_controller.state = INFINIT_ONBOARDING_SEND_FILE_SENDING;
}

- (NSArray*)sendControllerWantsFriendsByLastInteraction:(IAGeneralSendController*)sender
{
  NSMutableArray* res = [NSMutableArray array];
  for (IATransaction* transaction in [_transaction_manager latestTransactionPerUser])
  {
    [res addObject:transaction.other_user];
  }
  for (IAUser* user in [IAUserManager favouritesList])
  {
    if (![res containsObject:user])
      [res addObject:user];
  }
  for (IAUser* user in [IAUserManager swaggerList])
  {
    if (![res containsObject:user])
      [res addObject:user];
  }
  return res;
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
  [paste_board setString:link.url_link forType:NSStringPboardType];
  if (notify)
  {
    [self closeNotificationWindow];
    [_desktop_notifier desktopNotificationForLinkCopied:link];
  }
}

- (void)linkManager:(InfinitLinkManager*)sender
hadStatusChangeForLink:(InfinitLinkTransaction*)link
{
  if ([_current_view_controller isKindOfClass:InfinitMainViewController.class])
    [_main_view_controller linkUpdated:link];
  [self updateStatusBarIcon];
  [_desktop_notifier desktopNotificationForLink:link];
  if (link.status == gap_transaction_transferring)
    [self _copyLinkToClipboard:link withNotification:NO];
}

- (void)linkManager:(InfinitLinkManager*)sender
         hasNewLink:(InfinitLinkTransaction*)link
{
  if ([_current_view_controller isKindOfClass:InfinitMainViewController.class])
    [_main_view_controller linkAdded:link];
  [self updateStatusBarIcon];
  [_desktop_notifier desktopNotificationForLink:link];
  if (link.status == gap_transaction_transferring)
    [self _copyLinkToClipboard:link withNotification:NO];
}

- (void)copyLinkToClipboard:(InfinitLinkTransaction*)link
{
  [self _copyLinkToClipboard:link withNotification:YES];
}

- (void)cancelLink:(InfinitLinkTransaction*)link
{
  [_link_manager cancelLink:link];
}

- (void)deleteLink:(InfinitLinkTransaction*)link
{
  [_link_manager deleteLink:link];
}

- (void)linkManager:(InfinitLinkManager*)sender
hadDataUpdatedForLink:(InfinitLinkTransaction*)link
{
  if ([_current_view_controller isKindOfClass:InfinitMainViewController.class])
    [_main_view_controller linkUpdated:link];
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
  if ([IAFunctions osxVersion] < INFINIT_OS_X_VERSION_10_10)
    [_status_bar_icon setConnected:gap_user_status_online];
  else
    _status_item.connected = gap_user_status_online;
  [self onSuccessfulLogin];
  [_delegate mainControllerWantsBackgroundUpdateChecks:self];
  [self performSelector:@selector(showNotifications) withObject:nil afterDelay:0.5];
}

- (void)alreadyLoggedIn:(InfinitLoginViewController*)sender
{
  [self updateStatusBarIcon];
  if ([IAFunctions osxVersion] < INFINIT_OS_X_VERSION_10_10)
    [_status_bar_icon setConnected:gap_user_status_online];
  else
    _status_item.connected = gap_user_status_online;
  [_delegate mainControllerWantsBackgroundUpdateChecks:self];
  [self performSelector:@selector(showNotifications) withObject:nil afterDelay:0.5];
}

//- Main View Protocol -----------------------------------------------------------------------------

- (NSArray*)latestTransactionsByUser:(InfinitMainViewController*)sender
{
  return [_transaction_manager latestTransactionPerUser];
}

- (NSArray*)linkHistory:(InfinitMainViewController*)sender
{
  return [_link_manager reversedLinkList];
}

- (NSUInteger)runningTransactionsForUser:(IAUser*)user
{
  return [_transaction_manager activeTransactionsForUser:user];
}

- (NSUInteger)notDoneTransactionsForUser:(IAUser*)user
{
  return [_transaction_manager notDoneTransactionsForUser:user];
}

- (NSUInteger)unreadTransactionsForUser:(IAUser*)user
{
  return  [_transaction_manager unreadAndNeedingActionTransactionsForUser:user];
}

- (CGFloat)totalProgressForUser:(IAUser*)user
{
  return [_transaction_manager transactionsProgressForUser:user];
}

- (BOOL)transferringTransactionsForUser:(IAUser*)user
{
  return [_transaction_manager transferringTransactionsForUser:user];
}

- (void)userGotClicked:(IAUser*)user
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

- (void)markTransactionRead:(IATransaction*)transaction
{
  [_transaction_manager markTransactionAsRead:transaction];
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

- (gap_UserStatus)currentSelfStatus:(InfinitMainViewController*)status
{
  return [_me_manager connection_status];
}

//- Me Manager Protocol ----------------------------------------------------------------------------

- (void)meManager:(IAMeManager*)sender
hadConnectionStateChange:(gap_UserStatus)status
{
  if ([IAFunctions osxVersion] < INFINIT_OS_X_VERSION_10_10)
    [_status_bar_icon setConnected:status];
  else
    _status_item.connected = status;

  if ([_current_view_controller isKindOfClass:IANoConnectionViewController.class] &&
      status == gap_user_status_online)
  {
    [self showNotifications];
  }
  if (status == gap_user_status_online)
  {
    [IAUserManager resyncUserStatuses];

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
  else if (status == gap_user_status_offline)
  {
    [IAUserManager setAllUsersOffline];
  }

  if (_current_view_controller != nil)
    [_current_view_controller selfStatusChanged:status];
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

//- Settings Protocol ------------------------------------------------------------------------------

- (void)openPreferences
{
  if (![[IAGapState instance] logged_in])
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

- (BOOL)uploadsScreenshots:(InfinitSettingsWindow*)sender
{
  return _screenshot_manager.watch;
}

- (void)setUploadsScreenshots:(InfinitSettingsWindow*)sender
                           to:(BOOL)value
{
  _screenshot_manager.watch = value;
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
    if (![_current_view_controller isKindOfClass:InfinitSendViewController.class])
      _general_send_controller = [[IAGeneralSendController alloc] initWithDelegate:self];
    [_general_send_controller openWithFiles:files forUser:nil];
  }
}

- (void)statusBarIconLinkDrop:(IAStatusBarIcon*)sender
                    withFiles:(NSArray*)files
{
  [_link_manager createLinkWithFiles:files withMessage:@"" forScreenshot:NO];
  [_sent_sound play];
}

- (void)statusBarIconDragEntered:(id)sender
{
  if (![[IAGapState instance] logged_in] ||
      [_me_manager connection_status] != gap_user_status_online ||
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

//- Screenshot Manager Protocol --------------------------------------------------------------------

- (void)screenshotManager:(InfinitScreenshotManager*)sender
            gotScreenshot:(NSString*)path
{
  if (![[IAGapState instance] logged_in] || [_me_manager connection_status] != gap_user_status_online)
    return;
  [_link_manager createLinkWithFiles:@[path] withMessage:@"" forScreenshot:YES];
}

//- Stay Awake Manager Protocol --------------------------------------------------------------------

- (BOOL)stayAwakeManagerWantsActiveTransactions:(InfinitStayAwakeManager*)sender
{
  return ([_transaction_manager hasTransferringTransaction] || [_link_manager hasTransferringLink]);
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

- (void)markTransactionReadIfNeeded:(IATransaction*)transaction
{
  if ([self notificationViewOpen])
  {
    if ([_transaction_manager notDoneTransactionsForUser:transaction.other_user] == 0 &&
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
  {
    [_desktop_notifier transactionUpdated:transaction];
    [_desktop_notifier desktopNotificationForTransaction:transaction];
  }
  
  if (_onboard_controller.state == INFINIT_ONBOARDING_SEND_FILE_SENDING &&
      _onboard_controller.send_transaction == transaction &&
      (transaction.is_done || transaction.view_mode == TRANSACTION_VIEW_CLOUD_BUFFERED))
  {
    _onboard_controller.state = INFINIT_ONBOARDING_SEND_FILE_SENT;
  }
  
  if (_current_view_controller == nil)
    return;
  
  [_current_view_controller transactionUpdated:transaction];
}

- (void)transactionManager:(IATransactionManager*)sender
    hadTransactionAccepted:(IATransaction*)transaction
{
  if ([IAFunctions osxVersion] != INFINIT_OS_X_VERSION_10_7)
    [_desktop_notifier desktopNotificationForTransactionAccepted:transaction];
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

- (void)transactionManagerHadFileSent:(IATransactionManager*)sender
{
  [_sent_sound play];
}

- (void)transactionManagerWantsEnsureDownloadDestination:(IATransactionManager*)sender
{
  [[InfinitDownloadDestinationManager sharedInstance] ensureDownloadDestination];
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

- (void)userManager:(IAUserManager*)sender
     hadUserDeleted:(IAUser*)user
{
  [_transaction_manager updateTransactionsForUser:user];
  if (_current_view_controller == nil)
    return;
  [_current_view_controller userDeleted:user];
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
