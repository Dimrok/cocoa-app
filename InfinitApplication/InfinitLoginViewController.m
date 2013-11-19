//
//  InfinitLoginViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 31/10/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "InfinitLoginViewController.h"

#import <Gap/IAGapState.h>
#import <Gap/version.h>

#define INFINIT_REGISTER_URL "http://infinit.io/register"
#define INFINIT_FORGOT_PASSWORD_URL "http://infinit.io/forgot_password"

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
    BOOL _logging_in;
    
    NSString* _version_str;
}

//- Initialisation ---------------------------------------------------------------------------------

@synthesize mode = _mode;

- (id)initWithDelegate:(id<InfinitLoginViewControllerProtocol>)delegate
              withMode:(InfinitLoginViewMode)mode
{
    if (self = [super initWithNibName:[self className] bundle:nil])
    {
        _delegate = delegate;
        _mode = mode;
        NSMutableParagraphStyle* error_para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        error_para.alignment = NSCenterTextAlignment;
        NSFont* error_font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica"
                                                                        traits:NSUnboldFontMask
                                                                        weight:5
                                                                          size:12.0];
        _error_attrs = [IAFunctions textStyleWithFont:error_font
                                       paragraphStyle:error_para
                                               colour:IA_RGB_COLOUR(222.0, 104.0, 81.0)
                                               shadow:nil];
        
        _version_str = [NSString stringWithFormat:@"v%@",
                        [NSString stringWithUTF8String:INFINIT_VERSION]];
    }
    return self;
}

- (BOOL)closeOnFocusLost
{
    return NO;
}

- (void)setLoginButtonText
{
    NSMutableParagraphStyle* style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    style.alignment = NSCenterTextAlignment;
    NSShadow* shadow = [IAFunctions shadowWithOffset:NSMakeSize(0.0, -1.0)
                                          blurRadius:1.0
                                              colour:[NSColor blackColor]];
    
    NSDictionary* button_style = [IAFunctions textStyleWithFont:[NSFont boldSystemFontOfSize:13.0]
                                                 paragraphStyle:style
                                                         colour:[NSColor whiteColor]
                                                         shadow:shadow];
    self.login_button.attributedTitle = [[NSAttributedString alloc]
                                         initWithString:NSLocalizedString(@"LOGIN", @"login")
                                         attributes:button_style];
}

- (void)setLinkText
{
    NSFont* link_font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica"
                                                                   traits:NSUnboldFontMask
                                                                   weight:0
                                                                     size:11.0];
    NSDictionary* link_attrs = [IAFunctions
                                textStyleWithFont:link_font
                                paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                colour:IA_RGB_COLOUR(103.0, 181.0, 214.0)
                                shadow:nil];
    NSString* need_account = NSLocalizedString(@"Need an account?", @"need an account?");
    NSString* forgot_password = NSLocalizedString(@"Forgot password?", @"forgot password?");
    NSString* problem = NSLocalizedString(@"Problem?", nil);
    
    self.create_account_button.attributedTitle = [[NSAttributedString alloc]
                                                  initWithString:need_account
                                                  attributes:link_attrs];
    self.forgot_password_button.attributedTitle = [[NSAttributedString alloc]
                                                   initWithString:forgot_password
                                                   attributes:link_attrs];
    self.problem_button.attributedTitle = [[NSAttributedString alloc] initWithString:problem
                                                                          attributes:link_attrs];
    [self.create_account_button setNormalTextAttributes:link_attrs];
    [self.forgot_password_button setNormalTextAttributes:link_attrs];
    [self.problem_button setNormalTextAttributes:link_attrs];
    
    NSFont* link_hover_font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica"
                                                                         traits:NSUnboldFontMask
                                                                         weight:0
                                                                           size:11.0];
    NSDictionary* link_hover_attrs = [IAFunctions
                                      textStyleWithFont:link_hover_font
                                      paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                      colour:IA_RGB_COLOUR(11.0, 117.0, 162)
                                      shadow:nil];
    [self.create_account_button setHoverTextAttributes:link_hover_attrs];
    [self.forgot_password_button setHoverTextAttributes:link_hover_attrs];
    [self.problem_button setHoverTextAttributes:link_hover_attrs];
}

- (void)viewChanged
{
    // WORKAROUND: Set focus on email field for 10.7 and 10.8
    if ([IAFunctions osxVersion] == INFINIT_OS_X_VERSION_10_7 ||
        [IAFunctions osxVersion] == INFINIT_OS_X_VERSION_10_8)
    {
        [self performSelector:@selector(delayedFocusOnEmailField) withObject:nil afterDelay:0.3];
    }
}

- (void)delayedFocusOnEmailField
{
    [self.view.window makeFirstResponder:self.email_address];
}

