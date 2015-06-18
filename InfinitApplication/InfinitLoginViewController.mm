//
//  InfinitLoginViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 31/10/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "InfinitLoginViewController.h"

#import "IAUserPrefs.h"
#import "InfinitFacebookWindowController.h"
#import "InfinitKeychain.h"
#import "InfinitLoginButton.h"
#import "InfinitLoginView.h"
#import "InfinitMetricsManager.h"
#import "InfinitNetworkManager.h"

#import <Gap/InfinitColor.h>
#import <Gap/InfinitStateManager.h>
#import <Gap/InfinitStateResult.h>
#import <Gap/NSString+email.h>

#import <version.hh>

#define INFINIT_HELP_URL @"https://infinit.io/faq?utm_source=app&utm_medium=mac&utm_campaign=help"
#define INFINIT_FORGOT_PASSWORD_URL @"https://infinit.io/forgot_password?utm_source=app&utm_medium=mac&utm_campaign=forgot_password"

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("OSX.LoginViewController");

@interface InfinitLoginViewController () <InfinitFacebookWindowProtocol>

@property (nonatomic, weak) IBOutlet InfinitLoginButton* action_button;
@property (nonatomic, weak) IBOutlet InfinitLoginButton* facebook_button;
@property (nonatomic, strong) InfinitFacebookWindowController* facebook_window;
@property (nonatomic, weak) IBOutlet InfinitLoginView* main_view;
@property (nonatomic, weak) IBOutlet IAHoverButton* close_button;
@property (nonatomic, weak) IBOutlet NSTextField* email_address;
@property (nonatomic, weak) IBOutlet NSTextField* error_message;
@property (nonatomic, weak) IBOutlet NSTextField* fullname;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* fullname_height;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* or_bottom_dh;
@property (nonatomic, weak) IBOutlet IAHoverButton* help_button;
@property (nonatomic, weak) IBOutlet IAHoverButton* problem_button;
@property (nonatomic, weak) IBOutlet IAHoverButton* forgot_password_button;
@property (nonatomic, weak) IBOutlet NSButton* register_tab;
@property (nonatomic, weak) IBOutlet NSButton* login_tab;
@property (nonatomic, weak) IBOutlet NSTextField* password;
@property (nonatomic, readwrite) BOOL running;
@property (nonatomic, readwrite) BOOL facebook_connect;
@property (nonatomic, weak) IBOutlet NSProgressIndicator* spinner;
@property (nonatomic, weak) IBOutlet NSTextField* version;

@end

@implementation InfinitLoginViewController
{
@private
  id<InfinitLoginViewControllerProtocol> _delegate;
  NSDictionary* _error_attrs;
  
  NSAttributedString* _version_str;
  NSDictionary* _link_attrs;
  NSDictionary* _link_hover_attrs;
  NSDictionary* _tab_light_attrs;
  NSDictionary* _tab_dark_attrs;
}

@dynamic main_view;

#pragma mark - Init

- (id)initWithDelegate:(id<InfinitLoginViewControllerProtocol>)delegate
              withMode:(InfinitLoginViewMode)mode
{
  if (self = [super initWithNibName:self.className bundle:nil])
  {
    _delegate = delegate;
    _mode = mode;
    NSMutableParagraphStyle* error_para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    NSFont* error_font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica"
                                                                    traits:NSUnboldFontMask
                                                                    weight:5
                                                                      size:12.0];
    _error_attrs = [IAFunctions textStyleWithFont:error_font
                                   paragraphStyle:error_para
                                           colour:IA_RGB_COLOUR(222.0, 104.0, 81.0)
                                           shadow:nil];

    NSFont* version_font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica"
                                                                      traits:NSUnboldFontMask
                                                                      weight:2
                                                                        size:10.0];
    NSDictionary* version_style = [IAFunctions textStyleWithFont:version_font
                                                  paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                                          colour:IA_GREY_COLOUR(206.0)
                                                          shadow:nil];

    _version_str =  [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"v%@",
                                                [NSString stringWithUTF8String:INFINIT_VERSION]]
                                                    attributes:version_style];

    NSFont* link_font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica"
                                                                   traits:NSUnboldFontMask
                                                                   weight:0
                                                                     size:12.0];
    NSMutableParagraphStyle* right_para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    right_para.alignment = NSRightTextAlignment;
    _link_attrs = [IAFunctions textStyleWithFont:link_font
                                  paragraphStyle:right_para
                                          colour:IA_RGB_COLOUR(103.0, 181.0, 214.0)
                                          shadow:nil];
    _link_hover_attrs = [IAFunctions textStyleWithFont:link_font
                                        paragraphStyle:right_para
                                                colour:IA_RGB_COLOUR(11.0, 117.0, 162)
                                                shadow:nil];
    NSFont* tab_font = [NSFont fontWithName:@"Source Sans Pro Bold" size:12.0f];
    NSMutableParagraphStyle* center_para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    center_para.alignment = NSCenterTextAlignment;
    _tab_light_attrs = [IAFunctions textStyleWithFont:tab_font
                                       paragraphStyle:center_para
                                               colour:[InfinitColor colorWithGray:186]
                                               shadow:nil];
    _tab_dark_attrs = [IAFunctions textStyleWithFont:tab_font
                                      paragraphStyle:center_para
                                              colour:[InfinitColor colorWithRed:81 green:81 blue:73]
                                              shadow:nil];
    _facebook_connect = NO;
  }
  return self;
}

