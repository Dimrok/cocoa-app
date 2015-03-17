//
//  IADesktopNotifier.h
//  InfinitApplication
//
//  Created by Christopher Crone on 8/27/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Gap/InfinitLinkTransaction.h>
#import <Gap/InfinitPeerTransaction.h>

@protocol IADesktopNotifierProtocol;

@interface IADesktopNotifier : NSObject <NSUserNotificationCenterDelegate>

- (id)initWithDelegate:(id<IADesktopNotifierProtocol>)delegate;

- (void)clearAllNotifications;

- (void)desktopNotificationForTransactionAccepted:(InfinitPeerTransaction*)transaction;

- (void)desktopNotificationForLinkCopied:(InfinitLinkTransaction*)link;

- (void)desktopNotificationForApplicationUpdated;

@end

@protocol IADesktopNotifierProtocol <NSObject>

- (void)desktopNotifier:(IADesktopNotifier*)sender
hadClickNotificationForTransactionId:(NSNumber*)id_;
- (void)desktopNotifier:(IADesktopNotifier*)sender
   hadAcceptTransaction:(NSNumber*)id_;

- (void)desktopNotifier:(IADesktopNotifier*)sender
hadClickNotificationForLinkId:(NSNumber*)id_;

- (void)desktopNotifierHadClickApplicationUpdatedNotification:(IADesktopNotifier*)sender;

@end