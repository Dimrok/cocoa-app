//
//  IADesktopNotifier.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/27/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IADesktopNotifier.h"

#import "InfinitMetricsManager.h"

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("OSX.DesktopNotifier");

@implementation IADesktopNotifier
{
@private
    id <IADesktopNotifierProtocol> _delegate;
    NSUserNotificationCenter* _notification_centre;
    
    NSSound* _finished_sound;
    NSSound* _incoming_sound;
}

//- Inititalisation --------------------------------------------------------------------------------

- (id)initWithDelegate:(id<IADesktopNotifierProtocol>)delegate
{
    if (self = [super init])
    {
        _delegate = delegate;
        _notification_centre = [NSUserNotificationCenter defaultUserNotificationCenter];
        [_notification_centre setDelegate:self];
        NSString* finished_name = @"sound_finished";
        NSString* incoming_name = @"sound_incoming";
        NSString* finished_path = [[NSBundle mainBundle] pathForSoundResource:finished_name];
        NSString* incoming_path = [[NSBundle mainBundle] pathForSoundResource:incoming_name];
        _finished_sound = [[NSSound alloc] initWithContentsOfFile:finished_path byReference:YES];
        _finished_sound.name = finished_name;
        _incoming_sound = [[NSSound alloc] initWithContentsOfFile:incoming_path byReference:YES];
        _incoming_sound.name = incoming_name;
    }
    return self;
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter*)center
     shouldPresentNotification:(NSUserNotification*)notification
{
    return YES;
}

//- General Functions ------------------------------------------------------------------------------

- (NSString*)truncateFilename:(NSString*)filename
{
    NSUInteger max_filename_length = 15;
    NSString* filename_prefix = [filename stringByDeletingPathExtension];
    NSMutableString* truncated_filename;
    if (filename_prefix.length > max_filename_length)
    {
        NSRange truncate_range = {0, MIN([filename_prefix length], max_filename_length)};
        truncate_range = [filename_prefix rangeOfComposedCharacterSequencesForRange:truncate_range];
        
        truncated_filename = [NSMutableString stringWithString:[filename_prefix
                                                                substringWithRange:truncate_range]];
        [truncated_filename appendString:@"..."];
        [truncated_filename appendString:[filename pathExtension]];
    }
    else
        truncated_filename = [NSMutableString stringWithString:filename];
    return truncated_filename;
}

- (NSUserNotification*)notificationFromTransaction:(IATransaction*)transaction
{
    NSUserNotification* res = [[NSUserNotification alloc] init];
    NSString* filename;
    NSString* message;
    NSString* sound;
    NSString* title;
    if (transaction.files_count > 1)
    {
        filename = [NSString stringWithFormat:@"%lu %@", transaction.files_count,
                                                        NSLocalizedString(@"files", @"files")];
    }
    else if ([transaction.files[0] length] > 18)
    {
        filename = [self truncateFilename:transaction.files[0]];
    }
    else
    {
        filename = transaction.files[0];
    }
    
    switch (transaction.view_mode)
    {
        case TRANSACTION_VIEW_WAITING_ACCEPT:
            if (transaction.from_me)
                return nil;
            title = NSLocalizedString(@"Incoming!", @"incoming!");
            sound = _incoming_sound.name;
            message = [NSString stringWithFormat:@"%@ %@ %@ %@", transaction.other_user.fullname,
                       NSLocalizedString(@"wants to send", @"wants to send"),
                       filename,
                       NSLocalizedString(@"to you", @"to you")];
            break;
        
        case TRANSACTION_VIEW_REJECTED:
            if (!transaction.from_me)
                return nil;
            title = NSLocalizedString(@"Shenanigans!", @"shenanigans!");
            message = [NSString stringWithFormat:@"%@ %@", transaction.other_user.fullname,
                       NSLocalizedString(@"declined your transfer", @"declined your transfer")];
            break;
            
        case TRANSACTION_VIEW_CANCELLED:
            title = NSLocalizedString(@"Nuts!", @"nuts!");
            message = [NSString stringWithFormat:@"%@ %@ %@",
                       NSLocalizedString(@"Your transfer with", @"your transfer with"),
                       transaction.other_user.fullname,
                       NSLocalizedString(@"was cancelled", @"was cancelled")];
            break;
            
        case TRANSACTION_VIEW_FAILED:
            title = NSLocalizedString(@"Oh no!", @"oh no!");
            if (transaction.from_me)
                message = [NSString stringWithFormat:@"%@ %@ %@", filename,
                           NSLocalizedString(@"couldn't be sent to", @"couldn't be sent to"),
                           transaction.other_user.fullname];
            else
                message = [NSString stringWithFormat:@"%@ %@ %@", filename,
                           NSLocalizedString(@"couldn't be received from", @"couldn't be received from"),
                           transaction.other_user.fullname];
            break;
            
        case TRANSACTION_VIEW_FINISHED:
            title = NSLocalizedString(@"Success!", @"success");
            sound = _finished_sound.name;
            if (transaction.from_me)
                message = [NSString stringWithFormat:@"%@ %@ %@", transaction.other_user.fullname,
                           NSLocalizedString(@"received", @"received"),
                           filename];
            else
                message = [NSString stringWithFormat:@"%@ %@ %@", filename,
                           NSLocalizedString(@"received from", @"received from"),
                           transaction.other_user.fullname];
            break;
            
        default:
            message = nil;
            break;
    }

    if (title == nil)
        return nil;

    res.title = title;
    res.informativeText = message;
    res.soundName = sound;
    res.userInfo = @{@"transaction_id": transaction.transaction_id};

    return res;
}

- (void)clearAllNotifications
{
    [_notification_centre removeAllDeliveredNotifications];
}

//- Transaction Handling ---------------------------------------------------------------------------

- (void)desktopNotificationForTransaction:(IATransaction*)transaction
{
    NSUserNotification* user_notification = [self notificationFromTransaction:transaction];
    
    if (user_notification == nil)
        return;
    
    ELLE_LOG("%s: show desktop notification for transaction (%d) with status: %d",
             self.description.UTF8String, transaction.transaction_id, transaction.status);
    
    [_notification_centre deliverNotification:user_notification];
}

//- User Notifications Protocol --------------------------------------------------------------------

- (void)userNotificationCenter:(NSUserNotificationCenter*)center
       didActivateNotification:(NSUserNotification*)notification
{
    NSDictionary* dict = notification.userInfo;
    NSNumber* transaction_id;
    if ([[dict objectForKey:@"transaction_id"] isKindOfClass:NSNumber.class])
        transaction_id = [dict objectForKey:@"transaction_id"];
    
    if (transaction_id == nil || transaction_id.unsignedIntValue == 0)
        return;
    
    [_delegate desktopNotifier:self hadClickNotificationForTransactionId:transaction_id];
    [InfinitMetricsManager sendMetric:INFINIT_METRIC_DESKTOP_NOTIFICATION];
}

@end