- (void)dealloc
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)setupButtonsForMode:(InfinitLoginViewMode)mode
{
  if (mode == InfinitLoginViewModeRegister)
  {
    self.action_button.text = NSLocalizedString(@"SIGN UP", nil);
    self.main_view.selector = InfinitLoginSelectorLeft;
    self.facebook_button.text = NSLocalizedString(@"SIGN UP WITH FACEBOOK", nil);
  }
  else
  {
    self.main_view.selector = InfinitLoginSelectorRight;
    self.action_button.text = NSLocalizedString(@"LOGIN", nil);
    self.facebook_button.text = NSLocalizedString(@"SIGN IN WITH FACEBOOK", nil);
  }
  [self tabButtonsForMode:mode];
}

- (void)tabButtonsForMode:(InfinitLoginViewMode)mode
{
  NSDictionary* register_attrs = nil;
  NSDictionary* login_attrs = nil;
  if (mode == InfinitLoginViewModeRegister)
  {
    register_attrs = _tab_dark_attrs;
    login_attrs = _tab_light_attrs;
  }
  else
  {
    register_attrs = _tab_light_attrs;
    login_attrs = _tab_dark_attrs;
  }
  self.register_tab.attributedTitle =
  [[NSAttributedString alloc] initWithString:NSLocalizedString(@"REGISTER", nil)
                                  attributes:register_attrs];
  self.login_tab.attributedTitle =
  [[NSAttributedString alloc] initWithString:NSLocalizedString(@"LOGIN", nil)
                                  attributes:login_attrs];
}

- (void)setFocus
{
  if (self.mode == InfinitLoginViewModeRegister)
    [self.view.window makeFirstResponder:self.fullname];
  else
    [self.view.window makeFirstResponder:self.email_address];
}

- (void)awakeFromNib
{
  _running = NO;
  self.close_button.hand_cursor = NO;
  self.close_button.hover_image = [IAFunctions imageNamed:@"login-icon-close-hover"];
  [self configureForMode];
  
  self.version.attributedStringValue = _version_str;
  [self.action_button.cell setImageDimsWhenDisabled:NO];
  self.help_button.normal_attrs = _link_attrs;
  self.help_button.hover_attrs = _link_hover_attrs;
  self.problem_button.normal_attrs = _link_attrs;
  self.problem_button.hover_attrs = _link_hover_attrs;
  self.facebook_button.color = [InfinitColor colorWithRed:79 green:108 blue:214];
  self.action_button.color = [InfinitColor colorWithRed:255 green:70 blue:75];
  self.help_button.attributedTitle =
    [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Help", nil)
                                    attributes:_link_attrs];
}

- (void)loadView
{
  ELLE_TRACE("%s: loadview with mode: %d", self.description.UTF8String, _mode);
  [super loadView];
  if (self.mode != InfinitLoginViewModeRegister)
  {
    self.fullname.alphaValue = 0.0;
    self.fullname.hidden = YES;
    self.fullname_height.constant = 0.0f;
    self.or_bottom_dh.constant = 0.0f;
    self.content_height_constraint.constant = 405.0f;
    [self.view.window makeFirstResponder:self.email_address];
  }
  [self setupButtonsForMode:self.mode];
}

#pragma mark - General

