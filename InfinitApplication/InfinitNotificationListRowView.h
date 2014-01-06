//
//  InfinitNotificationListRowView.h
//  InfinitApplication
//
//  Created by Christopher Crone on 06/01/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol InfinitNotificationListRowProtocol;

@interface InfinitNotificationListRowView : NSTableRowView

@property (nonatomic, readwrite, setter = setClicked:) BOOL clicked;
@property (nonatomic, readwrite, setter = setHovered:) BOOL hovered;
@property (nonatomic, readwrite, setter = setUnread:) BOOL unread;

- (id)initWithFrame:(NSRect)frameRect
        andDelegate:(id<InfinitNotificationListRowProtocol>)delegate;

@end

@protocol InfinitNotificationListRowProtocol <NSObject>

- (void)notificationRowHoverChanged:(InfinitNotificationListRowView*)sender;

@end
