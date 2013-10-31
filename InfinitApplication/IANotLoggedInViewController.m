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
    NSDictionary* _message_attrs;
}

//- Initialisation ---------------------------------------------------------------------------------

@synthesize mode = _mode;

- (id)initWithMode:(IANotLoggedInViewMode)mode
{
    if (self = [super initWithNibName:[self className] bundle:nil])
    {
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
    }
    return self;
}

- (void)awakeFromNib
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
    
    [self configureForMode:_mode];
}

- (void)configureForMode:(IANotLoggedInViewMode)mode
{
    NSString* message;
    if (_mode == LOGGED_OUT)
    {
        message = NSLocalizedString(@"Not currently logged in...", @"not logged in");
        [self.login_button setEnabled:YES];
    }
    else if (_mode == LOGGING_IN)
    {
        message = NSLocalizedString(@"Logging in...", @"logging in");
        [self.login_button setEnabled:NO];
    }
    self.not_logged_message.attributedStringValue = [[NSAttributedString alloc]
                                                     initWithString:message
                                                     attributes:_message_attrs];
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

@end