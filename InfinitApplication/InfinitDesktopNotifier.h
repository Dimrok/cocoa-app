//
//  InfinitDesktopNotifier.h
//  InfinitApplication
//
//  Created by Christopher Crone on 8/27/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Gap/InfinitLinkTransaction.h>
#import <Gap/InfinitPeerTransaction.h>

@protocol InfinitDesktopNotifierProtocol;

@interface InfinitDesktopNotifier : NSObject <NSUserNotificationCenterDelegate>

@property (nonatomic, weak) id<InfinitDesktopNotifierProtocol> delegate;

+ (instancetype)sharedInstance;

- (void)clearAllNotifications;

- (void)desktopNotificationForTransactionAccepted:(InfinitPeerTransaction*)transaction;

- (void)desktopNotificationForLinkCopied:(InfinitLinkTransaction*)link;

- (void)desktopNotificationForApplicationUpdated;

- (void)desktopNotificationForContactJoined:(NSString*)name
                                    details:(NSString*)details;

- (void)checkPendingTransactions;

@end

@protocol InfinitDesktopNotifierProtocol <NSObject>

- (void)desktopNotifier:(InfinitDesktopNotifier*)sender
hadClickNotificationForTransactionId:(NSNumber*)id_;
- (void)desktopNotifier:(InfinitDesktopNotifier*)sender
   hadAcceptTransaction:(NSNumber*)id_;

- (void)desktopNotifier:(InfinitDesktopNotifier*)sender
hadClickNotificationForLinkId:(NSNumber*)id_;

- (void)desktopNotifierHadClickApplicationUpdatedNotification:(InfinitDesktopNotifier*)sender;

@end