//
//  InfinitLoginViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 31/10/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "InfinitLoginViewController.h"
#import "IAKeychainManager.h"

#import <Gap/IAGapState.h>
#import <version.hh>

#define INFINIT_HELP_URL "https://infinit.io/faq?utm_source=app&utm_medium=mac"
#define INFINIT_FORGOT_PASSWORD_URL "https://infinit.io/forgot_password?utm_source=app&utm_medium=mac"

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("OSX.LoginViewController");

@interface InfinitLoginViewController ()
@end

//- Login View -------------------------------------------------------------------------------------

@interface InfinitLoginView : IAMainView
@end

@implementation InfinitLoginView

- (BOOL)isOpaque
{
  return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
  [IA_GREY_COLOUR(248.0) set];
  NSRectFill(self.bounds);
}

@end

//- Login View Controller --------------------------------------------------------------------------

@implementation InfinitLoginViewController
{
@private
  id<InfinitLoginViewControllerProtocol> _delegate;
  NSDictionary* _error_attrs;
  BOOL _showing_error;
  
  NSAttributedString* _version_str;
  NSDictionary* _button_attrs;
  NSDictionary* _link_attrs;
  NSDictionary* _link_hover_attrs;
  NSDictionary* _link_right_attrs;
  NSDictionary* _link_right_hover_attrs;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithDelegate:(id<InfinitLoginViewControllerProtocol>)delegate
              withMode:(InfinitLoginViewMode)mode
{
  if (self = [super initWithNibName:[self className] bundle:nil])
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
    NSMutableParagraphStyle* version_para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    version_para.alignment = NSRightTextAlignment;
    NSDictionary* version_style = [IAFunctions textStyleWithFont:version_font
                                                  paragraphStyle:version_para
                                                          colour:IA_GREY_COLOUR(206.0)
                                                          shadow:nil];

    _version_str =  [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"v%@",
                                                [NSString stringWithUTF8String:INFINIT_VERSION]]
                                                    attributes:version_style];

    NSMutableParagraphStyle* style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    style.alignment = NSCenterTextAlignment;
    NSShadow* shadow = [IAFunctions shadowWithOffset:NSMakeSize(0.0, -1.0)
                                          blurRadius:1.0
                                              colour:[NSColor blackColor]];

    _button_attrs = [IAFunctions textStyleWithFont:[NSFont boldSystemFontOfSize:13.0]
                                    paragraphStyle:style
                                            colour:[NSColor whiteColor]
                                            shadow:shadow];

    NSFont* link_font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica"
                                                                   traits:NSUnboldFontMask
                                                                   weight:0
                                                                     size:12.0];
    _link_attrs = [IAFunctions textStyleWithFont:link_font
                                  paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                          colour:IA_RGB_COLOUR(103.0, 181.0, 214.0)
                                          shadow:nil];
    _link_hover_attrs = [IAFunctions textStyleWithFont:link_font
                                        paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                                colour:IA_RGB_COLOUR(11.0, 117.0, 162)
                                                shadow:nil];
    NSMutableParagraphStyle* link_right = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    link_right.alignment = NSRightTextAlignment;
    _link_right_attrs = [IAFunctions textStyleWithFont:link_font
                                        paragraphStyle:link_right
                                                colour:IA_RGB_COLOUR(103.0, 181.0, 214.0)
                                                shadow:nil];
    _link_right_hover_attrs = [IAFunctions textStyleWithFont:link_font
                                              paragraphStyle:link_right
                                                      colour:IA_RGB_COLOUR(11.0, 117.0, 162)
                                                      shadow:nil];
    _showing_error = NO;
  }
  return self;
}

- (void)dealloc
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (BOOL)closeOnFocusLost
{
  if (_running)
    return YES;
  else
    return NO;
}

- (void)setupButtonsForMode:(InfinitLoginViewMode)mode
{
  NSString* action_button_text;
  NSString* got_account_text;
  NSString* problem = NSLocalizedString(@"Problem?", nil);
  if (mode == INFINIT_LOGIN_VIEW_REGISTER)
  {
    action_button_text = NSLocalizedString(@"REGISTER", nil);
    got_account_text = NSLocalizedString(@"Already have an account?", nil);
    self.action_text.stringValue = NSLocalizedString(@"CREATE AN ACCOUNT", nil);
  }
  else
  {
    action_button_text = NSLocalizedString(@"LOGIN", nil);
    got_account_text = NSLocalizedString(@"Need an account?", nil);
    self.action_text.stringValue = NSLocalizedString(@"LOGIN", nil);
  }
  self.action_button.attributedTitle = [[NSAttributedString alloc] initWithString:action_button_text
                                                                       attributes:_button_attrs];
  self.got_account.attributedTitle = [[NSAttributedString alloc] initWithString:got_account_text
                                                                     attributes:_link_attrs];
  self.problem_button.attributedTitle = [[NSAttributedString alloc] initWithString:problem
                                                                        attributes:_link_attrs];
}

