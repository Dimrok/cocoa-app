//
//  InfinitTooltipViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 02/04/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitTooltipViewController.h"

@interface InfinitTooltipViewController ()
@end

@implementation InfinitTooltipViewController
{
@private
  INPopoverController* _popover_controller;
  NSWindow* _focus_window;
  NSSize _arrow_size;
}

@synthesize message = _message;

- (id)init
{
  if (self = [super initWithNibName:self.className bundle:nil])
  {
    _popover_controller = [[INPopoverController alloc] initWithContentViewController:self];
    _popover_controller.delegate = self;
    _popover_controller.color = [NSColor colorWithCalibratedWhite:0.0 alpha:0.8];
    _popover_controller.cornerRadius = 3.0;
    _popover_controller.borderWidth = 0.0;
    _arrow_size = NSMakeSize(8.0, 8.0);
    _popover_controller.arrowSize = _arrow_size;
    _popover_controller.closesWhenPopoverResignsKey = NO;
    _popover_controller.closesWhenApplicationBecomesInactive = YES;
    _popover_controller.animationType = INPopoverAnimationTypePop;
  }
  return self;
}

- (BOOL)showing
{
  return _popover_controller.popoverIsVisible;
}

- (void)showPopoverForView:(NSView*)view
        withArrowDirection:(INPopoverArrowDirection)direction
               withMessage:(NSString*)message
{
  _message.stringValue = message;
  [self.view layoutSubtreeIfNeeded];
  _popover_controller.contentSize = NSMakeSize(_message.intrinsicContentSize.width + _arrow_size.width + 2.0,
                                               _message.intrinsicContentSize.height + 6.0);
  [_popover_controller presentPopoverFromRect:view.bounds
                                       inView:view
                      preferredArrowDirection:direction
                        anchorsToPositionView:YES];
  _focus_window = view.window;
}

- (void)close
{
  if (self.showing)
    [_popover_controller closePopover:self];
}

//- Popover Protocol -------------------------------------------------------------------------------

- (void)popoverDidShow:(INPopoverController*)popover
{
  [_focus_window makeKeyWindow];
}

@end
