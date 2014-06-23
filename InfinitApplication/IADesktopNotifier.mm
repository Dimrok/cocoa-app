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
#import <surface/gap/enums.hh>

ELLE_LOG_COMPONENT("OSX.DesktopNotifier");

@implementation IADesktopNotifier
{
@private
  __weak id<IADesktopNotifierProtocol> _delegate;
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

- (NSUserNotification*)_statusNotificationFromTransaction:(IATransaction*)transaction
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
      
    case TRANSACTION_VIEW_CLOUD_BUFFERED:
      title = NSLocalizedString(@"Uploaded!", nil);
      sound = _finished_sound.name;
      message = [NSString stringWithFormat:@"%@ %@ %@",
                 NSLocalizedString(@"Your transfer with", nil),
                 transaction.other_user.fullname,
                 NSLocalizedString(@"is ready to be downloaded", nil)];
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
  res.userInfo = @{@"transaction_id": transaction.transaction_id,
                   @"pid": [NSNumber numberWithInt:[[NSProcessInfo processInfo] processIdentifier]]};
  
  return res;
}

- (NSUserNotification*)_acceptedNotificationFromTransaction:(IATransaction*)transaction
{
  NSUserNotification* res = [[NSUserNotification alloc] init];

  res.title = NSLocalizedString(@"Accepted!", nil);
  NSString* message = [NSString stringWithFormat:@"%@ %@",
                       transaction.other_user.fullname,
                       NSLocalizedString(@"accepted your transfer", nil)];
  res.informativeText = message;
  res.soundName = nil;
  res.userInfo = @{@"transaction_id": transaction.transaction_id,
                   @"pid": [NSNumber numberWithInt:[[NSProcessInfo processInfo] processIdentifier]]};
  return res;
}

- (NSUserNotification*)notificationFromLink:(InfinitLinkTransaction*)link
{
  NSUserNotification* res = [[NSUserNotification alloc] init];
  NSString* message;
  NSString* sound;
  NSString* title;


  switch (link.status)
  {
    case gap_transaction_transferring:
      title = NSLocalizedString(@"Got link!", nil);
      message = [NSString stringWithFormat:@"%@ %@ %@", NSLocalizedString(@"Copied link for", nil),
                 link.name, NSLocalizedString(@"to the clipboard", nil)];
      sound = _incoming_sound.name;
      break;
    case gap_transaction_finished:
      title = NSLocalizedString(@"Success!", nil);
      message = [NSString stringWithFormat:@"%@ %@",
                 link.name, NSLocalizedString(@"successfully uploaded", nil)];
      sound = _finished_sound.name;
      break;

    default:
      return nil;
  }

  if (title == nil)
    return nil;

  res.title = title;
  res.informativeText = message;
  res.soundName = sound;
  res.userInfo = @{@"link_id": link.id_,
                   @"pid": [NSNumber numberWithInt:[[NSProcessInfo processInfo] processIdentifier]]};
  return res;
}

- (void)clearAllNotifications
{
  [_notification_centre removeAllDeliveredNotifications];
}

//- Transaction Handling ---------------------------------------------------------------------------

- (void)desktopNotificationForTransaction:(IATransaction*)transaction
{
  NSUserNotification* user_notification = [self _statusNotificationFromTransaction:transaction];
  
  if (user_notification == nil)
    return;
  
  ELLE_LOG("%s: show desktop notification for transaction (%d) with status: %d",
           self.description.UTF8String, transaction.transaction_id, transaction.status);
  
  [_notification_centre deliverNotification:user_notification];
}

- (void)desktopNotificationForTransactionAccepted:(IATransaction*)transaction
{
  ELLE_LOG("%s: show desktop notification for transaction (%d) accepted",
           self.description.UTF8String, transaction.transaction_id);
  NSUserNotification* user_notification = [self _acceptedNotificationFromTransaction:transaction];

  if (user_notification == nil)
    return;

  [_notification_centre deliverNotification:user_notification];
}

//- Link Handling ----------------------------------------------------------------------------------

- (void)desktopNotificationForLink:(InfinitLinkTransaction*)link
{
  NSUserNotification* user_notification;
  BOOL replaced = NO;
  
  for (NSUserNotification* notif in [_notification_centre deliveredNotifications])
  {
    if ([notif.userInfo valueForKey:@"link_id"] == link.id_)
    {
      ELLE_DEBUG("%s: already have a delivered notification for this link (%d), replace it",
                 self.description.UTF8String, link.id_.unsignedIntegerValue);
      user_notification = [[NSUserNotification alloc] init];
      user_notification.title = NSLocalizedString(@"Uploaded and Got Link!", nil);
      user_notification.informativeText =
      [NSString stringWithFormat:@"%@ %@ %@", NSLocalizedString(@"Copied link for", nil), link.name,
       NSLocalizedString(@"to the clipboard", nil)];
      user_notification.soundName = nil;
      user_notification.userInfo =
      @{@"link_id": link.id_,
        @"pid": [NSNumber numberWithInt:[[NSProcessInfo processInfo] processIdentifier]]};
      [_notification_centre removeDeliveredNotification:notif];
      replaced = YES;
      break;
    }
  }

  if (!replaced)
    user_notification = [self notificationFromLink:link];

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

//- User Notifications Protocol --------------------------------------------------------------------

- (void)userNotificationCenter:(NSUserNotificationCenter*)center
       didActivateNotification:(NSUserNotification*)notification
{
  NSDictionary* dict = notification.userInfo;
  if ([[dict objectForKey:@"pid"] intValue] != [[NSProcessInfo processInfo] processIdentifier])
    return;
  if ([dict objectForKey:@"transaction_id"] != nil)
  {
    NSNumber* transaction_id = [dict objectForKey:@"transaction_id"];
    if (transaction_id == nil || transaction_id.unsignedIntValue == 0)
      return;

    [_delegate desktopNotifier:self hadClickNotificationForTransactionId:transaction_id];
  }
  else if ([dict objectForKey:@"link_id"] != nil)
  {
    NSNumber* link_id = [dict objectForKey:@"link_id"];
    if (link_id == nil || link_id.unsignedIntValue == 0)
      return;
    [_delegate desktopNotifier:self hadClickNotificationForLinkId:link_id];
  }
  [InfinitMetricsManager sendMetric:INFINIT_METRIC_DESKTOP_NOTIFICATION];
}

@end
