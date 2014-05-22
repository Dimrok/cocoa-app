//
//  IADesktopNotifier.h
//  InfinitApplication
//
//  Created by Christopher Crone on 8/27/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol IADesktopNotifierProtocol;

@interface IADesktopNotifier : NSObject <NSUserNotificationCenterDelegate>

- (id)initWithDelegate:(id<IADesktopNotifierProtocol>)delegate;

- (void)clearAllNotifications;

- (void)desktopNotificationForTransaction:(IATransaction*)transaction;

- (void)desktopNotificationForLink:(InfinitLinkTransaction*)link;

@end

@protocol IADesktopNotifierProtocol <NSObject>

- (void)desktopNotifier:(IADesktopNotifier*)sender
hadClickNotificationForTransactionId:(NSNumber*)transaction_id;

- (void)desktopNotifier:(IADesktopNotifier*)sender
hadClickNotificationForLinkId:(NSNumber*)transaction_id;

@end