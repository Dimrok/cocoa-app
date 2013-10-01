//
//  IAPopoverViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 9/30/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface IAPopoverViewController : NSViewController <NSPopoverDelegate>

@property (nonatomic, strong) IBOutlet NSTextField* heading;
@property (nonatomic, strong) IBOutlet NSTextField* message;
@property (nonatomic, strong) IBOutlet NSPopover* popover;

- (id)init;

- (void)showHeading:(NSString*)heading
         andMessage:(NSString*)message
          belowView:(NSView*)view;

- (void)hidePopover;

@end