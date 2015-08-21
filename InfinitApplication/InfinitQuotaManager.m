//
//  InfinitQuotaManager.m
//  InfinitApplication
//
//  Created by Christopher Crone on 19/08/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitQuotaManager.h"

#import "InfinitQuotaWindowController.h"
#import "InfinitMetricsManager.h"

#import <Gap/InfinitAccountManager.h>
#import <Gap/InfinitLinkTransactionManager.h>
#import <Gap/InfinitPeerTransactionManager.h>

#import <Gap/NSNumber+DataSize.h>

typedef NS_ENUM(NSUInteger, InfinitQuotaWindowType)
{
  InfinitQuotaWindowGhost,
  InfinitQuotaWindowSelf,
  InfinitQuotaWindowTransfer,
  InfinitQuotaWindowLink,
};

@interface InfinitQuotaManager () <InfinitQuotaWindowProtocol>

@property InfinitQuotaWindowType current_window;
@property (nonatomic, readonly) NSString* ghost_download_details;
@property (nonatomic, readonly) NSString* ghost_download_title;
@property (nonatomic, readonly) NSString* link_quota_details;
@property (nonatomic, readonly) NSString* link_quota_title;
@property (nonatomic, readonly) NSString* send_to_self_details;
@property (nonatomic, readonly) NSString* send_to_self_title;
@property (nonatomic, readonly) NSString* transfer_size_details;
@property (nonatomic, readonly) NSString* transfer_size_title;

@property (nonatomic, readonly) InfinitQuotaWindowController* quota_window;

@end

static InfinitQuotaManager* _instance = nil;
static dispatch_once_t _instance_token = 0;

@implementation InfinitQuotaManager

@synthesize quota_window = _quota_window;

#pragma mark - Init

- (instancetype)_init
{
  NSAssert(_instance == nil, @"Use sharedInstance.");
  if (self = [super init])
  {
    _ghost_download_details =
      NSLocalizedString(@"You can upgrade your plan to remove this limitation.", nil);
    _ghost_download_title =
      NSLocalizedString(@"%@ will need to install Infinit to get the files you sent.", nil);
    _send_to_self_details =
      NSLocalizedString(@"You can upgrade your plan or invite friends to remove this limitation.",
                        nil);
    _send_to_self_title =
      NSLocalizedString(@"You have reached your monthly limit for sending files to your own devices.", nil);
    _transfer_size_details =
      NSLocalizedString(@"You can upgrade your plan or invite friends to remove this limitation.",
                        nil);
    _transfer_size_title = NSLocalizedString(@"This account is limited to %@ transfers.", nil);
    _link_quota_details =
      NSLocalizedString(@"You can upgrade your plan or invite friends to remove this limitation.",
                        nil);
    _link_quota_title =
      NSLocalizedString(@"You have reached your %@ storage limit for links.", nil);
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_ghostDownloadLimited:)
                                                 name:INFINIT_GHOST_DOWNLOAD_LIMITED
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_linkQuotaExceeded:)
                                                 name:INFINIT_LINK_QUOTA_EXCEEDED
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_sendToSelfLimited:)
                                                 name:INFINIT_SEND_TO_SELF_LIMITED 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_transferSizeLimited:)
                                                 name:INFINIT_PEER_TRANSFER_SIZE_LIMITED
                                               object:nil];
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (instancetype)sharedInstance
{
  dispatch_once(&_instance_token, ^
  {
    _instance = [[self alloc] _init];
  });
  return _instance;
}

#pragma mark - External

+ (void)start
{
  [self sharedInstance];
}

+ (void)showWindowForSendToSelfLimit
{
  [[self sharedInstance] _showWindowForSendToSelfLimit];
}

+ (void)showWindowForTransferSizeLimit
{
  [[self sharedInstance] _showWindowForTransferSizeLimit];
}

- (void)_showWindowForSendToSelfLimit
{
  [self _showWindowWithTitle:self.send_to_self_title
                     details:self.send_to_self_details 
               inviteEnabled:YES];
}

