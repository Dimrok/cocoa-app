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

- (void)getHistory
{
    NSArray* transaction_ids = [IAGapState.instance getTransactionList];
    for (NSNumber* transaction_id in transaction_ids)
    {
        IATransaction* transaction = [IATransaction
                                      transactionWithId:transaction_id
                                              andStatus:[[IAGapState instance]
                                                         getStatusForTransaction:transaction_id]];
        transaction.view_mode = [self transactionViewMode:transaction];
        [_transactions addObject:transaction];
    }
}

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
    if (transaction_id.unsignedIntegerValue == gap_null())
    {
        IALog(@"%@ WARNING: transaction from notification failed, no id", self);
        return nil;
    }
    NSNumber* status = [dict objectForKey:@"status"];
    if (status.intValue == 0)
    {
        IALog(@"%@ WARNING: transaction from notification failed, no status", self);
        return nil;
    }
    IATransaction* transaction = [IATransaction transactionWithId:transaction_id
                                                        andStatus:status];
    return transaction;
}

- (void)sendFiles:(NSArray*)files
          toUsers:(NSArray*)users
      withMessage:(NSString*)message
{
    for (id user in users)
    {
        if ([user isKindOfClass:IAUser.class])
        {
            NSNumber* result = [[IAGapState instance] sendFiles:files
                                                        toUser:user
                                                   withMessage:message];
            if (result.unsignedIntValue == gap_null())
            {
                // XXX Handle send to user error
                IALog(@"%@ ERROR: Unable to send to user (%@): %@", self, user, files);
            }
        }
        else if ([user isKindOfClass:NSString.class] && [IAFunctions stringIsValidEmail:user])
        {
            NSNumber* result = [[IAGapState instance] sendFiles:files
                                                        toEmail:user
                                                    withMessage:message];
            if (result.unsignedIntValue == gap_null())
            {
                // XXX Handle send to email error
                IALog(@"%@ ERROR: Unable to send to email (%@): %@", self, user, files);
            }
        }
    }
}

- (void)acceptTransaction:(IATransaction*)transaction
{
    NSNumber* result = [[IAGapState instance] acceptTransaction:transaction];
    if (result.unsignedIntValue == gap_null())
    {
        // XXX Handle accept error
        IALog(@"%@ ERROR: Unable to send to accept transaction: %@", self, transaction);
    }
}

- (void)cancelTransaction:(IATransaction*)transaction
{
    NSNumber* result = [[IAGapState instance] cancelTransaction:transaction];
    if (result.unsignedIntValue == gap_null())
    {
        // XXX Handle cancel error
        IALog(@"%@ ERROR: Unable to send to cancel transaction: %@", self, transaction);
    }
}

- (void)rejectTransaction:(IATransaction*)transaction
{
    NSNumber* result = [[IAGapState instance] rejectTransaction:transaction];
    if (result.unsignedIntValue == gap_null())
    {
        // XXX Handle reject error
        IALog(@"%@ ERROR: Unable to send to reject transaction: %@", self, transaction);
    }
}

//- Transaction View Mode Handling -----------------------------------------------------------------


//    gap_transaction_none,
//    gap_transaction_pending,
//    gap_transaction_copying,
//    gap_transaction_waiting_for_accept,
//    gap_transaction_accepted,
//    gap_transaction_preparing,
//    gap_transaction_running,
//    gap_transaction_cleaning,
//    gap_transaction_finished,
//    gap_transaction_failed,
//    gap_transaction_canceled,
//    gap_transaction_rejected,


- (IATransactionViewMode)transactionViewMode:(IATransaction*)transaction
{
    switch (transaction.status)
    {            
        case gap_transaction_pending:
            return TRANSACTION_VIEW_PENDING_SEND;
            
        case gap_transaction_copying:
            if (transaction.recipient.is_ghost)
                return TRANSACTION_VIEW_WAITING_REGISTER;
            else if (transaction.recipient.status != gap_user_status_online)
                return TRANSACTION_VIEW_WAITING_ONLINE;
            else
                return TRANSACTION_VIEW_WAITING_ACCEPT;
            
        case gap_transaction_waiting_for_accept:
            if (transaction.recipient.is_ghost)
                return TRANSACTION_VIEW_WAITING_REGISTER;
            else if (transaction.recipient.status != gap_user_status_online)
                return TRANSACTION_VIEW_WAITING_ONLINE;
            else
                return TRANSACTION_VIEW_WAITING_ACCEPT;
            
        case gap_transaction_preparing:
            return TRANSACTION_VIEW_PREPARING;
            
        case gap_transaction_running:
            return TRANSACTION_VIEW_RUNNING;
            
        case gap_transaction_cleaning:
            return transaction.view_mode;
            
        case gap_transaction_finished:
            return TRANSACTION_VIEW_FINISHED;
            
        case gap_transaction_rejected:
            return TRANSACTION_VIEW_REJECTED;
            
        case gap_transaction_canceled: // Must include logic to say who cancelled transaction
            return TRANSACTION_VIEW_CANCELLED_SELF;
        
        case gap_transaction_failed:
            return TRANSACTION_VIEW_FAILED;
            
        default:
            return TRANSACTION_VIEW_NONE;
    }
}

