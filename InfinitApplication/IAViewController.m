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

@end

//- Main View --------------------------------------------------------------------------------------

@implementation IAMainView

- (BOOL)isOpaque
{
    return YES;
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

- (void)aboutToChangeView
{
    // Called just before view is changed so that tidy up can occur, overload as needed
}

- (CGFloat)heightDiffOld:(NSSize)old_size new:(NSSize)new_size
{
    return new_size.height - old_size.height;
}

//- Transaction and User Update Handling -----------------------------------------------------------

- (void)transactionAdded:(IATransaction*)transaction
{
    // Do nothing by default, overload if needed
    return;
}

- (void)transactionUpdated:(IATransaction*)transaction
{
    // Do nothing by default, overload if needed
    return;
}

- (void)userUpdated:(IAUser*)user
{
    // Do nothing by default, overload if needed
    return;
}

@end