- (void)viewActive
{
  [self performSelector:@selector(setFocus) withObject:nil afterDelay:0.3];
}

- (void)setFocus
{
  if (_mode == INFINIT_LOGIN_VIEW_REGISTER)
    [self.view.window makeFirstResponder:self.fullname];
  else
    [self.view.window makeFirstResponder:self.email_address];
}

- (void)awakeFromNib
{
  _running = NO;
  self.close_button.hand_cursor = NO;
  [self.close_button setHoverImage:[IAFunctions imageNamed:@"login-icon-close-hover"]];
  [self configureForMode];
  
  self.version.attributedStringValue = _version_str;
  self.action_button.hand_cursor = YES;
  self.got_account.normal_attrs = _link_attrs;
  self.got_account.hover_attrs = _link_hover_attrs;
  self.problem_button.normal_attrs = _link_attrs;
  self.problem_button.hover_attrs = _link_hover_attrs;
  self.help_button.normal_attrs = _link_right_attrs;
  self.help_button.hover_attrs = _link_right_hover_attrs;
  [self.problem_button setToolTip:NSLocalizedString(@"Click to tell us!", nil)];
}

- (void)loadView
{
  ELLE_TRACE("%s: loadview with mode: %d", self.description.UTF8String, _mode);
  [super loadView];
  if (_mode != INFINIT_LOGIN_VIEW_REGISTER)
  {
     self.fullname.alphaValue = 0.0;
     self.fullname.hidden = YES;
     self.content_height_constraint.constant = 333.0;
     [self.view.window makeFirstResponder:self.email_address];
  }
}

//- General ----------------------------------------------------------------------------------------

- (void)configureForMode
{
  [self.spinner stopAnimation:nil];
  self.got_account.hidden = NO;
  self.action_button.enabled = YES;
  self.email_address.enabled = YES;
  self.password.enabled = YES;
  NSString* help_str;
  switch (_mode)
  {
    case INFINIT_LOGIN_VIEW_REGISTER:
      self.fullname.enabled = YES;
      self.fullname.hidden = NO;
      self.error_message.stringValue = @"";
      self.error_message.hidden = YES;
      help_str = NSLocalizedString(@"Help", nil);
      break;

    case INFINIT_LOGIN_VIEW_NOT_LOGGED_IN:
      self.fullname.enabled = NO;
      self.fullname.hidden = YES;
      self.error_message.stringValue = @"";
      self.error_message.hidden = YES;
      help_str = NSLocalizedString(@"Forgot password?", nil);
      break;
      
    case INFINIT_LOGIN_VIEW_NOT_LOGGED_IN_WITH_CREDENTIALS:
      self.fullname.enabled = NO;
      self.fullname.hidden = YES;
      help_str = NSLocalizedString(@"Forgot password?", nil);
      break;
      
    default:
      ELLE_WARN("%s: unknown login view mode", self.description.UTF8String);
      break;
  }
  self.help_button.attributedTitle = [[NSAttributedString alloc] initWithString:help_str
                                                                     attributes:_link_right_attrs];
  [self setupButtonsForMode:_mode];
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
  if (_mode == INFINIT_LOGIN_VIEW_REGISTER)
  {
    self.fullname_pos.constant = 317.0;
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
    {
      context.duration = 0.15;
      self.fullname.hidden = NO;
      [self.fullname_pos.animator setConstant:26.0];
      [self.fullname.animator setAlphaValue:1.0];
      [self.content_height_constraint.animator setConstant:378.0];
    }
                        completionHandler:^
     {
       self.fullname.hidden = NO;
       self.fullname.alphaValue = 1.0;
       self.fullname_pos.constant = 26.0;
       self.content_height_constraint.constant = 378.0;
       [self.view.window makeFirstResponder:self.fullname];
     }];
  }
  else if (last_mode == INFINIT_LOGIN_VIEW_REGISTER)
  {
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
     {
       context.duration = 0.15;
       [self.fullname.animator setAlphaValue:0.0];
       [self.content_height_constraint.animator setConstant:333.0];
     }
                        completionHandler:^
     {
       self.fullname.alphaValue = 0.0;
       self.fullname.hidden = YES;
       self.content_height_constraint.constant = 333.0;
       [self.view.window makeFirstResponder:self.email_address];
     }];
  }
}

