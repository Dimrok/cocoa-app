//
//  IATransactionManager.m
//  InfinitApplication
//
//  Created by Christopher Crone on 7/30/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IATransactionManager.h"

#import <Gap/IAGapState.h>

@implementation IATransactionManager
{
@private
    id<IATransactionManagerProtocol> _delegate;
    NSMutableArray* _transactions;
}

//- Initialisation ---------------------------------------------------------------------------------

@synthesize transactions = _transactions;

- (id)initWithDelegate:(id<IATransactionManagerProtocol>)delegate
{
    if (self = [super init])
    {
        _delegate = delegate;
        _transactions = [NSMutableArray array];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onTransactionNotification:)
                                                     name:IA_GAP_EVENT_TRANSACTION_NOTIFICATION
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onNotificationsRead:)
                                                     name:IA_GAP_EVENT_TRANSACTION_READ_NOTIFICATION
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

//- General Functions ------------------------------------------------------------------------------

- (NSInteger)indexOfTransactionWithId:(NSString*)transaction_id
{
    NSInteger count = 0;
    for (IATransaction* transaction in _transactions)
    {
        if (transaction.transaction_id == transaction_id)
            return count;
        else
            count++;
    }
    return -1; // transaction not found
}

- (IATransaction*)transactionFromNotification:(NSNotification*)notification
{
    NSDictionary* dict = notification.userInfo;
    NSString* transaction_id = [dict objectForKey:@"transaction_id"];
    IATransaction* transaction = [IATransaction transactionWithId:transaction_id];
    transaction.is_new = ((NSNumber*)[dict objectForKey:@"is_new"]).boolValue;
    return transaction;
}

//- Transaction Handling ---------------------------------------------------------------------------

- (void)onTransactionNotification:(NSNotification*)notification
{
    @synchronized(_transactions)
    {
        IATransaction* transaction = [self transactionFromNotification:notification];
        if (transaction == nil)
            return;
        
        NSInteger index = [self indexOfTransactionWithId:transaction.transaction_id];
        if (index == -1) // transaction is new
        {
            [_transactions insertObject:transaction atIndex:0];
            [_delegate transactionManager:self transactionAdded:transaction];
        }
        else // transaction needs to be updated
        {
            [_transactions replaceObjectAtIndex:index withObject:transaction];
            [_delegate transactionManager:self transactionUpdated:transaction];
        }
    }
}

@end