- (void)configureForMode
{
  [self.spinner stopAnimation:nil];
  self.action_button.enabled = YES;
  self.email_address.enabled = YES;
  self.password.enabled = YES;
  switch (self.mode)
  {
    case InfinitLoginViewModeRegister:
      self.fullname.enabled = YES;
      self.fullname.hidden = NO;
      self.error_message.stringValue = @"";
      self.error_message.hidden = YES;
      self.main_view.selector = InfinitLoginSelectorLeft;
      self.forgot_password_button.hidden = YES;
      break;

    case InfinitLoginViewModeLogin:
      self.fullname.enabled = NO;
      self.fullname.hidden = YES;
      self.error_message.stringValue = @"";
      self.error_message.hidden = YES;
      self.main_view.selector = InfinitLoginSelectorRight;
      self.forgot_password_button.hidden = NO;
      break;
      
    case InfinitLoginViewModeLoginCredentials:
      self.fullname.enabled = NO;
      self.fullname.hidden = YES;
      self.main_view.selector = InfinitLoginSelectorRight;
      self.forgot_password_button.hidden = NO;
      break;
      
    default:
      ELLE_WARN("%s: unknown login view mode", self.description.UTF8String);
      break;
  }
  [self tabButtonsForMode:self.mode];
  [self setupButtonsForMode:self.mode];
}

- (void)closeLoginView
{
  [_delegate loginViewWantsClose:self];
}

- (void)setRunning:(BOOL)running
{
  _running = running;
  if (_running)
    self.action_button.enabled = NO;
  else
    self.action_button.enabled = YES;
}

- (void)setMode:(InfinitLoginViewMode)mode
{
  InfinitLoginViewMode last_mode = _mode;
  _mode = mode;
  [self configureForMode];
  if (_mode == last_mode)
    return;
  if (_mode == InfinitLoginViewModeRegister)
  {
    self.fullname_height.constant = 0.0f;
    self.or_bottom_dh.constant = 0.0f;
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
    {
      context.duration = 0.15;
      self.fullname.hidden = NO;
      self.fullname_height.animator.constant = 35.0f;
      self.or_bottom_dh.animator.constant = 10.0f;
      [self.fullname.animator setAlphaValue:1.0];
      self.content_height_constraint.animator.constant = 450.0f;;
    }
                        completionHandler:^
     {
       self.fullname.hidden = NO;
       self.fullname.alphaValue = 1.0;
       self.fullname_height.constant = 35.0f;
       self.or_bottom_dh.constant = 10.0f;
       self.content_height_constraint.constant = 450.0f;
       [self.view.window makeFirstResponder:self.fullname];
     }];
  }
  else if (last_mode == InfinitLoginViewModeRegister)
  {
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
     {
       context.duration = 0.15;
       [self.fullname.animator setAlphaValue:0.0];
       self.fullname_height.animator.constant = 0.0f;
       self.or_bottom_dh.animator.constant = 0.0f;
       self.content_height_constraint.animator.constant = 405.0f;
     }
                        completionHandler:^
     {
       self.fullname.alphaValue = 0.0;
       self.fullname_height.constant = 0.0f;
       self.or_bottom_dh.constant = 0.0f;
       self.fullname.hidden = YES;
       self.content_height_constraint.constant = 405.0f;
       [self.view.window makeFirstResponder:self.email_address];
     }];
  }
}

- (void)showWithError:(NSString*)error
             username:(NSString*)username
          andPassword:(NSString*)password
{
  self.mode = InfinitLoginViewModeLoginCredentials;
  self.running = NO;
  [self.spinner stopAnimation:nil];
  if (username.length > 0 && password.length > 0)
  {
    self.email_address.stringValue = username;
    self.password.stringValue = password;
    password = @"";
    password = nil;
  }
  [self showError:error];
  [self.view.window makeFirstResponder:self.email_address];
}

- (void)showError:(NSString*)error
{
  [self.spinner stopAnimation:nil];
  self.error_message.attributedStringValue =
    [[NSAttributedString alloc] initWithString:error attributes:_error_attrs];
  self.version.hidden = NO;
  self.error_message.hidden = NO;
}

- (void)hideError
{
  self.version.hidden = YES;
  self.error_message.hidden = YES;
}

#pragma mark - User Interaction

