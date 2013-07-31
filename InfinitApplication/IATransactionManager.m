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
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(onTransactionNotification:)
                                                   name:IA_GAP_EVENT_TRANSACTION_NOTIFICATION
                                                 object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(onNotificationsRead:)
                                                   name:IA_GAP_EVENT_TRANSACTION_READ_NOTIFICATION
                                                 object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(onGapError:)
                                                   name:IA_GAP_EVENT_ERROR
                                                 object:nil];
    }
    return self;
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (NSString*)description
{
    return @"[TransactionManager]";
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
    if (transaction_id == nil)
        return nil;
    IATransaction* transaction = [IATransaction transactionWithId:transaction_id];
    transaction.is_new = ((NSNumber*)[dict objectForKey:@"is_new"]).boolValue;
    return transaction;
}

- (IATransactionViewMode)modeForTransaction:(IATransaction*)transaction
{
}

//- Transaction Manipulation -----------------------------------------------------------------------


//- User Handling ----------------------------------------------------------------------------------

- (NSArray*)transactionsForUserId:(NSString*)user_id
{
    NSMutableArray* transactions = [[NSMutableArray alloc] init];
    for (IATransaction* transaction in _transactions)
    {
        if ([transaction.sender_id isEqualToString:user_id] ||
            [transaction.recipient_id isEqualToString:user_id])
        {
            [transactions addObject:transaction];
        }
    }
    return [NSArray arrayWithArray:transactions];
}

//- Gap Message Handling ---------------------------------------------------------------------------

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

- (void)onGapError:(NSNotification*)notification
{
    NSDictionary* dict = notification.userInfo;
    gap_Status error_code = ((NSNumber*)[dict valueForKey:@"error_code"]).intValue;
    NSString* error_reason = [dict valueForKey:@"reason"];
    IATransaction* transaction = [self transactionFromNotification:notification];
    IALog(@"%@ Error (%d: %@) for transaction %@(", self, error_code, error_reason, transaction);
}

- (void)onNotificationsRead:(NSNotification*)notification
{
    for (IATransaction* transaction in _transactions)
        transaction.is_new = NO;
}

@end
