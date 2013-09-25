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
    [IA_GREY_COLOUR(246.0) set];
    [path fill];
}

@end

@implementation IANotLoggedInViewController

- (id)initWithDelegate:(id<IANotLoggedInViewProtocol>)delegate
{
    if (self = [super initWithNibName:[self className] bundle:nil])
    {
        _delegate = delegate;
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
    
    NSDictionary* message_attrs = [IAFunctions textStyleWithFont:[NSFont systemFontOfSize:12.0]
                                                  paragraphStyle:style
                                                          colour:IA_GREY_COLOUR(32.0)
                                                          shadow:nil];
    NSString* message = NSLocalizedString(@"Not currently logged in...", @"not logged in");
    
    self.not_logged_message.attributedStringValue = [[NSAttributedString alloc]
                                                     initWithString:message
                                                         attributes:message_attrs];
}

- (BOOL)closeOnFocusLost
{
    return YES;
}

//- Button Handling --------------------------------------------------------------------------------

- (IBAction)openLoginWindow:(NSButton*)sender
{
    [_delegate notLoggedInViewControllerWantsOpenLoginWindow:self];
}

@end