//
//  IANotLoggedInView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 7/26/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IANotLoggedInViewController.h"

@interface IANotLoggedInViewController ()

@end

@interface IANotLoggedInView : NSView
@end

@implementation IANotLoggedInView

- (void)drawRect:(NSRect)dirtyRect
{
    NSBezierPath* path = [NSBezierPath bezierPathWithRect:self.bounds];
    [IA_GREY_COLOUR(248.0) set];
    [path fill];
}

@end

@implementation IANotLoggedInViewController
{
@private
    id<IANotLoggedInViewProtocol> _delegate;
    NSDictionary* _message_attrs;
    NSDictionary* _button_style;
}

//- Initialisation ---------------------------------------------------------------------------------

@synthesize mode = _mode;

- (id)initWithMode:(IANotLoggedInViewMode)mode
       andDelegate:(id<IANotLoggedInViewProtocol>)delegate;
{
    if (self = [super initWithNibName:[self className] bundle:nil])
    {
        _delegate = delegate;
        _mode = mode;
        NSMutableParagraphStyle* style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        style.alignment = NSCenterTextAlignment;
        NSFont* message_font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica"
                                                                          traits:NSUnboldFontMask
                                                                          weight:0
                                                                            size:12.0];
        _message_attrs = [IAFunctions textStyleWithFont:message_font
                                         paragraphStyle:style
                                                 colour:IA_GREY_COLOUR(32.0)
                                                 shadow:nil];
    
        NSShadow* shadow = [IAFunctions shadowWithOffset:NSMakeSize(0.0, -1.0)
                                              blurRadius:1.0
                                                  colour:[NSColor blackColor]];
        
        _button_style = [IAFunctions textStyleWithFont:[NSFont boldSystemFontOfSize:13.0]
                                        paragraphStyle:style
                                                colour:[NSColor whiteColor]
                                                shadow:shadow];
    }
    return self;
}

- (void)awakeFromNib
{
    [self configureForMode:_mode];
}

- (void)configureForMode:(IANotLoggedInViewMode)mode
{
    NSString* message;
    NSString* button_text;
    if (_mode == INFINIT_LOGGED_OUT)
    {
        button_text = NSLocalizedString(@"LOGIN", @"login");
        message = NSLocalizedString(@"Not currently logged in...", @"not logged in");
        [self.bottom_button setEnabled:YES];
    }
    else if (_mode == INFINIT_LOGGING_IN)
    {
        button_text = NSLocalizedString(@"LOGIN", @"login");
        message = NSLocalizedString(@"Logging in...", @"logging in");
        [self.bottom_button setEnabled:NO];
    }
    else if (_mode == INFINIT_WAITING_FOR_CONNECTION)
    {
        button_text = NSLocalizedString(@"QUIT", @"quit");
        message = NSLocalizedString(@"Waiting for connection...", @"waiting for connection");
        [self.bottom_button setEnabled:YES];
    }
    self.not_logged_message.attributedStringValue = [[NSAttributedString alloc]
                                                     initWithString:message
                                                     attributes:_message_attrs];
    
    self.bottom_button.attributedTitle = [[NSAttributedString alloc]
                                          initWithString:button_text
                                          attributes:_button_style];
}

- (BOOL)closeOnFocusLost
{
    return YES;
}

//- General Functions ------------------------------------------------------------------------------

- (void)setMode:(IANotLoggedInViewMode)mode
{
    _mode = mode;
    [self configureForMode:mode];
}

//- User Interaction -------------------------------------------------------------------------------

- (IBAction)bottomButtonClicked:(IABottomButton*)sender
{
    if (_mode == INFINIT_WAITING_FOR_CONNECTION)
        [_delegate notLoggedInViewWantsQuit:self];
}

@end