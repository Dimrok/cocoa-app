//
//  IAPopoverViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 9/30/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol IAPopoverViewProtocol;

@interface IAPopoverViewController : NSViewController <NSPopoverDelegate>

@property (nonatomic, strong) IBOutlet NSTextField* heading;
@property (nonatomic, strong) IBOutlet NSButton* left_button;
@property (nonatomic, strong) IBOutlet NSButton* middle_button;
@property (nonatomic, strong) IBOutlet NSTextField* message;
@property (nonatomic, strong) IBOutlet NSButton* right_button;
@property (nonatomic, strong) IBOutlet NSPopover* popover;

- (id)initWithDelegate:(id<IAPopoverViewProtocol>)delegate;

- (void)showHeading:(NSString*)heading
         andMessage:(NSString*)message
         leftButton:(NSString*)left_button
      midddleButton:(NSString*)middle_button
        rightButton:(NSString*)right_button
          belowView:(NSView*)view;

- (void)hidePopover;

@end

@protocol IAPopoverViewProtocol <NSObject>

- (void)popoverHadMiddleButtonClicked:(IAPopoverViewController*)sender;
- (void)popoverHadLeftButtonClicked:(IAPopoverViewController*)sender;
- (void)popoverHadRightButtonClicked:(IAPopoverViewController*)sender;

@end