//- Transaction Lists ------------------------------------------------------------------------------

- (NSUInteger)totalUntreatedAndUnreadTransactions
{
    NSUInteger res = 0;
    for (IATransaction* transaction in _transactions)
    {
        if (transaction.is_new || transaction.needs_action)
            res++;
    }
    return res;
}

- (void)markTransactionsRead
{
    for (IATransaction* transaction in _transactions)
        transaction.is_new = NO;
}

- (NSArray*)latestTransactionPerUser
{
    NSSortDescriptor* descending = [NSSortDescriptor sortDescriptorWithKey:nil
                                                                 ascending:NO
                                                                  selector:@selector(compare:)];
    NSArray* sorted_transactions = [_transactions sortedArrayUsingDescriptors:
                                    [NSArray arrayWithObject:descending]];
    NSMutableArray* res = [NSMutableArray array];
    NSMutableArray* users = [NSMutableArray array];
    for (IATransaction* transaction in sorted_transactions)
    {
        if (transaction.from_me)
        {
            if (![users containsObject:transaction.recipient])
            {
                [users addObject:transaction.recipient];
                [res addObject:transaction];
            }
        }
        else
        {
            if (![users containsObject:transaction.sender])
            {
                [users addObject:transaction.sender];
                [res addObject:transaction];
            }
        }
    }
    return res;
}

- (NSArray*)transactionsForUser:(IAUser*)user
{
    NSMutableArray* transactions = [NSMutableArray array];
    for (IATransaction* transaction in _transactions)
    {
        if ([transaction.sender isEqual:user] ||
            [transaction.recipient isEqual:user])
        {
            [transactions addObject:transaction];
        }
    }
    return [NSArray arrayWithArray:transactions];
}

- (NSUInteger)activeAndUnreadTransactionsForUser:(IAUser*)user
{
    NSArray* transactions = [NSArray arrayWithArray:[self transactionsForUser:user]];
    NSUInteger res = 0;
    for (IATransaction* transaction in transactions)
    {
        if (transaction.is_active || transaction.needs_action)
            res++;
    }
    return res;
}

- (BOOL)transferringTransactionsForUser:(IAUser*)user
{
    NSArray* transactions = [NSArray arrayWithArray:[self transactionsForUser:user]];
    for (IATransaction* transaction in transactions)
    {
        if (transaction.view_mode == TRANSACTION_VIEW_RUNNING)
            return YES;
    }
    return NO;
}

- (CGFloat)transactionsProgressForUser:(IAUser*)user
{
    NSArray* transactions = [NSArray arrayWithArray:[self transactionsForUser:user]];
    CGFloat total = 0.0;
    CGFloat transferred = 0.0;
    for (IATransaction* transaction in transactions)
    {
        if (transaction.view_mode == TRANSACTION_VIEW_RUNNING)
        {
            total += transaction.total_size.doubleValue;
            transferred += (transaction.progress * transaction.total_size.doubleValue);
        }
    }
    return (transferred / total);
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
        if (index == -1) // Transaction is new
        {
            transaction.view_mode = [self transactionViewMode:transaction];
            transaction.is_new = YES;
            [_transactions insertObject:transaction atIndex:0];
            [_delegate transactionManager:self transactionAdded:transaction];
        }
        else // Transaction already in list
        {
            // Only update if view move changes
            if (transaction.view_mode != [self transactionViewMode:transaction])
            {
                transaction.view_mode = [self transactionViewMode:transaction];
                transaction.is_new = YES;
                [_transactions replaceObjectAtIndex:index withObject:transaction];
                [_delegate transactionManager:self transactionUpdated:transaction];
            }
        }
    }
}

// XXX currently unimplemented
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
    {
        if (!transaction.from_me && !transaction.view_mode == TRANSACTION_VIEW_WAITING_ACCEPT)
            transaction.is_new = NO;
    }
}

@end
