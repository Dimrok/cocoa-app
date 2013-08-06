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

@end
