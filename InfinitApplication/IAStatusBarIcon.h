//
//  IAStatusBarIcon.h
//  InfinitApplication
//
//  Created by Christopher Crone on 7/26/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//
//  This view is simply the icon in the status bar.

#import <Cocoa/Cocoa.h>

@protocol IAStatusBarIconProtocol;

@interface IAStatusBarIcon : NSView <NSDraggingDestination>

@property (nonatomic, readwrite) BOOL isClickable;
@property (nonatomic, readonly) BOOL isHighlighted;

- (id)initWithDelegate:(id <IAStatusBarIconProtocol>)delegate statusItem:(NSStatusItem*)status_item;

- (void)setConnected:(gap_UserStatus)connected;

- (void)setHighlighted:(BOOL)is_highlighted;

- (void)setNumberOfItems:(NSInteger)number_of_items;

- (void)startPulse;

- (void)stopPulse;

@end


@protocol IAStatusBarIconProtocol <NSObject>

- (void)statusBarIconClicked:(IAStatusBarIcon*)sender;
- (void)statusBarIconDragDrop:(IAStatusBarIcon*)sender
                    withFiles:(NSArray*)files;
- (void)statusBarIconDragEntered:(IAStatusBarIcon*)sender;

@end