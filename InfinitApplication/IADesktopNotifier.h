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

- (void)transactionAdded:(IATransaction*)transaction;

- (void)transactionUpdated:(IATransaction*)transaction;

@end

@protocol IADesktopNotifierProtocol <NSObject>

- (void)desktopNotifier:(IADesktopNotifier*)sender
hadClickNotificationForUserId:(NSNumber*)user_id;

@end