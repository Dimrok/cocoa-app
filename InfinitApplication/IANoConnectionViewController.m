//
//  IANoConnectionViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 9/2/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IANoConnectionViewController.h"

@interface IANoConnectionViewController ()

@end

@interface IANoConnectionView : IAMainView
@end

@implementation IANoConnectionView

- (void)drawRect:(NSRect)dirtyRect
{
    NSBezierPath* path = [NSBezierPath bezierPathWithRect:self.bounds];
    [IA_GREY_COLOUR(246.0) set];
    [path fill];
}

- (NSSize)intrinsicContentSize
{
    return self.bounds.size;
}

@end

@implementation IANoConnectionViewController

//- Initialisation ---------------------------------------------------------------------------------

- (id)init
{
    if (self = [super initWithNibName:[self className] bundle:nil])
    {
    }
    return self;
}

- (BOOL)closeOnFocusLost
{
    return YES;
}

- (void)awakeFromNib
{
    NSMutableParagraphStyle* style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    style.alignment = NSCenterTextAlignment;
    NSDictionary* message_attrs = [IAFunctions textStyleWithFont:[NSFont systemFontOfSize:12.0]
                                                  paragraphStyle:style
                                                          colour:IA_GREY_COLOUR(32.0)
                                                          shadow:nil];
    NSString* message = NSLocalizedString(@"No connection to the Internet...", @"no connection");
    
    self.no_connection_message.attributedStringValue = [[NSAttributedString alloc]
                                                        initWithString:message
                                                            attributes:message_attrs];
}

- (void)loadView
{
    [super loadView];
    [self.view layoutSubtreeIfNeeded];
}

@end
