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
	result.backgroundColor = IA_RGBA_COLOUR(32.0, 32.0, 32.0, 0.5);
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
        NSMutableParagraphStyle* message_para = [[NSParagraphStyle defaultParagraphStyle]
                                                 mutableCopy];
        message_para.alignment = NSCenterTextAlignment;
        _message_attrs = [IAFunctions textStyleWithFont:[NSFont boldSystemFontOfSize:20.0]
                                         paragraphStyle:message_para
                                                 colour:IA_GREY_COLOUR(255.0)
                                                 shadow:[IAFunctions
                                                         shadowWithOffset:NSMakeSize(1.0, -1.0)
                                                               blurRadius:2.0
                                                                    color:IA_GREY_COLOUR(0.0)]];
    }
    return self;
}

- (void)loadView
{
    [super loadView];
}

//- Onboardin Screens ------------------------------------------------------------------------------

- (void)firstOnboardingScreen
{
    NSString* message_str = NSLocalizedString(@"Drag files up to the Infinit icon to send them", nil);
    self.message.attributedStringValue = [[NSAttributedString alloc] initWithString:message_str
                                                                         attributes:_message_attrs];
    NSPoint icon_position = [_delegate onboardingViewWantsInfinitIconPosition:self];
    IALog(@"xxx %f,%f", icon_position.x, icon_position.y);
    icon_position.x -= self.files_icon.frame.size.width / 2.0;
    icon_position.y -= self.files_icon.frame.size.height;
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
    _window.contentView = self.view;
    self.view_height.constant = [NSScreen mainScreen].frame.size.height;
    self.view_width.constant = [NSScreen mainScreen].frame.size.width;
    [self.view setFrameOrigin:NSZeroPoint];
    
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

//- Button Handling --------------------------------------------------------------------------------

- (IBAction)nextButtonClicked:(NSButton*)sender
{
    [_delegate onboardingComplete:self];
}

- (IBAction)backButtonClicked:(NSButton*)sender
{
    
}

- (IBAction)closeButtonClicked:(NSButton*)sender
{
    [_delegate onboardingComplete:self];
}

@end
