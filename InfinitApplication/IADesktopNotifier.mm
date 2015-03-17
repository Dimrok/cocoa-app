//
//  IADesktopNotifier.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/27/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IADesktopNotifier.h"

#import "InfinitMetricsManager.h"

#import <Gap/InfinitLinkTransactionManager.h>
#import <Gap/InfinitPeerTransactionManager.h>

#undef check
#import <elle/log.hh>
#import <surface/gap/enums.hh>

ELLE_LOG_COMPONENT("OSX.DesktopNotifier");

@interface NSUserNotification(Private)
@property BOOL _showsButtons;
@end

@implementation IADesktopNotifier
{
@private
  __weak id<IADesktopNotifierProtocol> _delegate;
  NSUserNotificationCenter* _notification_centre;
  
  NSSound* _finished_sound;
  NSSound* _incoming_sound;
}

#pragma mark - Init

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
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(linkTransactionUpdated:)
                                                 name:INFINIT_LINK_TRANSACTION_STATUS_NOTIFICATION
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(peerTransactionUpdated:)
                                                 name:INFINIT_NEW_PEER_TRANSACTION_NOTIFICATION
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(peerTransactionUpdated:)
                                                 name:INFINIT_PEER_TRANSACTION_STATUS_NOTIFICATION
                                               object:nil];
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  for (NSUserNotification* notification in _notification_centre.scheduledNotifications)
    [_notification_centre removeScheduledNotification:notification];
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter*)center
     shouldPresentNotification:(NSUserNotification*)notification
{
  return YES;
}

#pragma mark - General

- (void)clearAllNotifications
{
  [_notification_centre removeAllDeliveredNotifications];
  for (NSUserNotification* notification in _notification_centre.scheduledNotifications)
    [_notification_centre removeScheduledNotification:notification];
}

#pragma mark - Transaction Handling

- (void)desktopNotificationForTransactionAccepted:(InfinitPeerTransaction*)transaction
{
  if (!transaction.from_device)
    return;

  ELLE_LOG("%s: show desktop notification for transaction (%d) accepted",
           self.description.UTF8String, transaction.id_);
  NSUserNotification* user_notification = [self _acceptedNotificationFromTransaction:transaction];

  if (user_notification == nil)
    return;

  [_notification_centre deliverNotification:user_notification];
}

- (void)peerTransactionUpdated:(NSNotification*)notification
{
  NSNumber* id_ = notification.userInfo[kInfinitTransactionId];
  InfinitPeerTransaction* transaction =
    [[InfinitPeerTransactionManager sharedInstance] transactionWithId:id_];
  if (!transaction.from_device && !transaction.to_device)
  {
    [self _removeNotificationForTransactionId:id_];
    ELLE_DEBUG("%s: transaction (%d) for another device, remove existing notifications",
               self.description.UTF8String, id_.unsignedIntegerValue);
    return;
  }

  NSUserNotification* user_notification = [self _statusNotificationFromPeerTransaction:transaction];

  if (user_notification == nil)
    return;

  [self _removeNotificationForTransactionId:id_];

  ELLE_LOG("%s: show desktop notification for transaction (%d) with status: %d",
           self.description.UTF8String, transaction.id_.unsignedIntegerValue, transaction.status);

  [_notification_centre deliverNotification:user_notification];
  if (transaction.status == gap_transaction_waiting_accept && transaction.receivable)
    [_notification_centre scheduleNotification:user_notification];
}

- (void)linkTransactionUpdated:(NSNotification*)notification
{
  NSNumber* id_ = notification.userInfo[kInfinitTransactionId];
  InfinitLinkTransaction* link =
    [[InfinitLinkTransactionManager sharedInstance] transactionWithId:id_];
  if (!link.from_device)
    return;

  NSUserNotification* user_notification = [self _notificationFromLink:link];

  if (user_notification == nil)
    return;

  ELLE_LOG("%s: show desktop notification for link (%d) with status: %d",
           self.description.UTF8String, link.id_, link.status);
  [_notification_centre deliverNotification:user_notification];
}

- (void)desktopNotificationForLinkCopied:(InfinitLinkTransaction*)link
{
  NSUserNotification* user_notification = [[NSUserNotification alloc] init];

  user_notification.title = NSLocalizedString(@"Got Link!", nil);
  user_notification.informativeText =
    [NSString stringWithFormat:@"%@ %@ %@", NSLocalizedString(@"Copied link for", nil), link.name,
     NSLocalizedString(@"to the clipboard", nil)];
  user_notification.soundName = nil;
  user_notification.userInfo =
    @{@"link_id": link.id_,
      @"pid": [NSNumber numberWithInt:[[NSProcessInfo processInfo] processIdentifier]]};

  ELLE_LOG("%s: show desktop notification for copy link (%d)",
           self.description.UTF8String, link.id_);

  [_notification_centre deliverNotification:user_notification];
}

#pragma mark - Application Updated

