//
//  InfinitTransactionViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 12/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "InfinitTransactionCellView.h"

@protocol InfinitTransactionViewProtocol;

@interface InfinitTransactionViewController : NSViewController <NSTableViewDelegate,
                                                                NSTableViewDataSource>

@property (nonatomic, strong) IBOutlet NSTableView* table_view;

@property (nonatomic, readwrite) BOOL changing;

- (id)initWithDelegate:(id<InfinitTransactionViewProtocol>)delegate
    andTransactionList:(NSArray*)transaction_list;

- (void)updateModelWithList:(NSArray*)list;

- (void)transactionAdded:(IATransaction*)transaction;
- (void)transactionUpdated:(IATransaction*)transaction;

- (void)userUpdated:(IAUser*)user;

- (CGFloat)height;

- (NSUInteger)unreadRows;

- (void)markTransactionsRead;

@end

@protocol InfinitTransactionViewProtocol <NSObject>

- (void)transactionsViewResizeToHeight:(CGFloat)height;

- (NSUInteger)runningTransactionsForUser:(IAUser*)user;
- (NSUInteger)notDoneTransactionsForUser:(IAUser*)user;
- (NSUInteger)unreadTransactionsForUser:(IAUser*)user;
- (CGFloat)totalProgressForUser:(IAUser*)user;

- (BOOL)transferringTransactionsForUser:(IAUser*)user;

- (void)userGotClicked:(IAUser*)user;

- (void)markTransactionRead:(IATransaction*)transaction;

@end
