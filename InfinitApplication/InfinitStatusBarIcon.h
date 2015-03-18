//
//  InfinitStatusBarIcon.h
//  InfinitApplication
//
//  Created by Christopher Crone on 02/09/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol InfinitStatusBarIconProtocol;
@protocol InfinitStatusBarDragDropProtocol;

@interface InfinitStatusBarIcon : NSObject <NSDraggingDestination, NSWindowDelegate>

@property (nonatomic, readonly) NSRect frame;
@property (nonatomic, readwrite) BOOL hidden;
@property (nonatomic, readwrite) BOOL open;
@property (nonatomic, readonly) NSView* view;

- (id)initWithDelegate:(id<InfinitStatusBarIconProtocol>)delegate;

@end


@protocol InfinitStatusBarIconProtocol <NSObject>

- (void)statusBarIconClicked:(id)sender;

- (void)statusBarIconDragDrop:(id)sender
                    withFiles:(NSArray*)files;

- (void)statusBarIconDragEntered:(id)sender;

@end