- (void)desktopNotificationForApplicationUpdated
{
  NSString* version =
    [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
  NSUserNotification* user_notification = [[NSUserNotification alloc] init];
  user_notification.title = NSLocalizedString(@"Infinit Updated!", nil);
  user_notification.informativeText = [NSString stringWithFormat:@"%@ %@",
                                       NSLocalizedString(@"Infinit updated to version", nil),
                                       version];
  user_notification.soundName = nil;
  user_notification.userInfo =
    @{@"pid": [NSNumber numberWithInt:[[NSProcessInfo processInfo] processIdentifier]]};
  ELLE_LOG("%s: show desktop notification for application updated to %s",
           self.description.UTF8String, version.UTF8String);
  [_notification_centre deliverNotification:user_notification];
}

#pragma mark - NSUserNotificationCenterDelegate

- (void)userNotificationCenter:(NSUserNotificationCenter*)center
       didActivateNotification:(NSUserNotification*)notification
{
  NSDictionary* dict = notification.userInfo;
  [center removeScheduledNotification:notification];
  [center removeDeliveredNotification:notification];
  if ([[dict objectForKey:@"pid"] intValue] != [NSProcessInfo processInfo].processIdentifier)
    return;
  if ([dict objectForKey:@"transaction_id"] != nil)
  {
    NSNumber* transaction_id = [dict objectForKey:@"transaction_id"];
    if (transaction_id == nil || transaction_id.unsignedIntValue == 0)
      return;

    if (notification.activationType == NSUserNotificationActivationTypeContentsClicked)
    {
      [_delegate desktopNotifier:self hadClickNotificationForTransactionId:transaction_id];
    }
    else
    {
      [_delegate desktopNotifier:self hadAcceptTransaction:transaction_id];
      [InfinitMetricsManager sendMetric:INFINIT_METRIC_DESKTOP_NOTIFICATION_ACCEPT];
    }
  }
  else if ([dict objectForKey:@"link_id"] != nil)
  {
    NSNumber* link_id = [dict objectForKey:@"link_id"];
    if (link_id == nil || link_id.unsignedIntValue == 0)
      return;
    [_delegate desktopNotifier:self hadClickNotificationForLinkId:link_id];
  }
  else
  {
    [_delegate desktopNotifierHadClickApplicationUpdatedNotification:self];
  }
  [InfinitMetricsManager sendMetric:INFINIT_METRIC_DESKTOP_NOTIFICATION];
}

#pragma mark - Helpers

- (NSString*)_truncateFilename:(NSString*)filename
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

- (NSDictionary*)_userInfoFromTransaction:(InfinitTransaction*)transaction
{
  NSString* key = nil;
  if ([transaction isKindOfClass:InfinitPeerTransaction.class])
    key = @"transaction_id";
  else if ([transaction isKindOfClass:InfinitLinkTransaction.class])
    key = @"link_id";
  else
    return nil;
  return @{key: transaction.id_,
           @"pid": @([NSProcessInfo processInfo].processIdentifier)};
}

- (NSUserNotification*)_statusNotificationFromPeerTransaction:(InfinitPeerTransaction*)transaction
{
  // Only show desktop notifications on concerned devices.
  if (!transaction.sender.is_self && !transaction.recipient.is_self)
    return nil;

  NSUserNotification* res = [[NSUserNotification alloc] init];
  res.soundName = nil;
  NSString* filename;
  if (transaction.files.count > 1)
  {
    filename = [NSString stringWithFormat:@"%lu %@", transaction.files.count,
                NSLocalizedString(@"files", @"files")];
  }
  else if ([transaction.files[0] length] > 18)
  {
    filename = [self _truncateFilename:transaction.files[0]];
  }
  else
  {
    filename = transaction.files[0];
  }

  switch (transaction.status)
  {
    case gap_transaction_waiting_accept:
      if (transaction.from_device)
      {
        res.title = NSLocalizedString(@"Now Sending!", nil);
        res.soundName = _incoming_sound.name;
        res.informativeText = NSLocalizedString(@"Your transfer is in progress!", nil);
      }
      else if (transaction.receivable)
      {
        res.title = NSLocalizedString(@"Incoming!", @"incoming!");
        res.soundName = _incoming_sound.name;
        res.informativeText = [NSString stringWithFormat:@"%@ %@ %@", transaction.sender.fullname,
                               NSLocalizedString(@"wants to send", nil),
                               filename,
                               NSLocalizedString(@"to you", nil)];
        if ([IAFunctions osxVersion] > INFINIT_OS_X_VERSION_10_8)
        {
          res.hasActionButton = YES;
          res._showsButtons = YES;
          res.actionButtonTitle = NSLocalizedString(@"Accept", nil);
          res.otherButtonTitle = NSLocalizedString(@"Snooze", nil);
        }
      }
      else
      {
        return nil;
      }
      break;

    case gap_transaction_rejected:
      if (!transaction.sender.is_self)
        return nil;
      res.title = NSLocalizedString(@"Declined!", nil);
      res.informativeText = [NSString stringWithFormat:@"%@ %@ %@.",
                             NSLocalizedString(@"Unfortunately", nil),
                             transaction.other_user.fullname,
                             NSLocalizedString(@"declined your transfer", nil)];
      break;

    case gap_transaction_canceled:
      if (transaction.canceler == nil)
      {
        res.title = NSLocalizedString(@"Canceled", nil);
        res.informativeText = NSLocalizedString(@"Your transfer has been canceled", nil);
      }
      else if (transaction.canceler.is_self)
      {
        res.title = NSLocalizedString(@"Canceled", nil);
        res.informativeText = NSLocalizedString(@"You canceled the transfer", nil);
      }
      else if (transaction.sender.is_self)
      {
        res.title = NSLocalizedString(@"Declined", nil);
        res.informativeText = [NSString stringWithFormat:@"%@ %@ %@",
                               NSLocalizedString(@"Unfortunately", nil),
                               transaction.canceler.fullname,
                               NSLocalizedString(@"declined your file", nil)];
      }
      else
      {
        res.title = NSLocalizedString(@"Canceled", nil);
        res.informativeText = [NSString stringWithFormat:@"%@ %@",
                               transaction.canceler.fullname,
                               NSLocalizedString(@"canceled the transfer", nil)];
      }
      break;

    case gap_transaction_failed:
      res.title = NSLocalizedString(@"Transfer stopped!", nil);
      if (transaction.sender.is_self)
      {
        res.informativeText =
        NSLocalizedString(@"Something went wrong. Keep calm and try again.", nil);
      }
      break;

    case gap_transaction_finished:
      if (transaction.sender.is_self)
      {
        res.title = NSLocalizedString(@"Delivered!", nil);
        res.informativeText = [NSString stringWithFormat:@"%@ %@.",
                               NSLocalizedString(@"Voilà, your file has been delivered to", nil),
                               transaction.recipient.fullname];
      }
      else
      {
        res.title = NSLocalizedString(@"Received!", nil);
        res.informativeText =
        NSLocalizedString(@"Voilà, your file is available. Open it now!", nil);
      }
      res.soundName = _finished_sound.name;
      break;

    case gap_transaction_cloud_buffered:
      res.title = NSLocalizedString(@"Sent!", nil);
      res.soundName = _finished_sound.name;
      res.informativeText =
      NSLocalizedString(@"We’ll let you know when your file has been delivered.", nil);
      break;

    default:
      return nil;
  }

  res.deliveryDate = [NSDate date];
  res.userInfo = [self _userInfoFromTransaction:transaction];

  return res;
}

- (NSUserNotification*)_acceptedNotificationFromTransaction:(InfinitPeerTransaction*)transaction
{
  NSUserNotification* res = [[NSUserNotification alloc] init];

  res.title = NSLocalizedString(@"Accepted!", nil);
  NSString* message = [NSString stringWithFormat:@"%@ %@",
                       transaction.other_user.fullname,
                       NSLocalizedString(@"accepted your transfer", nil)];
  res.informativeText = message;
  res.soundName = nil;
  res.userInfo = [self _userInfoFromTransaction:transaction];
  return res;
}

- (NSUserNotification*)_notificationFromLink:(InfinitLinkTransaction*)link
{
  // Only show desktop notifications on concerned devices.
  if (!link.from_device)
    return nil;
  NSUserNotification* res = [[NSUserNotification alloc] init];
  NSString* message;
  NSString* sound;
  NSString* title;


  switch (link.status)
  {
    case gap_transaction_transferring:
      title = NSLocalizedString(@"Link copied!", nil);
      if (link.screenshot)
      {
        message = NSLocalizedString(@"A link to the screenshot has been copied to your clipboard",
                                    nil);
      }
      else
      {
        message = NSLocalizedString(@"A link to the file has been copied to your clipboard", nil);
      }
      sound = _incoming_sound.name;
      break;

    default:
      return nil;
  }

  if (title == nil)
    return nil;

  res.title = title;
  res.informativeText = message;
  res.soundName = sound;
  res.deliveryDate = [NSDate date];
  res.userInfo = [self _userInfoFromTransaction:link];
  return res;
}

- (void)_removeNotificationForTransactionId:(NSNumber*)id_
{
  NSMutableArray* delivered = [NSMutableArray array];
  for (NSUserNotification* notification in _notification_centre.deliveredNotifications)
  {
    if ([notification.userInfo[@"transaction_id"] isEqual:id_])
      [delivered addObject:notification];
  }
  for (NSUserNotification* notification in delivered)
    [_notification_centre removeDeliveredNotification:notification];
  NSMutableArray* scheduled = [NSMutableArray array];
  for (NSUserNotification* notification in _notification_centre.scheduledNotifications)
  {
    if ([notification.userInfo[@"transaction_id"] isEqual:id_])
      [scheduled addObject:notification];
  }
  for (NSUserNotification* notification in scheduled)
    [_notification_centre removeScheduledNotification:notification];
}

@end
