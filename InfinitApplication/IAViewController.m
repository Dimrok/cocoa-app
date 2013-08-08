//
//  IAViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 7/31/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAViewController.h"

@interface IAViewController ()

@end

//- Footer View ------------------------------------------------------------------------------------

@implementation IAFooterView

- (void)setFrame:(NSRect)frameRect
{
    [super setFrame:frameRect];
    [self invalidateIntrinsicContentSize];
    [self setNeedsDisplay:YES];
}

- (void)setFrameSize:(NSSize)newSize
{
    [super setFrameSize:newSize];
    [self invalidateIntrinsicContentSize];
    [self setNeedsDisplay:YES];
}

- (NSSize)intrinsicContentSize
{
    return self.bounds.size;
}

- (NSString*)description
{
    return @"FooterView";
}

@end

//- Header View ------------------------------------------------------------------------------------

@implementation IAHeaderView

- (void)setFrame:(NSRect)frameRect
{
    [super setFrame:frameRect];
    [self invalidateIntrinsicContentSize];
    [self setNeedsDisplay:YES];
}

- (void)setFrameSize:(NSSize)newSize
{
    [super setFrameSize:newSize];
    [self invalidateIntrinsicContentSize];
    [self setNeedsDisplay:YES];
}

- (NSSize)intrinsicContentSize
{
    return self.bounds.size;
}

- (NSString*)description
{
    return @"HeaderView";
}

@end

//- Main View --------------------------------------------------------------------------------------

@implementation IAMainView

- (void)drawRect:(NSRect)dirtyRect
{
    NSBezierPath* bg = [NSBezierPath bezierPathWithRect:self.bounds];
    [TH_RGBCOLOR(246.0, 246.0, 246.0) set];
    [bg fill];
}

- (void)setFrame:(NSRect)frameRect
{
    [super setFrame:frameRect];
    [self invalidateIntrinsicContentSize];
    [self setNeedsDisplay:YES];
}

- (void)setFrameSize:(NSSize)newSize
{
    [super setFrameSize:newSize];
    [self invalidateIntrinsicContentSize];
    [self setNeedsDisplay:YES];
}

- (NSSize)intrinsicContentSize
{
    return self.bounds.size;
}

- (NSString*)description
{
    return @"MainView";
}

@end

//- View Controller --------------------------------------------------------------------------------

@implementation IAViewController

@synthesize header_view;
@synthesize main_view;
@synthesize footer_view;

- (BOOL)closeOnFocusLost
{
    return NO;
}

- (void)resizeContainerView
{
    CGFloat height = self.header_view.frame.size.height + self.main_view.frame.size.height +
    self.footer_view.frame.size.height;
    NSSize new_size = NSMakeSize(self.view.frame.size.width, height);
    CGFloat y_diff = height - self.view.window.frame.size.height;
    NSRect window_rect = NSZeroRect;
    window_rect.origin = NSMakePoint(self.view.window.frame.origin.x,
                                     self.view.window.frame.origin.y - y_diff);
    window_rect.size = new_size;
    [self.view.window setFrame:window_rect
                       display:YES
                       animate:YES];
    [self.view.animator layoutSubtreeIfNeeded];
    [self.view setFrame:NSMakeRect(0.0, 0.0, new_size.width, new_size.height)];
    [self.view.window display];
    [self.view.window invalidateShadow];
}

@end
