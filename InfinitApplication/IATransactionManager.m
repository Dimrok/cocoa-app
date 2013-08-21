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
    return transaction;
}

- (void)sendFiles:(NSArray*)files
          toUsers:(NSArray*)users
{
    for (id user in users)
    {
        if ([user isKindOfClass:IAUser.class])
        {
            [[IAGapState instance] sendFiles:files toUser:user]; // XXX returns transaction id
        }
        else if ([user isKindOfClass:NSString.class] && [IAFunctions stringIsValidEmail:user])
        {
            [[IAGapState instance] sendFiles:files toEmail:user]; // XXX returns transaction id
        }
    }
}

//- Transaction View Mode Handling -----------------------------------------------------------------

// View modes:
//    TRANSACTION_VIEW_NONE = 0,
//    TRANSACTION_VIEW_PENDING_SEND = 1,
//    TRANSACTION_VIEW_WAITING_REGISTER = 2,
//    TRANSACTION_VIEW_WAITING_ONLINE = 3,
//    TRANSACTION_VIEW_WAITING_ACCEPT = 4,
//    TRANSACTION_VIEW_PREPARING = 5,
//    TRANSACTION_VIEW_RUNNING = 6,
//    TRANSACTION_VIEW_PAUSE_USER = 7,
//    TRANSACTION_VIEW_PAUSE_AUTO = 8,
//    TRANSACTION_VIEW_REJECTED = 9,
//    TRANSACTION_VIEW_FINISHED = 10,
//    TRANSACTION_VIEW_CANCELLED_SELF = 11,
//    TRANSACTION_VIEW_CANCELLED_OTHER = 12,
//    TRANSACTION_VIEW_FAILED = 13

// Transaction states:
//    TransferState_NewTransaction = 0,
//    TransferState_SenderCreateNetwork = 1,
//    TransferState_SenderCreateTransaction = 2,
//    TransferState_SenderCopyFiles = 3,
//    TransferState_SenderWaitForDecision = 4,
//    TransferState_RecipientWaitForDecision = 5,
//    TransferState_RecipientAccepted = 6,
//    TransferState_GrantPermissions = 7,
//    TransferState_PublishInterfaces = 8,
//    TransferState_Connect = 9,
//    TransferState_PeerDisconnected = 10,
//    TransferState_PeerConnectionLost = 11,
//    TransferState_Transfer = 12,
//    TransferState_CleanLocal = 13,
//    TransferState_CleanRemote = 14,
//    TransferState_Finished = 15,
//    TransferState_Rejected = 16,
//    TransferState_Canceled = 17,
//    TransferState_Failed = 18,

- (IATransactionViewMode)transactionViewMode:(IATransaction*)transaction
{
    switch (transaction.status)
    {
        case TransferState_NewTransaction:
            return TRANSACTION_VIEW_NONE;
            
        case TransferState_SenderCreateNetwork:
            return TRANSACTION_VIEW_PENDING_SEND;
            
        case TransferState_SenderCreateTransaction:
            return TRANSACTION_VIEW_PENDING_SEND;
            
        case TransferState_SenderCopyFiles:
            return TRANSACTION_VIEW_PENDING_SEND;
            
        case TransferState_SenderWaitForDecision:
            if (transaction.recipient.is_ghost)
                return TRANSACTION_VIEW_WAITING_REGISTER;
            else if (transaction.recipient.status != gap_user_status_online)
                return TRANSACTION_VIEW_WAITING_ONLINE;
            else
                return TRANSACTION_VIEW_WAITING_ACCEPT;
            
        case TransferState_RecipientWaitForDecision:
            return TRANSACTION_VIEW_WAITING_ACCEPT;
            
        case TransferState_RecipientAccepted:
            return TRANSACTION_VIEW_PREPARING;
            
        case TransferState_GrantPermissions:
            return TRANSACTION_VIEW_PREPARING;
            
        case TransferState_PublishInterfaces:
            return TRANSACTION_VIEW_PREPARING;
            
        case TransferState_Connect:
            return TRANSACTION_VIEW_PREPARING;
            
        case TransferState_PeerDisconnected: // XXX Currently will restart transfer
            return TRANSACTION_VIEW_PAUSE_AUTO;
            
        case TransferState_PeerConnectionLost: // XXX Currently will restart transfer
            return TRANSACTION_VIEW_PAUSE_AUTO;
            
        case TransferState_Transfer:
            return TRANSACTION_VIEW_RUNNING;
            
        case TransferState_CleanLocal:
            return transaction.view_mode;
            
        case TransferState_CleanRemote:
            return transaction.view_mode;
            
        case TransferState_Finished:
            return TRANSACTION_VIEW_FINISHED;
            
        case TransferState_Rejected:
            return TRANSACTION_VIEW_REJECTED;
            
        case TransferState_Canceled: // Must include logic to say who cancelled transaction
            return TRANSACTION_VIEW_CANCELLED_SELF;
        
        case TransferState_Failed:
            return TRANSACTION_VIEW_FAILED;
            
        default:
            return TRANSACTION_VIEW_NONE;
    }
}

//- Transaction Lists ------------------------------------------------------------------------------

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
    NSMutableArray* transactions = [[NSMutableArray alloc] init];
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
