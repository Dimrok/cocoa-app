//
//  IAOnboardingViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 9/10/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAOnboardingViewController.h"

@interface IAOnboardingViewController ()

@end

//- Onboarding Window ------------------------------------------------------------------------------

@interface IAOnboardingWindow : NSWindow
@end

@implementation IAOnboardingWindow

- (BOOL)canBecomeKeyWindow
{
    return YES;
}

@end

//- Onboarding View --------------------------------------------------------------------------------

@interface IAOnboardingView : NSView
@end

@implementation IAOnboardingView

- (BOOL)acceptsFirstResponder
{
    return YES;
}

@end

@implementation IAOnboardingViewController
{
@private
    id<IAOnboardingViewProtocol> _delegate;
    IAOnboardingWindow* _window;
    NSDictionary* _message_attrs;
    NSDictionary* _back_button_attrs;
    NSDictionary* _next_button_attrs;
    NSInteger _onboard_screen;
}

//- Initialisation ---------------------------------------------------------------------------------

+ (IAOnboardingWindow*)windowWithFrame:(NSRect)frame
                                screen:(NSScreen*)screen
{
    IAOnboardingWindow* result = [[IAOnboardingWindow alloc]
                                  initWithContentRect:frame
                                            styleMask:NSBorderlessWindowMask
                                              backing:NSBackingStoreBuffered
                                                defer:YES
                                               screen:screen];
    result.alphaValue = 0.0;
	result.backgroundColor = [NSColor clearColor];
    result.hasShadow = NO;
	result.opaque = NO;
    [result setLevel:CGShieldingWindowLevel()];
    return result;
}

- (id)initWithDelegate:(id<IAOnboardingViewProtocol>)delegate
{
    if (self = [super initWithNibName:self.className bundle:nil])
    {
        _delegate = delegate;
        NSMutableParagraphStyle* centre_para = [[NSParagraphStyle defaultParagraphStyle]
                                                 mutableCopy];
        centre_para.alignment = NSCenterTextAlignment;
        _message_attrs = [IAFunctions textStyleWithFont:[NSFont systemFontOfSize:15.0]
                                         paragraphStyle:centre_para
                                                 colour:IA_RGB_COLOUR(81.0, 81.0, 73.0)
                                                 shadow:nil];
        _back_button_attrs = [IAFunctions textStyleWithFont:[NSFont systemFontOfSize:13.0]
                                             paragraphStyle:centre_para
                                                     colour:IA_RGB_COLOUR(81.0, 81.0, 73.0)
                                                     shadow:nil];
        _next_button_attrs = [IAFunctions textStyleWithFont:[NSFont systemFontOfSize:13.0]
                                             paragraphStyle:centre_para
                                                     colour:IA_RGB_COLOUR(81.0, 81.0, 73.0)
                                                     shadow:nil];
        _onboard_screen = 1;
    }
    return self;
}

- (void)loadView
{
    [super loadView];
}

//- Onboarding Screens -----------------------------------------------------------------------------

- (void)firstOnboardingScreen
{
    [_window.contentView addSubview:self.view];
    [self.back_button setHidden:YES];
    [self.files_icon setHidden:YES];
    [_delegate onboardingViewWantsStartPulseStatusBarIcon:self];
    
    NSString* back_str = NSLocalizedString(@"Back", @"Back");
    self.back_button.attributedTitle = [[NSAttributedString alloc] initWithString:back_str
                                                                       attributes:_back_button_attrs];
    NSString* next_str = NSLocalizedString(@"Next", @"Next");
    self.next_button.attributedTitle = [[NSAttributedString alloc] initWithString:next_str
                                                                       attributes:_next_button_attrs];
    
    NSPoint centre = NSMakePoint(_window.frame.size.width / 2.0,
                                 _window.frame.size.height / 2.0);
    [self.message_view setFrameOrigin:NSMakePoint(centre.x - self.message_view.frame.size.width / 2.0,
                                                  centre.y - self.message_view.frame.size.height / 2.0)];
    NSString* message_str = NSLocalizedString(@"The Infinit icon can be found in the menu bar", nil);
    self.message.attributedStringValue = [[NSAttributedString alloc] initWithString:message_str
                                                                         attributes:_message_attrs];
}

- (void)secondOnboardingScreen
{
    [self.back_button setHidden:NO];
    [self.files_icon setHidden:NO];
    [_delegate onboardingViewWantsStopPulseStatusBarIcon:self];
    
    NSString* back_str = NSLocalizedString(@"Back", @"Back");
    self.back_button.attributedTitle = [[NSAttributedString alloc] initWithString:back_str
                                                                       attributes:_back_button_attrs];
    NSString* next_str = NSLocalizedString(@"Done", @"Done");
    self.next_button.attributedTitle = [[NSAttributedString alloc] initWithString:next_str
                                                                       attributes:_next_button_attrs];
    
    NSPoint centre = NSMakePoint(_window.frame.size.width / 2.0,
                                 _window.frame.size.height / 2.0);
    [self.message_view setFrameOrigin:NSMakePoint(centre.x - self.message_view.frame.size.width / 2.0,
                                                  centre.y - self.message_view.frame.size.height / 2.0)];
    NSString* message_str = NSLocalizedString(@"Drag files up to the Infinit icon to send them", nil);
    self.message.attributedStringValue = [[NSAttributedString alloc] initWithString:message_str
                                                                         attributes:_message_attrs];
    NSPoint icon_position = [_delegate onboardingViewWantsInfinitIconPosition:self];
    
    [_window.contentView addSubview:self.files_icon];
    [self.files_icon setFrameOrigin:NSMakePoint(icon_position.x - 30.0,
                                                icon_position.y - self.files_icon.frame.size.height + 15.0)];
}

//- Opening/Closing Window -------------------------------------------------------------------------

- (void)openOnboardingWindow
{
    if (_window != nil)
        return;
    
    _window = [IAOnboardingViewController windowWithFrame:[NSScreen mainScreen].frame
                                                   screen:[NSScreen mainScreen]];
    _window.alphaValue = 0.0;
    _window.delegate = self;
    
    [self firstOnboardingScreen];
    
    [_window makeKeyAndOrderFront:nil];
    
    [_window makeFirstResponder:self.view];
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
     {
         context.duration = 0.5;
         [_window.animator setAlphaValue:1.0];
     }
                        completionHandler:^
     {
     }];
}

- (void)closeOnboarding
{
    if (_window == nil)
    {
        return;
    }
    _window.delegate = nil;
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
     {
         context.duration = 0.2;
         [_window.animator setAlphaValue:0.0];
     }
                        completionHandler:^
     {
         [_window orderOut:nil];
         _window = nil;
     }];
}

//- General Functions ------------------------------------------------------------------------------

- (void)startOnboarding
{
    [self openOnboardingWindow];
}

- (void)selectScreen
{
    switch (_onboard_screen)
    {
        case 1:
            [self firstOnboardingScreen];
            break;
        case 2:
            [self secondOnboardingScreen];
            break;
            
        default:
            [_delegate onboardingComplete:self];
            break;
    }
}

//- Button Handling --------------------------------------------------------------------------------

- (IBAction)nextButtonClicked:(NSButton*)sender
{
    ++_onboard_screen;
    [self selectScreen];
}

- (IBAction)backButtonClicked:(NSButton*)sender
{
    --_onboard_screen;
    [self selectScreen];
}

- (IBAction)closeButtonClicked:(NSButton*)sender
{
    [_delegate onboardingComplete:self];
}

@end