- (void)awakeFromNib
{
    _logging_in = NO;
    self.close_button.hand_cursor = NO;
    [self.close_button setHoverImage:[IAFunctions imageNamed:@"icon-onboarding-close-hover"]];
    [self setLoginButtonText];
    [self setLinkText];
    [self configureForMode];
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
    
    self.version.attributedStringValue = [[NSAttributedString alloc] initWithString:_version_str
                                                                         attributes:version_style];
}

//- General ----------------------------------------------------------------------------------------

- (void)configureForMode
{
    switch (_mode)
    {
        case LOGIN_VIEW_NOT_LOGGED_IN:
            [self.spinner stopAnimation:nil];
            
            self.error_message.stringValue = @"";
            [self.error_message setHidden:YES];
            [self.problem_button setHidden:YES];
            [self.version setHidden:YES];
            
            [self.email_address setEnabled:YES];
            [self.password setEnabled:YES];
            [self.login_button setEnabled:YES];
            break;
            
        case LOGIN_VIEW_NOT_LOGGED_IN_WITH_CREDENTIALS:
            [self.spinner stopAnimation:nil];
            
            [self.email_address setEnabled:YES];
            [self.error_message setHidden:NO];
            [self.problem_button setHidden:NO];
            [self.version setHidden:NO];
            [self.password setEnabled:YES];
            [self.login_button setEnabled:YES];
            [self.create_account_button setHidden:NO];
            [self.forgot_password_button setHidden:NO];
            break;
            
        default:
            IALog(@"WARNING: unknown login view mode");
            break;
    }
}

- (void)closeLoginView
{
    [_delegate loginViewWantsClose:self];
}

- (void)setLoginViewMode:(InfinitLoginViewMode)mode
{
    _mode = mode;
    [self configureForMode];
}

- (void)showWithError:(NSString*)error
             username:(NSString*)username
          andPassword:(NSString*)password
{
    _logging_in = NO;
    if (username.length > 0 && password.length > 0)
    {
        self.email_address.stringValue = username;
        self.password.stringValue = password;
        password = @"";
        password = nil;
    }
    self.error_message.attributedStringValue = [[NSAttributedString alloc]
                                                initWithString:error
                                                attributes:_error_attrs];
    [self.view.window makeFirstResponder:self.email_address];
}

//- Login ------------------------------------------------------------------------------------------

- (BOOL)inputsGood
{
    if (![IAFunctions stringIsValidEmail:self.email_address.stringValue])
    {
        NSString* error = NSLocalizedString(@"Please enter a valid email address",
                                            @"email not valid");
        self.error_message.attributedStringValue = [[NSAttributedString alloc]
                                                    initWithString:error
                                                    attributes:_error_attrs];
        [self.error_message setHidden:NO];
        return NO;
    }
    else if (self.password.stringValue.length == 0)
    {
        NSString* error = NSLocalizedString(@"Please enter your password",
                                            @"no password entered");
        self.error_message.attributedStringValue = [[NSAttributedString alloc]
                                                    initWithString:error
                                                    attributes:_error_attrs];
        [self.error_message setHidden:NO];
        return NO;
    }
    return YES;
}

- (IBAction)loginClicked:(IABottomButton*)sender
{
    if (_logging_in)
        return;
    
    if ([self inputsGood])
    {
        _logging_in = YES;
        [self.login_button setEnabled:NO];
        [self.spinner startAnimation:nil];
        [self.email_address setEnabled:NO];
        [self.password setEnabled:NO];
        [self.error_message setHidden:YES];
        [_delegate tryLogin:self
                   username:self.email_address.stringValue
                   password:self.password.stringValue];
        [self.create_account_button setHidden:YES];
        [self.forgot_password_button setHidden:YES];
    }
}

//- Close Button -----------------------------------------------------------------------------------

- (IBAction)closeButtonClicked:(NSButton*)sender
{
    // Don't quit Infinit if we're logging in
    if (_logging_in)
        [_delegate loginViewWantsClose:self];
    else
        [_delegate loginViewWantsCloseAndQuit:self];
}

//- Got a Problem ----------------------------------------------------------------------------------

- (IBAction)onProblemClick:(NSButton*)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"mailto:support@infinit.io?Subject=Login%20Problem"]];
    [self closeLoginView];
}

//- Register and Forgot Password -------------------------------------------------------------------

- (IBAction)registerButtonClicked:(IAHoverButton*)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL
                                            URLWithString:[NSString stringWithUTF8String:INFINIT_REGISTER_URL]]];
    [self closeLoginView];
}

- (IBAction)forgotPasswordButtonClicked:(IAHoverButton*)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL
                                            URLWithString:[NSString stringWithUTF8String:INFINIT_FORGOT_PASSWORD_URL]]];
    [self closeLoginView];
}

@end
