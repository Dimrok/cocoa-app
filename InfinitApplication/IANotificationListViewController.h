//
//  IANotificationListViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 7/31/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IAViewController.h"

@protocol IANotificationListViewProtocol;

@interface IANotificationListViewController : IAViewController

@property (nonatomic, retain) IBOutlet NSView* footer_view;
@property (nonatomic, strong) IBOutlet NSButton* gear_button;
@property (nonatomic, strong) IBOutlet NSMenu* gear_menu;
@property (nonatomic, retain) IBOutlet NSView* header_view;
@property (nonatomic, strong) IBOutlet NSButton* transfer_button;
@property (nonatomic, strong) IBOutlet NSMenuItem* version_item;
@property (nonatomic, retain) IBOutlet NSView* main_view;

- (id)initWithDelegate:(id<IANotificationListViewProtocol>)delegate;

@end

@protocol IANotificationListViewProtocol <NSObject>

- (void)notificationListGotTransferClick:(IANotificationListViewController*)sender;
- (void)notificationListWantsQuit:(IANotificationListViewController*)sender;

@end
