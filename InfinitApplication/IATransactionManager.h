//
//  IATransactionManager.h
//  InfinitApplication
//
//  Created by Christopher Crone on 7/30/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Gap/IATransaction.h>

@protocol IATransactionManagerProtocol;

@interface IATransactionManager : NSObject

@property (readonly) NSArray* transactions;

- (id)initWithDelegate:(id<IATransactionManagerProtocol>)delegate;

- (void)setTransaction:(IATransaction*)transaction
              viewMode:(IATransactionViewMode)mode;
- (NSArray*)transactionsForUserId:(NSString*)user_id;

@end


@protocol IATransactionManagerProtocol <NSObject>

- (void)transactionManager:(IATransactionManager*)sender
          transactionAdded:(IATransaction*)transaction;
- (void)transactionManager:(IATransactionManager*)sender
        transactionUpdated:(IATransaction*)transaction;

@end