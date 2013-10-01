//
//  IAPopoverViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 9/30/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAPopoverViewController.h"

@interface IAPopoverViewController ()
@end

@implementation IAPopoverViewController
{
@private
    id<IAPopoverViewProtocol> _delegate;
}

//- Initialisation ---------------------------------------------------------------------------------

@synthesize popover;

- (id)initWithDelegate:(id<IAPopoverViewProtocol>)delegate;
{
    if (self = [super initWithNibName:self.className bundle:nil])
    {
        _delegate = delegate;
    }
    return self;
}

//- General Functions ------------------------------------------------------------------------------

- (void)showHeading:(NSString*)heading
         andMessage:(NSString*)message
         leftButton:(NSString*)left_button_str
      midddleButton:(NSString*)middle_button_str
        rightButton:(NSString*)right_button_str
          belowView:(NSView*)view
{
    self.popover.animates = YES;
    self.popover.contentViewController.view = self.view;
    
    if (left_button_str == nil || left_button_str.length == 0)
    {
        [self.left_button setHidden:YES];
    }
    else
    {
        [self.left_button setHidden:NO];
        self.left_button.title = left_button_str;
    }
    
    if (middle_button_str == nil || middle_button_str.length == 0)
    {
        [self.middle_button setHidden:YES];
    }
    else
    {
        [self.middle_button setHidden:NO];
        self.middle_button.title = middle_button_str;
    }
    
    if (right_button_str == nil || right_button_str.length == 0)
    {
        [self.right_button setHidden:YES];
    }
    else
    {
        [self.right_button setHidden:NO];
        self.right_button.title = right_button_str;
    }
    
    self.heading.stringValue = heading;
    self.message.stringValue = message;
    self.popover.appearance = NSPopoverAppearanceHUD;
    [self.popover showRelativeToRect:view.frame ofView:view preferredEdge:NSMinYEdge];
    self.popover.contentSize = self.view.frame.size;
}

- (void)hidePopover
{
    [self.popover close];
}

//- Button Handling --------------------------------------------------------------------------------

- (IBAction)middleButtonClicked:(NSButton*)sender
{
    [_delegate popoverHadMiddleButtonClicked:self];
}

- (IBAction)leftButtonClicked:(NSButton*)sender
{
    [_delegate popoverHadLeftButtonClicked:self];
}

- (IBAction)rightButtonClicked:(NSButton*)sender
{
    [_delegate popoverHadRightButtonClicked:self];
}

- (void)mouseDown:(NSEvent*)theEvent
{
    if (self.left_button.isHidden && self.middle_button.isHidden && self.right_button.isHidden)
        [self hidePopover];
}

@end