- (void)showWithError:(NSString*)error
             username:(NSString*)username
          andPassword:(NSString*)password
{
  self.mode = INFINIT_LOGIN_VIEW_NOT_LOGGED_IN_WITH_CREDENTIALS;
  self.running = NO;
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
  self.error_message.attributedStringValue =
    [[NSAttributedString alloc] initWithString:error
                                    attributes:_error_attrs];
  self.problem_button.hidden = NO;
  self.version.hidden = NO;
  if (!_showing_error)
  {
    _showing_error = YES;
    self.error_message.alphaValue = 0.0;
    self.error_message.hidden = NO;
    CGFloat height = self.content_height_constraint.constant;
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
    {
      context.duration = 0.1;
      [self.error_message.animator setAlphaValue:1.0];
      [self.content_height_constraint.animator setConstant:(height + 20.0)];
    }
                        completionHandler:^
     {
       self.error_message.alphaValue = 1.0;
       self.content_height_constraint.constant = height + 20.0;
     }];
  }
}

- (void)hideError
{
  if (!_showing_error)
    return;
  self.problem_button.hidden = YES;
  self.version.hidden = YES;
  CGFloat height = self.content_height_constraint.constant;
  _showing_error = NO;
  self.error_message.alphaValue = 0.0;
  self.error_message.hidden = YES;
  self.content_height_constraint.constant = height - 20.0;
}

//- Action Handling --------------------------------------------------------------------------------

- (BOOL)loginInputsGood
{
  if (![IAFunctions stringIsValidEmail:self.email_address.stringValue])
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

- (void)registerCallback:(IAGapOperationResult*)result
{
  self.running = NO;
  if (result.success)
  {
    ELLE_LOG("%s: Successfully registered as: %s",
             self.description.UTF8String, self.email_address.stringValue);
    [[IAKeychainManager sharedInstance] addPasswordKeychain:self.email_address.stringValue
                                                   password:self.password.stringValue];
    [_delegate registered:self];
  }
  else
  {
    self.action_button.enabled = YES;
    self.fullname.enabled = YES;
    self.email_address.enabled = YES;
    self.password.enabled = YES;
    NSString* error;
    switch (result.status)
    {
      case gap_already_logged_in:
        [[IAGapState instance] setLoggedIn:YES];
        [_delegate alreadyLoggedIn:self];
        return;
      case gap_email_already_registered:
        error = NSLocalizedString(@"This email has already been registered.", nil);
        break;
      case gap_email_not_valid:
        error = NSLocalizedString(@"Email not valid.", nil);
        break;
      case gap_password_not_valid:
        error = NSLocalizedString(@"Password not valid.", nil);
        break;
      case gap_fullname_not_valid:
        error = NSLocalizedString(@"Full name not valid.", nil);
        break;

      default:
        error = [NSString stringWithFormat:@"%@: %d", NSLocalizedString(@"Unknown error", nil),
                 result.status];
        break;
    }
    [self showError:error];
  }
}

- (IBAction)actionButtonClicked:(IABottomButton*)sender
{
  if (_running)
    return;

  self.running = YES;
  [self.spinner startAnimation:nil];
  self.action_button.enabled = NO;
  self.fullname.stringValue = self.fullname.stringValue;
  self.fullname.enabled = NO;
  self.email_address.stringValue = self.email_address.stringValue;
  self.email_address.enabled = NO;
  self.password.stringValue = self.password.stringValue;
  self.password.enabled = NO;

  if (_mode == INFINIT_LOGIN_VIEW_REGISTER)
  {
    if ([self registerInputsGood])
    {
      [self hideError];
      [[IAGapState instance] register_:self.email_address.stringValue
                          withFullname:self.fullname.stringValue
                           andPassword:self.password.stringValue
                       performSelector:@selector(registerCallback:)
                              onObject:self];
    }
  }
  else
  {
    if ([self loginInputsGood])
    {
      [self hideError];
      [_delegate tryLogin:self
                 username:self.email_address.stringValue
                 password:self.password.stringValue];
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

- (IBAction)changeModeClicked:(IAHoverButton*)sender
{
  _showing_error = NO;
  self.error_message.alphaValue = 0.0;
  if (_mode == INFINIT_LOGIN_VIEW_REGISTER)
    self.mode = INFINIT_LOGIN_VIEW_NOT_LOGGED_IN;
  else
    self.mode = INFINIT_LOGIN_VIEW_REGISTER;
}

- (IBAction)helpClicked:(IAHoverButton*)sender
{
  if (_mode == INFINIT_LOGIN_VIEW_REGISTER)
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithUTF8String:INFINIT_HELP_URL]]];
  else
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithUTF8String:INFINIT_FORGOT_PASSWORD_URL]]];
  [self closeLoginView];
}


@end