- (BOOL)loginInputsGood
{
  self.email_address.stringValue =
    [self.email_address.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  if (!self.email_address.stringValue.infinit_isEmail)
  {
    NSString* error = NSLocalizedString(@"Please enter a valid email address.", nil);
    [self showError:error];
    self.running = NO;
    self.fullname.enabled = YES;
    self.email_address.enabled = YES;
    self.password.enabled = YES;
    [self.view.window makeFirstResponder:self.email_address];
    return NO;
  }
  else if (self.password.stringValue.length == 0)
  {
    NSString* error = NSLocalizedString(@"Please enter your password.", nil);
    [self showError:error];
    self.running = NO;
    self.fullname.enabled = YES;
    self.email_address.enabled = YES;
    self.password.enabled = YES;
    [self.view.window makeFirstResponder:self.password];
    return NO;
  }
  return YES;
}

- (BOOL)registerInputsGood
{
  self.email_address.stringValue =
    [self.email_address.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  if (self.fullname.stringValue.length < 3)
  {
    NSString* error = NSLocalizedString(@"Please enter a name with at least 3 characters", nil);
    [self showError:error];
    self.fullname.enabled = YES;
    self.email_address.enabled = YES;
    self.password.enabled = YES;
    self.running = NO;
    [self.view.window makeFirstResponder:self.fullname];
    return NO;
  }
  return [self loginInputsGood];
}

- (void)registerCallback:(InfinitStateResult*)result
{
  self.running = NO;
  [self.spinner stopAnimation:nil];
  if (result.success)
  {
    ELLE_LOG("%s: Successfully registered as: %s",
             self.description.UTF8String, self.email_address.stringValue.UTF8String);
    [self onSuccessfulLogin];
    [_delegate loginViewDoneRegister:self];
  }
  else
  {
    NSString* error = [self _errorFromStatus:result.status];
    if (result.status == gap_already_logged_in)
    {
      [_delegate loginViewDoneRegister:self];
      return;
    }
    [self showError:error];
  }
  self.action_button.enabled = YES;
  self.fullname.enabled = YES;
  self.email_address.enabled = YES;
  self.password.enabled = YES;
}

- (void)loginCallback:(InfinitStateResult*)result
{
  self.running = NO;
  [self.spinner stopAnimation:nil];
  if (result.success)
  {
    ELLE_LOG("%s: Successfully logged in as: %s",
             self.description.UTF8String, self.email_address.stringValue.UTF8String);
    [self onSuccessfulLogin];
    [_delegate loginViewDoneLogin:self];
  }
  else
  {
    NSString* error = [self _errorFromStatus:result.status];
    if (result.status == gap_already_logged_in)
    {
      [_delegate loginViewDoneLogin:self];
      return;
    }
    [self showError:error];
  }
  self.action_button.enabled = YES;
  self.fullname.enabled = YES;
  self.email_address.enabled = YES;
  self.password.enabled = YES;
}

- (void)onSuccessfulLogin
{
  if (!self.facebook_connect)
  {
    InfinitKeychain* manager = [InfinitKeychain sharedInstance];
    NSString* account = self.email_address.stringValue;
    NSString* password = self.password.stringValue;
    if ([manager credentialsForAccountInKeychain:self.email_address.stringValue])
      [manager updatePassword:password forAccount:account];
    else
      [manager addPassword:password forAccount:account];
    password = @"";
    self.password.stringValue = @"";
    self.email_address.stringValue = @"";
    [[IAUserPrefs sharedInstance] setPref:account forKey:@"user:email"];
    [[IAUserPrefs sharedInstance] setPref:@"0" forKey:@"facebook_connect"];
  }
  else
  {
    [[IAUserPrefs sharedInstance] setPref:@"1" forKey:@"facebook_connect"];
  }
}

- (IBAction)actionButtonClicked:(NSButton*)sender
{
  if (_running)
    return;

  self.facebook_connect = NO;
  [self hideError];

  self.running = YES;
  [self.spinner startAnimation:nil];
  self.action_button.enabled = NO;
  self.fullname.stringValue = self.fullname.stringValue;
  self.fullname.enabled = NO;
  self.email_address.stringValue = self.email_address.stringValue;
  self.email_address.enabled = NO;
  self.password.stringValue = self.password.stringValue;
  self.password.enabled = NO;

  if (_mode == InfinitLoginViewModeRegister)
  {
    if ([self registerInputsGood])
    {
      [self hideError];
      [[InfinitStateManager sharedInstance] registerFullname:self.fullname.stringValue
                                                       email:self.email_address.stringValue
                                                    password:self.password.stringValue
                                             performSelector:@selector(registerCallback:)
                                                    onObject:self];
    }
  }
  else
  {
    if ([self loginInputsGood])
    {
      [self hideError];
      [[InfinitStateManager sharedInstance] login:self.email_address.stringValue
                                         password:self.password.stringValue
                                  performSelector:@selector(loginCallback:)
                                         onObject:self];
    }
  }
}

- (IBAction)closeButtonClicked:(NSButton*)sender
{
  // Don't quit Infinit if we're logging in or registering
  if (_running)
    [_delegate loginViewWantsClose:self];
  else
    [_delegate loginViewWantsCloseAndQuit:self];
}

- (IBAction)onProblemClick:(NSButton*)sender
{
  [_delegate loginViewWantsReportProblem:self];
}

- (IBAction)loginTabClicked:(id)sender
{
  if (self.mode == InfinitLoginViewModeLogin || self.mode == InfinitLoginViewModeLoginCredentials ||
      _running)
  {
    return;
  }
  [self hideError];
  self.mode = InfinitLoginViewModeLogin;
  [InfinitMetricsManager sendMetric:INFINIT_METRIC_REGISTER_TO_LOGIN];
}

- (IBAction)registerTabClicked:(id)sender
{
  if (_running || self.mode == InfinitLoginViewModeRegister)
    return;
  [self hideError];
  self.mode = InfinitLoginViewModeRegister;
  [InfinitMetricsManager sendMetric:INFINIT_METRIC_LOGIN_TO_REGISTER];
}

- (IBAction)helpClicked:(IAHoverButton*)sender
{
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:INFINIT_HELP_URL]];
  [self closeLoginView];
}

