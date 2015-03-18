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

@property (nonatomic, readwrite, setter = setHighlighted:) BOOL isHighlighted;
@property (nonatomic, readonly) BOOL show_link;

- (id)initWithDelegate:(id <IAStatusBarIconProtocol>)delegate
            statusItem:(NSStatusItem*)status_item;

@end


@protocol IAStatusBarIconProtocol <NSObject>

- (void)statusBarIconClicked:(id)sender;
- (void)statusBarIconDragDrop:(IAStatusBarIcon*)sender
                    withFiles:(NSArray*)files;
- (void)statusBarIconLinkDrop:(IAStatusBarIcon*)sender
                    withFiles:(NSArray*)files;
- (void)statusBarIconDragEntered:(IAStatusBarIcon*)sender;

@end