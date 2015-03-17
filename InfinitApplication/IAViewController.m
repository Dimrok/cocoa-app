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

//- Plain White Opaque View ------------------------------------------------------------------------

@interface InfinitWhiteView : NSView
@end

@implementation InfinitWhiteView

- (BOOL)isOpaque
{
  return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
  [IA_GREY_COLOUR(255) set];
  NSRectFill(self.bounds);
}

- (NSString*)description
{
  return [NSString stringWithFormat:@"%@ (%f, %f) (%f x %f)", super.description,
          self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.frame.size.height];
}

- (NSSize)intrinsicContentSize
{
  return self.bounds.size;
}

@end

//- Footer View ------------------------------------------------------------------------------------

@implementation IAFooterView

- (BOOL)wantsUpdateLayer
{
  return NO;
}

- (NSSize)intrinsicContentSize
{
  return self.bounds.size;
}

@end

//- Header View ------------------------------------------------------------------------------------

@implementation IAHeaderView

- (BOOL)wantsUpdateLayer
{
  return NO;
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

- (void)drawRect:(NSRect)dirtyRect
{
  [IA_GREY_COLOUR(255) set];
  NSRectFill(self.bounds);
}

- (BOOL)wantsUpdateLayer
{
  return NO;
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

- (void)viewActive
{
  // Called just before view is shown
}

- (void)aboutToChangeView
{
  // Called just before view is changed so that tidy up can occur, overload as needed
}

@end
