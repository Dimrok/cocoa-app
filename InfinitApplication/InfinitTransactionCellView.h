//
//  InfinitTransactionCellView.h
//  InfinitApplication
//
//  Created by Christopher Crone on 12/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "InfinitAvatarView.h"
#import "InfinitAvatarBadgeView.h"

#import <Gap/InfinitPeerTransaction.h>

@interface InfinitTransactionCellView : NSTableCellView

@property (nonatomic, weak) IBOutlet InfinitAvatarView* avatar_view;
@property (nonatomic, weak) IBOutlet InfinitAvatarBadgeView* badge;
@property (nonatomic, weak) IBOutlet NSTextField* fullname;
@property (nonatomic, weak) IBOutlet NSTextField* information;
@property (nonatomic, weak) IBOutlet NSTextField* indicator_text;
@property (nonatomic, weak) IBOutlet NSImageView* indicator;
@property (nonatomic, weak) IBOutlet NSImageView* user_status;

@property (nonatomic, readwrite) CGFloat progress;

- (void)setupCellWithTransaction:(InfinitPeerTransaction*)transaction
         withRunningTransactions:(NSUInteger)running_transactions
          andNotDoneTransactions:(NSUInteger)not_done_transactions
           andUnreadTransactions:(NSUInteger)unread
                     andProgress:(CGFloat)progress;

- (void)setBadgeCount:(NSUInteger)count;

- (void)loadAvatarImage:(NSImage*)image;

@end
