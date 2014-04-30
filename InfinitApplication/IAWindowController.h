//
//  IAWindowController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 8/1/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//
//  This class is designed to handle all window operations, such as: opening the window, closing the
//  winodw and switching between views when it is open. It does not decide which views to show, it
//  is only passed them. It takes IAViewController which are made up of views containing a header,
//  main view and footer view.

#import <Cocoa/Cocoa.h>

#import "IAViewController.h"

@class IANotificationWindow;

@protocol IAWindowControllerProtocol;
@protocol IANotificationWindowProtocol;

@interface IAWindowController : NSWindowController <NSWindowDelegate,
                                                    IANotificationWindowProtocol>

@property (atomic, readwrite) BOOL windowIsOpen;

- (id)initWithDelegate:(id<IAWindowControllerProtocol>)delegate;

- (void)closeWindow;

- (void)closeWindowWithAnimation:(BOOL)animate;

- (void)changeToViewController:(IAViewController*)new_controller;

- (void)openWithViewController:(IAViewController*)controller
                  withMidpoint:(NSPoint)midpoint;

@end

@protocol IAWindowControllerProtocol <NSObject>

- (void)windowControllerWantsCloseWindow:(IAWindowController*)sender;

- (void)windowController:(IAWindowController*)sender
hasCurrentViewController:(IAViewController*)controller;

@end
