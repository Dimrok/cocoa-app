//
//  IAWindowController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 8/1/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IAViewController.h"

@protocol IAWindowControllerProtocol;

@interface IAWindowController : NSWindowController <NSWindowDelegate>

@property (nonatomic, readonly) BOOL windowIsOpen;

- (id)initWithDelegate:(id<IAWindowControllerProtocol>)delegate;

- (void)closeWindow;

- (void)changeToViewController:(IAViewController*)controller;

- (void)openWithViewController:(IAViewController*)controller
                  withMidpoint:(NSPoint)midpoint;

@end

@protocol IAWindowControllerProtocol <NSObject>

- (void)windowControllerWantsCloseWindow:(IAWindowController*)sender;

@end
