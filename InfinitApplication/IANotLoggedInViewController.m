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
    [TH_RGBCOLOR(246.0, 246.0, 246.0) set];
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

- (NSString*)description
{
    return @"NotLoggedInViewController";
}

//- Button Handling --------------------------------------------------------------------------------

- (IBAction)openLoginWindow:(NSButton*)sender
{
    [_delegate notLoggedInViewControllerWantsOpenLoginWindow:self];
}

@end