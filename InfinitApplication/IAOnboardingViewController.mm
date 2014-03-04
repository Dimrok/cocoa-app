//
//  IAOnboardingViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 9/27/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAOnboardingViewController.h"

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("OSX.OnboardingViewController");

@interface IAOnboardingMainView : IAMainView
@end

@implementation IAOnboardingMainView

- (void)drawRect:(NSRect)dirtyRect
{
    NSBezierPath* bg = [NSBezierPath bezierPathWithRect:self.bounds];
    [IA_GREY_COLOUR(248.0) set];
    [bg fill];
}

@end

@interface IAOnboardingViewController ()
@end

@implementation IAOnboardingViewController
{
@private
    id<IAOnboardingProtocol> _delegate;
    
    NSInteger _page;
    NSView* _position_view;
    
    NSMutableArray* _headings;
    NSMutableArray* _messages;
    
    NSDictionary* _heading_style;
    NSDictionary* _message_style;
    NSDictionary* _button_style;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithDelegate:(id<IAOnboardingProtocol>)delegate
{
    if (self = [super initWithNibName:self.className bundle:nil])
    {
        _delegate = delegate;
        
        _page = 0;
        
        _headings = [NSMutableArray array];
        [_headings addObject:NSLocalizedString(@"Drag and Drop",
                                               @"Drag and Drop")];
        [_headings addObject:NSLocalizedString(@"Search and Send",
                                               @"Search and Send")];
        [_headings addObject:NSLocalizedString(@"Receive File",
                                               @"Receive File")];
        
        _messages = [NSMutableArray array];
        [_messages addObject:NSLocalizedString(@"Drag and drop files and folders on the icon above to send them. ",
                                               @"Drag and drop files and folders on the icon above to send them. ")];
        [_messages addObject:NSLocalizedString(@"You can then search for contacts on Infinit by name, or send directly to an email address.",
                                               @"You can then search for contacts on Infinit by name, or send directly to an email address.")];
        [_messages addObject:NSLocalizedString(@"The Infinit icon turns red for incoming transfers. Click the icon to choose to accept or decline transfers.",
                                               @"The Infinit icon turns red for incoming transfers. Click the icon to choose to accept or decline transfers.")];
        NSMutableParagraphStyle* para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        para.alignment = NSCenterTextAlignment;
        _heading_style = [IAFunctions textStyleWithFont:[NSFont boldSystemFontOfSize:12.0]
                                         paragraphStyle:para
                                                 colour:IA_GREY_COLOUR(0.0)
                                                 shadow:nil];
        
        _message_style = [IAFunctions textStyleWithFont:[NSFont systemFontOfSize:11.0]
                                         paragraphStyle:para
                                                 colour:IA_GREY_COLOUR(167.0)
                                                 shadow:nil];
        NSShadow* button_shadow = [IAFunctions shadowWithOffset:NSMakeSize(0.0, -1.0)
                                                     blurRadius:1.0
                                                         colour:IA_GREY_COLOUR(0.0)];
        _button_style = [IAFunctions textStyleWithFont:[NSFont boldSystemFontOfSize:13.0]
                                        paragraphStyle:para
                                                colour:IA_GREY_COLOUR(255.0)
                                                shadow:button_shadow];
    }
    return self;
}

- (void)awakeFromNib
{
    self.skip_button.hand_cursor = NO;
    [self.skip_button setToolTip:NSLocalizedString(@"Skip", @"skip")];
    [self.skip_button setHoverImage:[IAFunctions imageNamed:@"icon-onboarding-close-hover"]];
    [self moveToPage:0];
}

- (void)loadView
{
    ELLE_TRACE("%s: loadview", self.description.UTF8String);
    [super loadView];
    [_delegate onboardingControllerStarted:self];
    [self.view setAlphaValue:1.0];
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
     {
         context.duration = 0.15;
         [self.content_height_constraint.animator setConstant:106.0];
     }
                        completionHandler:^
     {
     }];
}

- (BOOL)closeOnFocusLost
{
    return NO;
}

//- General Functions ------------------------------------------------------------------------------

- (void)moveToPage:(NSInteger)page
{
    if (page < 0 || page > _headings.count)
        return;
    
    if (page == _messages.count)
    {
        [_delegate onboardingControllerDone:self];
        return;
    }
    
    _page = page;
    
    if (_page == 0)
        [self.back_button setHidden:YES];
    else
        [self.back_button setHidden:NO];
    
    self.heading.stringValue = _headings[_page];
    self.message.stringValue = _messages[_page];
}

//- Button Handling --------------------------------------------------------------------------------

- (IBAction)backClicked:(NSButton*)sender
{
    [self moveToPage:(_page - 1)];
}

- (IBAction)nextClicked:(NSButton*)sender
{
    [self moveToPage:(_page + 1)];
}

- (IBAction)skipClicked:(NSButton*)sender
{
    [self moveToPage:_messages.count];
}

@end
