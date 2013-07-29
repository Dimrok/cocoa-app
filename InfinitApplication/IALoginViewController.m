//
//  IALoginViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 7/29/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IALoginViewController.h"

#import <Gap/IAGapState.h>
#import "IADefine.h"

@interface IALoginViewController ()

@end

//- Login window -----------------------------------------------------------------------------------

@implementation IALoginWindow

- (BOOL)canBecomeKeyWindow
{
    return YES;
}

@end

//- Login view -------------------------------------------------------------------------------------

@interface IALoginView : NSView
@end

@implementation IALoginView

- (void)drawRect:(NSRect)dirtyRect
{
    CGFloat corner_radius = 10.0;
    NSBezierPath* path = [NSBezierPath bezierPathWithRoundedRect:self.bounds
                                                         xRadius:corner_radius
                                                         yRadius:corner_radius];
    
    [TH_RGBCOLOR(246.0, 246.0, 246.0) set];
    [path fill];
}

@end

//- Initiailisation --------------------------------------------------------------------------------

@implementation IALoginViewController

+ (IALoginWindow*)windowWithFrame:(NSRect)frame screen:(NSScreen*)screen
{
    IALoginWindow* result = [[IALoginWindow alloc] initWithContentRect:frame
                                                             styleMask:NSBorderlessWindowMask
                                                               backing:NSBackingStoreBuffered
                                                                 defer:YES
                                                                screen:screen];
    result.alphaValue = 0.0;
	result.backgroundColor = [NSColor clearColor];
    result.hasShadow = YES;
	result.opaque = NO;
    [result setLevel:NSFloatingWindowLevel];
    [result setMovableByWindowBackground:YES];
    return result;
}

- (id)initWithDelegate:(id<IALoginViewControllerProtocol>)delegate
{
    if (self = [super initWithNibName:[self className] bundle:nil])
    {
        _delegate = delegate;
    }
    return self;
}

- (void)awakeFromNib
{
    [self.email_address setDelegate:self];
    [self.password setDelegate:self];
}

- (NSString*)description
{
    return @"[LoginViewController]";
}

//- General Functions ------------------------------------------------------------------------------

- (void)showLoginWindowOnScreen:(NSScreen*)screen
{
    NSRect frame = NSZeroRect;
    frame.size = self.view.bounds.size;
    frame.origin = [self centreFrame:frame onScreen:screen];
    
    [self.view addSubview:[self login_view]];
    _window = [IALoginViewController windowWithFrame:frame screen:screen];
    _window.delegate = self;
    _window.alphaValue = 1.0;
    _window.contentView = self.view;
    [_window invalidateShadow];
    [_window update];
    [self.login_view setNeedsDisplay:YES];
    [_window makeKeyAndOrderFront:nil];
}

- (NSPoint)centreFrame:(NSRect)frame onScreen:(NSScreen*)screen
{
    CGFloat x = floor(NSWidth(screen.frame) / 2.0 - NSWidth(frame) / 2.0);
    CGFloat y = floor(NSHeight(screen.frame) / 2.0 - NSHeight(frame) / 2.0);
    return NSMakePoint(x, y);
}

//- Text Fields ------------------------------------------------------------------------------------

- (void)controlTextDidChange:(NSNotification*)aNotification
{
    NSControl* control = aNotification.object;
    if (control == self.email_address)
    {
        IALog(@"xxx %d", self.email_address.stringValue.length);
        if (self.email_address.stringValue.length == 0)
            [self.create_account_link setHidden:NO];
        else
            [self.create_account_link setHidden:YES];
    }
    else if (control == self.password)
    {
        if (self.password.stringValue.length == 0)
            [self.fogot_password_link setHidden:NO];
        else
            [self.fogot_password_link setHidden:YES];
    }
}

@end