- (IBAction)forgotPasswordClicked:(id)sender
{
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:INFINIT_FORGOT_PASSWORD_URL]];
  [self closeLoginView];
}

- (IBAction)facebookClicked:(id)sender
{
  self.facebook_button.enabled = NO;
  self.action_button.enabled = NO;
  self.facebook_connect = YES;
  self.facebook_window = [[InfinitFacebookWindowController alloc] initWithDelegate:self];
  [self.facebook_window showWindow:self];
}

#pragma mark - IAViewController

- (void)viewActive
{
  [self performSelector:@selector(setFocus) withObject:nil afterDelay:0.3];
}

- (BOOL)closeOnFocusLost
{
  if (_running)
    return YES;
  else
    return NO;
}

#pragma mark - Facebook Window Protocol

- (void)facebookWindow:(InfinitFacebookWindowController*)sender
              gotError:(NSString*)error
{
  self.facebook_button.enabled = YES;
  self.action_button.enabled = YES;
  NSAlert* alert =
    [NSAlert alertWithMessageText:NSLocalizedString(@"Unable to login with Facebook.", nil)
                    defaultButton:NSLocalizedString(@"OK", nil)
                  alternateButton:nil
                      otherButton:nil
        informativeTextWithFormat:NSLocalizedString(@"Ensure that you give Infinit permission to use your Facebook account.", nil)];
  [alert runModal];
}

- (void)facebookWindow:(InfinitFacebookWindowController*)sender
              gotToken:(NSString*)token
{
  [self gotFacebookAccess:token];
}

#pragma mark - Facebook Handling

- (void)gotFacebookAccess:(NSString*)token
{
  [self.spinner startAnimation:nil];
  [[InfinitStateManager sharedInstance] facebookConnect:token
                                           emailAddress:nil
                                        performSelector:@selector(facebookLoginRegisterCallback:)
                                               onObject:self];
}

- (void)facebookLoginRegisterCallback:(InfinitStateResult*)result
{
  [self.spinner stopAnimation:nil];
  self.facebook_button.enabled = YES;
  self.action_button.enabled = YES;
  if (result.success)
  {
    [self onSuccessfulLogin];
    [_delegate loginViewDoneRegister:self];
  }
  else
  {
    if (result.status == gap_email_already_registered)
      [self showError:NSLocalizedString(@"Login with your email address.", nil)];
  }
}

#pragma mark - Helpers

- (NSString*)_errorFromStatus:(gap_Status)status
{
  switch (status)
  {
    case gap_already_logged_in:
      return NSLocalizedString(@"You're already logged in.", nil);
    case gap_deprecated:
      return NSLocalizedString(@"Please update Infinit.", nil);
    case gap_email_already_registered:
      return NSLocalizedString(@"Email already registered.", nil);
    case gap_email_not_confirmed:
      return NSLocalizedString(@"Your email has not been confirmed.", nil);
    case gap_email_not_valid:
      return NSLocalizedString(@"Email not valid.", nil);
    case gap_email_password_dont_match:
      return NSLocalizedString(@"Login/Password don't match.", nil);
    case gap_fullname_not_valid:
      return NSLocalizedString(@"Fullname not valid.", nil);
    case gap_handle_already_registered:
      return NSLocalizedString(@"This handle has already been taken.", nil);
    case gap_handle_not_valid:
      return NSLocalizedString(@"Handle not valid", nil);
    case gap_meta_down_with_message:
      return NSLocalizedString(@"Our Server is down. Thanks for being patient.", nil);
    case gap_password_not_valid:
      return NSLocalizedString(@"Password not valid.", nil);

    default:
      return [NSString stringWithFormat:@"%@: %d", NSLocalizedString(@"Unknown login error", nil),
              status];
  }
}


@end
