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

- (CGFloat)heightDiffOld:(NSSize)old_size new:(NSSize)new_size
{
    return new_size.height - old_size.height;
}

@end