- (void)_showWindowForTransferSizeLimit
{
  NSString* size = @([InfinitAccountManager sharedInstance].transfer_size_limit).infinit_fileSize;
  NSString* title = [NSString stringWithFormat:self.transfer_size_title, size];
  [self _showWindowWithTitle:title details:self.transfer_size_details inviteEnabled:YES];
}

#pragma mark - Callbacks

- (void)_linkQuotaExceeded:(NSNotification*)notification
{
  NSString* size = [InfinitAccountManager sharedInstance].link_quota.quota.infinit_fileSize;
  NSString* title = [NSString stringWithFormat:self.link_quota_title, size];
  [self _showWindowWithTitle:title details:self.link_quota_details inviteEnabled:YES];
}

- (void)_sendToSelfLimited:(NSNotification*)notification
{
  [self _showWindowForSendToSelfLimit];
}

- (void)_transferSizeLimited:(NSNotification*)notification
{
  [self _showWindowForTransferSizeLimit];
}

- (void)_ghostDownloadLimited:(NSNotification*)notification
{
  InfinitPeerTransaction* transaction =
    [InfinitPeerTransactionManager transactionWithId:notification.userInfo[kInfinitTransactionId]];
  NSString* title =
    [NSString stringWithFormat:self.ghost_download_title, transaction.recipient.fullname];
  [self _showWindowWithTitle:title details:self.ghost_download_details inviteEnabled:NO];
}

#pragma mark - InfinitQuotaWindowProtocol

- (void)gotCancel
{
  InfinitMetricType metric;
  switch (self.current_window)
  {
    case InfinitQuotaWindowGhost:
      metric = INFINIT_METRIC_GHOST_QUOTA_CANCEL;
      break;
    case InfinitQuotaWindowLink:
      metric = INFINIT_METRIC_LINK_QUOTA_CANCEL;
      break;
    case InfinitQuotaWindowSelf:
      metric = INFINIT_METRIC_SELF_QUOTA_CANCEL;
      break;
    case InfinitQuotaWindowTransfer:
      metric = INFINIT_METRIC_TRANSFER_QUOTA_CANCEL;
      break;
  }
  [InfinitMetricsManager sendMetric:metric];
}

- (void)gotInvite
{
  InfinitMetricType metric;
  switch (self.current_window)
  {
    case InfinitQuotaWindowGhost:
      return;
    case InfinitQuotaWindowLink:
      metric = INFINIT_METRIC_LINK_QUOTA_INVITE;
      break;
    case InfinitQuotaWindowSelf:
      metric = INFINIT_METRIC_SELF_QUOTA_INVITE;
      break;
    case InfinitQuotaWindowTransfer:
      metric = INFINIT_METRIC_TRANSFER_QUOTA_INVITE;
      break;
  }
  [InfinitMetricsManager sendMetric:metric];
}

- (void)gotUpgrade
{
  InfinitMetricType metric;
  switch (self.current_window)
  {
    case InfinitQuotaWindowGhost:
      metric = INFINIT_METRIC_GHOST_QUOTA_UPGRADE;
      break;
    case InfinitQuotaWindowLink:
      metric = INFINIT_METRIC_LINK_QUOTA_UPGRADE;
      break;
    case InfinitQuotaWindowSelf:
      metric = INFINIT_METRIC_SELF_QUOTA_UPGRADE;
      break;
    case InfinitQuotaWindowTransfer:
      metric = INFINIT_METRIC_TRANSFER_QUOTA_UPGRADE;
      break;
  }
  [InfinitMetricsManager sendMetric:metric];
}

#pragma mark - Helpers

- (void)_showWindowWithTitle:(NSString*)title
                     details:(NSString*)details
               inviteEnabled:(BOOL)invite_enabled
{
  [self.quota_window showWithTitleText:title details:details inviteButtonEnabled:invite_enabled];
  [self.quota_window showWindow:self];
}

- (InfinitQuotaWindowController*)quota_window
{
  static dispatch_once_t _quota_window_token;
  dispatch_once(&_quota_window_token, ^
  {
    NSString* class_name = NSStringFromClass(InfinitQuotaWindowController.class);
    _quota_window = [[InfinitQuotaWindowController alloc] initWithWindowNibName:class_name];
    _quota_window.delegate = self;
  });
  return _quota_window;
}

@end
