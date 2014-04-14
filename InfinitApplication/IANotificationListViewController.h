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
#import "IANotificationListCellView.h"
#import "InfinitNotificationListRowView.h"
#import "InfinitOnboardingController.h"

#import <surface/gap/enums.hh>

@protocol IANotificationListViewProtocol;

@interface IANotificationListViewController : IAViewController <IANotificationListCellProtocol,
                                                                InfinitNotificationListRowProtocol>

@property (nonatomic, retain) IBOutlet NSMenuItem* auto_start_toggle;
@property (nonatomic, retain) IBOutlet IAFooterView* footer_view;
@property (nonatomic, strong) IBOutlet NSButton* gear_button;
@property (nonatomic, strong) IBOutlet NSMenu* gear_menu;
@property (nonatomic, strong) IBOutlet NSImageView* header_image;
@property (nonatomic, retain) IBOutlet IAHeaderView* header_view;
@property (nonatomic, retain) IBOutlet IAMainView* main_view;
@property (nonatomic, strong) IBOutlet NSTextField* no_data_message;
@property (nonatomic, strong) IBOutlet NSButton* transfer_button;
@property (nonatomic, strong) IBOutlet NSTableView* table_view;
@property (nonatomic, strong) IBOutlet NSMenuItem* version_item;

- (id)initWithDelegate:(id<IANotificationListViewProtocol>)delegate
   andConnectionStatus:(gap_UserStatus)connection_status;

- (void)setConnected:(gap_UserStatus)connection_status;

@end

@protocol IANotificationListViewProtocol <IAViewProtocol>

- (void)notificationListGotTransferClick:(IANotificationListViewController*)sender;
- (void)notificationListWantsQuit:(IANotificationListViewController*)sender;

// XXX This will need to change to a group when the functionality is available
- (void)notificationList:(IANotificationListViewController*)sender
         gotClickOnUser:(IAUser*)user;

- (NSArray*)notificationListWantsLastTransactions:(IANotificationListViewController*)sender;

- (void)notificationList:(IANotificationListViewController*)sender
wantsMarkTransactionRead:(IATransaction*)transaction;

- (NSUInteger)notificationList:(IANotificationListViewController*)sender
 needActionTransactionsForUser:(IAUser*)user;

- (NSUInteger)notificationList:(IANotificationListViewController*)sender
    notDoneTransactionsForUser:(IAUser*)user;

- (NSUInteger)notificationList:(IANotificationListViewController*)sender
     activeTransactionsForUser:(IAUser*)user;

- (NSUInteger)notificationList:(IANotificationListViewController*)sender
     unreadTransactionsForUser:(IAUser*)user;

- (BOOL)notificationList:(IANotificationListViewController*)sender
transferringTransactionsForUser:(IAUser*)user;

- (CGFloat)notificationList:(IANotificationListViewController*)sender
transactionsProgressForUser:(IAUser*)user;

- (void)notificationList:(IANotificationListViewController*)sender
       acceptTransaction:(IATransaction*)transaction;

- (void)notificationList:(IANotificationListViewController*)sender
       cancelTransaction:(IATransaction*)transaction;

- (void)notificationList:(IANotificationListViewController*)sender
       rejectTransaction:(IATransaction*)transaction;

- (void)notificationListWantsReportProblem:(IANotificationListViewController*)sender;

- (void)notificationListWantsCheckForUpdate:(IANotificationListViewController*)sender;

- (void)notificationListWantsLogout:(IANotificationListViewController*)sender;

- (BOOL)notificationListWantsAutoStartStatus:(IANotificationListViewController*)sender;

- (void)notificationList:(IANotificationListViewController*)sender
            setAutoStart:(BOOL)state;

- (IATransaction*)receiveOnboardingTransaction:(IAViewController*)sender;
- (IATransaction*)sendOnboardingTransaction:(IAViewController*)sender;

@end
