//
//  IAStatusBarIcon.h
//  InfinitApplication
//
//  Created by Christopher Crone on 7/26/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//
//  This view is simply the icon in the status bar.

#import <Cocoa/Cocoa.h>

#import <surface/gap/enums.hh>

@protocol IAStatusBarIconProtocol;

@interface IAStatusBarIcon : NSView <NSDraggingDestination>

@property (nonatomic, readwrite, setter = setFire:) BOOL isFire;
@property (nonatomic, readwrite, setter = setHighlighted:) BOOL isHighlighted;
@property (nonatomic, readwrite, setter = setLoggingIn:) BOOL isLoggingIn;
@property (nonatomic, readwrite, setter = setTransferring:) BOOL isTransferring;
@property (nonatomic, readonly) BOOL show_link;

- (id)initWithDelegate:(id <IAStatusBarIconProtocol>)delegate
            statusItem:(NSStatusItem*)status_item;

- (void)setConnected:(gap_UserStatus)connected;

- (void)setNumberOfItems:(NSInteger)number_of_items;

@end


@protocol IAStatusBarIconProtocol <NSObject>

- (void)statusBarIconClicked:(id)sender;
- (void)statusBarIconDragDrop:(IAStatusBarIcon*)sender
                    withFiles:(NSArray*)files;
- (void)statusBarIconLinkDrop:(IAStatusBarIcon*)sender
                    withFiles:(NSArray*)files;
- (void)statusBarIconDragEntered:(IAStatusBarIcon*)sender;

@end