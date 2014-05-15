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

@interface InfinitTransactionCellView : NSTableCellView

@property (nonatomic, strong) IBOutlet InfinitAvatarView* avatar_view;
@property (nonatomic, strong) IBOutlet InfinitAvatarBadgeView* badge;
@property (nonatomic, strong) IBOutlet NSTextField* fullname;
@property (nonatomic, strong) IBOutlet NSTextField* information;
@property (nonatomic, strong) IBOutlet NSTextField* indicator_text;
@property (nonatomic, strong) IBOutlet NSImageView* indicator;
@property (nonatomic, strong) IBOutlet NSImageView* user_status;

@property (nonatomic, readwrite) CGFloat progress;

- (void)setupCellWithTransaction:(IATransaction*)transaction
         withRunningTransactions:(NSUInteger)running_transactions
          andNotDoneTransactions:(NSUInteger)not_done_transactions
           andUnreadTransactions:(NSUInteger)unread
                     andProgress:(CGFloat)progress;

- (void)setBadgeCount:(NSUInteger)count;

- (void)loadAvatarImage:(NSImage*)image;

@end
