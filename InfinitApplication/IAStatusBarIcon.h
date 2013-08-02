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

@interface IAStatusBarIcon : NSView
{
@private
    id _delegate;
    NSImage* _icon[2];
    BOOL _is_highlighted;
    NSImageView* _icon_view;
    NSArray* _drag_types;
}

@property (nonatomic, readonly) BOOL isHighlighted;

- (id)initWithDelegate:(id <IAStatusBarIconProtocol>)delegate statusItem:(NSStatusItem*)status_item;
- (void)setHighlighted:(BOOL)is_highlighted;

@end


@protocol IAStatusBarIconProtocol <NSObject>

- (void)statusBarIconClicked:(IAStatusBarIcon*)status_bar_icon;
- (void)statusBarIconDragEntered:(IAStatusBarIcon*)status_bar_icon;

@end