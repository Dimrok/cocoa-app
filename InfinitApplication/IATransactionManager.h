//
//  IATransactionManager.h
//  InfinitApplication
//
//  Created by Christopher Crone on 7/30/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//
//  This manager is responsible for handling transactions. This means that it handles remote
//  changes to transaction state through gap, local user interactions with transactions (accept,
//  send, cancel, etc.), as well as setting the current view mode of each transaction.

#import <Foundation/Foundation.h>

#import <Gap/IATransaction.h>

@protocol IATransactionManagerProtocol;

@interface IATransactionManager : NSObject

@property (atomic, readonly) NSArray* transactions;

- (id)initWithDelegate:(id<IATransactionManagerProtocol>)delegate;

- (void)getHistory;

- (NSArray*)transactionsForUser:(IAUser*)user;

- (NSUInteger)activeAndUnreadTransactionsForUser:(IAUser*)user;

- (NSUInteger)totalUntreatedAndUnreadTransactions;

- (void)markTransactionsRead;

- (BOOL)transferringTransactionsForUser:(IAUser*)user;

- (CGFloat)transactionsProgressForUser:(IAUser*)user;

- (NSArray*)latestTransactionPerUser;

- (void)sendFiles:(NSArray*)files
          toUsers:(NSArray*)users
      withMessage:(NSString*)message;

- (void)acceptTransaction:(IATransaction*)transaction;

- (void)cancelTransaction:(IATransaction*)transaction;

- (void)rejectTransaction:(IATransaction*)transaction;

@end


@protocol IATransactionManagerProtocol <NSObject>

- (void)transactionManager:(IATransactionManager*)sender
          transactionAdded:(IATransaction*)transaction;
- (void)transactionManager:(IATransactionManager*)sender
        transactionUpdated:(IATransaction*)transaction;

- (void)transactionManagerHasGotHistory:(IATransactionManager*)sender;

@end