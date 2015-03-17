//
//  InfinitTransactionViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 12/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "InfinitTransactionCellView.h"

#import <Gap/InfinitPeerTransaction.h>
#import <Gap/InfinitUser.h>

@protocol InfinitTransactionViewProtocol;

@interface InfinitTransactionViewController : NSViewController <NSTableViewDelegate,
                                                                NSTableViewDataSource>

@property (nonatomic, weak) IBOutlet NSTableView* table_view;

@property (nonatomic, readwrite) BOOL changing;

- (id)initWithDelegate:(id<InfinitTransactionViewProtocol>)delegate;

- (void)updateModel;

- (void)transactionAdded:(InfinitPeerTransaction*)transaction;
- (void)transactionUpdated:(InfinitPeerTransaction*)transaction;

- (void)userUpdated:(InfinitUser*)user;

- (CGFloat)height;

- (NSUInteger)unreadRows;

- (void)markTransactionsRead;

- (void)closeToolTips;

@end

@protocol InfinitTransactionViewProtocol <NSObject>

- (void)transactionsViewResizeToHeight:(CGFloat)height;

- (void)userGotClicked:(InfinitUser*)user;

//- Onboarding -------------------------------------------------------------------------------------

- (InfinitPeerTransaction*)receiveOnboardingTransaction:(InfinitTransactionViewController*)sender;
- (InfinitPeerTransaction*)sendOnboardingTransaction:(InfinitTransactionViewController*)sender;

@end
