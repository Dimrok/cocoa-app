//
//  InfinitLinkShortcutView.h
//  InfinitApplication
//
//  Created by Christopher Crone on 26/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol InfinitLinkShortcutViewProtocol;

@interface InfinitLinkShortcutView : NSView <NSDraggingDestination>

- (id)initWithFrame:(NSRect)frameRect
        andDelegate:(id<InfinitLinkShortcutViewProtocol>)delegate;

@end

@protocol InfinitLinkShortcutViewProtocol <NSObject>

- (void)linkView:(InfinitLinkShortcutView*)sender
             gotFiles:(NSArray*)files;

- (void)linkViewGotDragEnter:(InfinitLinkShortcutView*)sender;
- (void)linkViewGotDragExit:(InfinitLinkShortcutView*)sender;

@end