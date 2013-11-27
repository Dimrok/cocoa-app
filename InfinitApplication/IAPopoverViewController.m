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

//- Popover TextField Cell -------------------------------------------------------------------------

@implementation IAPopoverTextField

-(NSSize)intrinsicContentSize
{
    if (![self.cell wraps])
        return [super intrinsicContentSize];
    
    NSRect frame = self.frame;
    
    CGFloat width = frame.size.width;
    
    // Make the frame very high, while keeping the width
    frame.size.height = CGFLOAT_MAX;
    
    // Calculate new height within the frame
    // with practically infinite height.
    CGFloat height = [self.cell cellSizeForBounds: frame].height;
    
    return NSMakeSize(width, height);
}

@end


@implementation IAPopoverViewController

//- Initialisation ---------------------------------------------------------------------------------

@synthesize popover;

- (id)init
{
    if (self = [super initWithNibName:self.className bundle:nil])
    {
    }
    return self;
}

- (void)dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

//- General Functions ------------------------------------------------------------------------------

- (void)showHeading:(NSString*)heading
         andMessage:(NSString*)message
          belowView:(NSView*)view
{
    self.popover.animates = YES;
    self.popover.contentViewController.view = self.view;
    self.heading.stringValue = heading;
    self.message.stringValue = message;
    self.popover.appearance = NSPopoverAppearanceHUD;
    [self.popover showRelativeToRect:view.frame ofView:view preferredEdge:NSMinYEdge];
    [self.view layoutSubtreeIfNeeded];
    self.popover.contentSize = self.view.frame.size;
    [self performSelector:@selector(hidePopover) withObject:Nil afterDelay:3.0];
}

- (void)hidePopover
{
    [self.popover close];
}

//- Click Handling ---------------------------------------------------------------------------------

- (void)mouseDown:(NSEvent*)theEvent
{
    [self hidePopover];
}

@end
