//
//  IANotificationListViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 7/31/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//
//  This view controller is the main application view and is responsible for showing current
//  notifications and a history of transactions.

#import <Cocoa/Cocoa.h>

#import "IAViewController.h"

@protocol IANotificationListViewProtocol;

@interface IANotificationListViewController : IAViewController

@property (nonatomic, retain) IBOutlet IAFooterView* footer_view;
@property (nonatomic, strong) IBOutlet NSButton* gear_button;
@property (nonatomic, strong) IBOutlet NSMenu* gear_menu;
@property (nonatomic, strong) IBOutlet NSImageView* header_image;
@property (nonatomic, retain) IBOutlet IAHeaderView* header_view;
@property (nonatomic, retain) IBOutlet IAMainView* main_view;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* main_view_height_constraint;
@property (nonatomic, strong) IBOutlet NSTextField* no_data_message;
@property (nonatomic, strong) IBOutlet NSButton* transfer_button;
@property (nonatomic, strong) IBOutlet NSTableView* table_view;
@property (nonatomic, strong) IBOutlet NSMenuItem* version_item;

- (id)initWithDelegate:(id<IANotificationListViewProtocol>)delegate;

@end

@protocol IANotificationListViewProtocol <NSObject>

- (void)notificationListGotTransferClick:(IANotificationListViewController*)sender;
- (void)notificationListWantsQuit:(IANotificationListViewController*)sender;

// XXX This will need to change to a group when the functionality is available
- (void)notificationList:(IANotificationListViewController*)sender
         gotClickOnUser:(IAUser*)user;

- (NSArray*)notificationListWantsLastTransactions:(IANotificationListViewController*)sender;

@end
