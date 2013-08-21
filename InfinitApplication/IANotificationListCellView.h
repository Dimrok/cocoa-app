//
//  IANotificationListCellView.h
//  InfinitApplication
//
//  Created by Christopher Crone on 8/9/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IAAvatarBadgeView.h"

@interface IANotificationListCellView : NSTableCellView

@property (nonatomic, strong) IBOutlet NSImageView* avatar;
@property (nonatomic, strong) IBOutlet IAAvatarBadgeView* badge_view;
@property (nonatomic, strong) IBOutlet NSTextField* file_name;
@property (nonatomic, strong) IBOutlet NSTextField* time_since_change;
@property (nonatomic, strong) IBOutlet NSImageView* transfer_status;
@property (nonatomic, strong) IBOutlet NSTextField* user_full_name;
@property (nonatomic, strong) IBOutlet NSImageView* user_online;

- (void)setupCellWithTransaction:(IATransaction*)transaction
          andRunningTransactions:(NSUInteger)count;

- (void)setBadgeCount:(NSUInteger)count;

@end
