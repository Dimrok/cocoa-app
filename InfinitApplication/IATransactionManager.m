//
//  IATransactionManager.m
//  InfinitApplication
//
//  Created by Christopher Crone on 7/30/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IATransactionManager.h"

#import <Gap/IAGapState.h>

// UI interaction key
typedef enum __IAUserTransactionAction
{
    USER_TRANSACTION_ACTION_NONE = 0,
    USER_TRANSACTION_ACTION_SEND,
    USER_TRANSACTION_ACTION_PAUSE,
    USER_TRANSACTION_ACTION_ACCEPT,
    USER_TRANSACTION_ACTION_CANCEL
} IAUserTransactionAction;

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

//- General Functions ------------------------------------------------------------------------------

- (NSInteger)indexOfTransactionWithId:(NSNumber*)transaction_id
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
    NSNumber* transaction_id = [dict objectForKey:@"transaction_id"];
    if (transaction_id == nil)
    {
        IALog(@"%@ WARNING: transaction from notification failed, no id", self);
        return nil;
    }
    NSNumber* status = [dict objectForKey:@"status"];
    if (status == nil)
    {
        IALog(@"%@ WARNING: transaction from notification failed, no status", self);
        return nil;
    }
    IATransaction* transaction = [IATransaction transactionWithId:transaction_id andStatus:status];
    transaction.is_new = ((NSNumber*)[dict objectForKey:@"is_new"]).boolValue;
    return transaction;
}

//- Transaction View Mode Machine ------------------------------------------------------------------

//    transaction_view_pending_send = 0,
//    transaction_view_waiting_register,
//    transaction_view_waiting_online,
//    transaction_view_waiting_accept,
//    transaction_view_preparing,
//    transaction_view_running,
//    transaction_view_pause_user,
//    transaction_view_pause_auto,
//    transaction_view_finished,
//    transaction_view_cancelled_self,
//    transaction_view_cancelled_other,
//    transaction_view_failed

- (void)setTransactionViewMode:(IATransaction*)transaction
                 forUserAction:(IAUserTransactionAction)action
{
    
}

//- Transaction Manipulation -----------------------------------------------------------------------


//- User Handling ----------------------------------------------------------------------------------

- (NSArray*)transactionsForUser:(IAUser*)user
{
    NSMutableArray* transactions = [[NSMutableArray alloc] init];
    for (IATransaction* transaction in _transactions)
    {
        if ([transaction.sender_id isEqualToNumber:user.user_id] ||
            [transaction.recipient_id isEqualToNumber:user.user_id])
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
        
        [self setTransactionViewMode:(IATransaction*)transaction
                       forUserAction:USER_TRANSACTION_ACTION_NONE];
        
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

//- User Status Handling ---------------------------------------------------------------------------

- (void)newUserStatusFor:(IAUser*)user
{
    NSArray* user_transactions = [NSArray arrayWithArray:[self transactionsForUser:user]];
    if (user_transactions.count == 0)
        return;
    for (IATransaction* transaction in user_transactions)
    {
        [self setTransactionViewMode:(IATransaction*)transaction
                       forUserAction:USER_TRANSACTION_ACTION_NONE];
    }
}

@end
