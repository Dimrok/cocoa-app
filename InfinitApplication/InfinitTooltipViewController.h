//
//  InfinitTooltipViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 02/04/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "InfinitSizedTextField.h"
#import "INPopoverController.h"

@interface InfinitTooltipViewController : NSViewController <INPopoverControllerDelegate>

@property (nonatomic, strong) IBOutlet InfinitSizedTextField* message;
@property (nonatomic, readonly) BOOL showing;

- (void)showPopoverForView:(NSView*)view
        withArrowDirection:(INPopoverArrowDirection)direction
               withMessage:(NSString*)message;

- (void)close;

@end
