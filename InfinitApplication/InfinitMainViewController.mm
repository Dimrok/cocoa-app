//
//  InfinitMainViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 13/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "InfinitMainViewController.h"
#import "InfinitMetricsManager.h"
#import "InfinitTooltipViewController.h"
#import "InfinitUsageBar.h"

#import <Gap/InfinitAccountManager.h>
#import <Gap/InfinitConnectionManager.h>
#import <Gap/InfinitConstants.h>
#import <Gap/InfinitLinkTransactionManager.h>
#import <Gap/InfinitPeerTransactionManager.h>
#import <Gap/InfinitStateManager.h>
#import <Gap/InfinitUserManager.h>
#import <Gap/NSNumber+DataSize.h>

#undef check
#import <elle/log.hh>
#import <version.hh>

ELLE_LOG_COMPONENT("OSX.MainViewController");

#define INFINIT_FEEDBACK_LINK @"http://help.infinit.io?utm_source=app&utm_medium=mac"
#define INFINIT_HELP_LINK @"http://help.infinit.io/knowledgebase?utm_source=app&utm_medium=mac"

//- Main Controller --------------------------------------------------------------------------------

@interface InfinitMainViewController ()

@property (nonatomic, strong) IBOutlet InfinitUsageBar* usage_bar;
@property (nonatomic, strong) IBOutlet NSButton* usage_label;

@property (nonatomic, unsafe_unretained) NSViewController* current_controller;
@property (nonatomic, weak) id<InfinitMainViewProtocol> delegate;
@property (nonatomic, readonly) BOOL for_people_view;
@property (nonatomic, strong) InfinitLinkViewController* link_controller;
@property (nonatomic, strong) InfinitTooltipViewController* tooltip;
@property (nonatomic, strong) InfinitTransactionViewController* transaction_controller;

@end

static NSString* _version_str = nil;
static NSDictionary* _usage_label_attrs = nil;

@implementation InfinitMainViewController

#pragma mark - Init

- (id)initWithDelegate:(id<InfinitMainViewProtocol>)delegate
         forPeopleView:(BOOL)flag;
{
  if (self = [super initWithNibName:self.className bundle:nil])
  {
    _for_people_view = flag;
    _delegate = delegate;
    _transaction_controller =
      [[InfinitTransactionViewController alloc] initWithDelegate:self];
    _link_controller =
      [[InfinitLinkViewController alloc] initWithDelegate:self];
    if (_for_people_view)
      self.current_controller = _transaction_controller;
    else
      self.current_controller = _link_controller;
    if (!_version_str.length)
    {
      _version_str =
        [NSString stringWithFormat:@"v%@", [NSString stringWithUTF8String:INFINIT_VERSION]];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateQuotaInformation)
                                                 name:INFINIT_ACCOUNT_QUOTA_UPDATED
                                               object:nil];
  }
  return self;
}

- (void)dealloc
{
  _transaction_controller = nil;
  _link_controller = nil;
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib
{
  [self.main_view addSubview:self.current_controller.view];
  NSArray* contraints =
    [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|"
                                            options:0
                                            metrics:nil
                                              views:@{@"view": self.current_controller.view}];
  [self.main_view addConstraints:contraints];
  _version_item.title = _version_str;
}

- (CATransition*)transitionFromLeft:(BOOL)from_left
{
  CATransition* transition = [CATransition animation];
  transition.type = kCATransitionPush;
  if (from_left)
    transition.subtype = kCATransitionFromLeft;
  else
    transition.subtype = kCATransitionFromRight;
  return transition;
}

- (void)loadView
{
  [super loadView];
  [self.view_selector setDelegate:self];
  [self.view_selector setupViewForPeopleView:_for_people_view];
  [self.view_selector setLinkCount:self.link_controller.links_running];
  [self.view_selector setTransactionCount:self.transaction_controller.unread_rows];

  if (_for_people_view)
  {
    ELLE_LOG("%s: loading main view for people", self.description.UTF8String);
    self.send_button.image = [IAFunctions imageNamed:@"icon-transfer"];
    self.send_button.toolTip = NSLocalizedString(@"Send a file", nil);
  }
  else
  {
    ELLE_LOG("%s: loading main view for links", self.description.UTF8String);
    self.send_button.image = [IAFunctions imageNamed:@"icon-upload"];
    self.send_button.toolTip = NSLocalizedString(@"Get a link", nil);
  }
  [self updateQuotaInformation];
}

- (void)linkAdded:(NSNotification*)notification
{
  NSNumber* id_ = notification.userInfo[kInfinitTransactionId];
  InfinitLinkTransaction* link =
    [[InfinitLinkTransactionManager sharedInstance] transactionWithId:id_];
  if (self.current_controller != _link_controller)
    return;
  [self.link_controller linkAdded:link];
  [self.view_selector setLinkCount:self.link_controller.links_running];
}

- (void)linkUpdated:(NSNotification*)notification
{
  if (self.current_controller != self.link_controller)
    return;
  NSNumber* id_ = notification.userInfo[kInfinitTransactionId];
  InfinitLinkTransaction* link =
    [[InfinitLinkTransactionManager sharedInstance] transactionWithId:id_];
  [_link_controller linkUpdated:link];
  [self.view_selector setLinkCount:_link_controller.links_running];
}

- (void)transactionAdded:(NSNotification*)notification
{
  if (self.current_controller != self.transaction_controller)
    return;
  NSNumber* id_ = notification.userInfo[kInfinitTransactionId];
  InfinitPeerTransaction* transaction =
    [[InfinitPeerTransactionManager sharedInstance] transactionWithId:id_];
  [_transaction_controller transactionAdded:transaction];
  [self.view_selector setTransactionCount:_transaction_controller.unread_rows];
}

- (void)transactionUpdated:(NSNotification*)notification
{
  if (self.current_controller != self.transaction_controller)
    return;
  NSNumber* id_ = notification.userInfo[kInfinitTransactionId];
  InfinitPeerTransaction* transaction =
    [[InfinitPeerTransactionManager sharedInstance] transactionWithId:id_];
  [self.transaction_controller transactionUpdated:transaction];
  [self.view_selector setTransactionCount:self.transaction_controller.unread_rows];
}

#pragma mark - User Handling

- (void)userUpdated:(NSNotification*)notification
{
  if (self.current_controller != self.transaction_controller)
    return;
  NSNumber* id_ = notification.userInfo[kInfinitUserId];
  InfinitUser* user = [[InfinitUserManager sharedInstance] userWithId:id_];
  [self.transaction_controller userUpdated:user];
}

#pragma mark - Link View Protocol

- (void)copyLinkToPasteBoard:(InfinitLinkTransaction*)link
{
  [_delegate copyLinkToClipboard:link];
}

- (void)linksViewResizeToHeight:(CGFloat)height
{
  if (height == self.content_height_constraint.constant)
  {
    [_link_controller resizeComplete];
    return;
  }

  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
   {
     context.duration = 0.15;
     [self.content_height_constraint.animator setConstant:height];
   }
                      completionHandler:^
   {
     self.content_height_constraint.constant = height;
     [_link_controller resizeComplete];
   }];
}


#pragma mark - Peer Transaction Protocol

- (void)transactionsViewResizeToHeight:(CGFloat)height
{
  if (height == self.content_height_constraint.constant)
    return;

  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
  {
    context.duration = 0.15;
    [self.content_height_constraint.animator setConstant:height];
  }
                      completionHandler:^
  {
    self.content_height_constraint.constant = height;
  }];
}
- (void)userGotClicked:(InfinitUser*)user
{
  self.transaction_controller.changing = YES;
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
  {
    context.duration = 0.15;
    [self.content_height_constraint.animator setConstant:0.0];
  }
                      completionHandler:^
  {
    [_delegate userGotClicked:user];
  }];
}

//- Transaction Link Protocol ----------------------------------------------------------------------

- (void)gotUserClick:(InfinitMainTransactionLinkView*)sender
{
  if (self.current_controller == _transaction_controller)
    return;

  ELLE_LOG("%s: changing to people view", self.description.UTF8String);

  self.send_button.image = [IAFunctions imageNamed:@"icon-transfer"];
  self.send_button.toolTip = NSLocalizedString(@"Send a file", nil);

  [_transaction_controller updateModel];
  [_transaction_controller scrollToTop];

  [self.view_selector setMode:INFINIT_MAIN_VIEW_TRANSACTION_MODE];
  _link_controller.changing = YES;
  self.main_view.animations = @{@"subviews": [self transitionFromLeft:NO]};
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
   {
     context.duration = 0.15;
     [self.main_view.animator replaceSubview:self.current_controller.view
                                        with:_transaction_controller.view];
     self.current_controller = self.transaction_controller;
     [self updateQuotaInformation];
   }
                      completionHandler:^
   {
     NSArray* constraints =
       [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|"
                                               options:0
                                               metrics:nil
                                                 views:@{@"view": self.current_controller.view}];
     [self.main_view addConstraints:constraints];
     if (self.content_height_constraint.constant != _transaction_controller.height)
     {
       [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
        {
          context.duration = 0.15;
          [self.content_height_constraint.animator setConstant:_transaction_controller.height];
        }
                           completionHandler:^
        {
          _transaction_controller.changing = NO;
        }];
     }
     else
     {
       _transaction_controller.changing = NO;
     }
   }];
  [InfinitMetricsManager sendMetric:INFINIT_METRIC_MAIN_PEOPLE];
}

- (void)gotLinkClick:(InfinitMainTransactionLinkView*)sender
{
  if (self.current_controller == self.link_controller)
    return;

  ELLE_LOG("%s: changing to link view", self.description.UTF8String);

  [_tooltip close];
  [self.transaction_controller closeToolTips];
  [self.transaction_controller markTransactionsRead];

  self.send_button.image = [IAFunctions imageNamed:@"icon-upload"];
  self.send_button.toolTip = NSLocalizedString(@"Get a link", nil);

  [self.link_controller updateModel];
  [self.link_controller scrollToTop];

  [self.view_selector setMode:INFINIT_MAIN_VIEW_LINK_MODE];
  self.transaction_controller.changing = YES;
  self.main_view.animations = @{@"subviews": [self transitionFromLeft:YES]};
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
  {
    context.duration = 0.15;
    [self.main_view.animator replaceSubview:self.current_controller.view
                                       with:self.link_controller.view];
    self.current_controller = self.link_controller;
    [self updateQuotaInformation];
  }
                      completionHandler:^
  {
    NSArray* constraints =
      [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|"
                                              options:0
                                              metrics:nil
                                                views:@{@"view": self.current_controller.view}];
    [self.main_view addConstraints:constraints];
    if (self.content_height_constraint.constant != self.link_controller.height)
    {
      [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
      {
        context.duration = 0.15;
        [self.content_height_constraint.animator setConstant:self.link_controller.height];
      }
                          completionHandler:^
      {
        self.link_controller.changing = NO;
      }];
    }
    else
    {
      self.link_controller.changing = NO;
    }
  }];
  [InfinitMetricsManager sendMetric:INFINIT_METRIC_MAIN_LINKS];
}

#pragma mark - User Interaction

- (IBAction)gearButtonClicked:(NSButton*)sender
{
  NSPoint point = NSMakePoint(sender.frame.origin.x + NSWidth(sender.frame),
                              sender.frame.origin.y);
  NSPoint menu_origin = [sender.superview convertPoint:point toView:nil];
  NSEvent* event = [NSEvent mouseEventWithType:NSLeftMouseDown
                                      location:menu_origin
                                 modifierFlags:NSLeftMouseDownMask
                                     timestamp:0
                                  windowNumber:sender.window.windowNumber
                                       context:sender.window.graphicsContext
                                   eventNumber:0
                                    clickCount:1
                                      pressure:1];
  [NSMenu popUpContextMenu:_gear_menu withEvent:event forView:sender];
}

- (IBAction)sendButtonClicked:(NSButton*)sender
{
  _transaction_controller.changing = YES;
  [InfinitMetricsManager sendMetric:INFINIT_METRIC_MAIN_SEND];
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
  {
    context.duration = 0.15;
    [self.content_height_constraint.animator setConstant:0.0];
  } completionHandler:^
  {
    if (self.view_selector.mode == INFINIT_MAIN_VIEW_TRANSACTION_MODE)
      [_delegate sendGotClicked:self];
    else
      [_delegate makeLinkGotClicked:self];
  }];
}

- (IBAction)quitClicked:(NSMenuItem*)sender
{
  [_delegate quit:self];
}

- (IBAction)logoutClicked:(NSMenuItem*)sender
{
  [_delegate logout:self];
} 

- (IBAction)onFeedbackClick:(NSMenuItem*)sender
{
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:INFINIT_FEEDBACK_LINK]];
}

- (IBAction)onHelpClick:(id)sender
{
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:INFINIT_HELP_LINK]];
}

- (IBAction)onReportProblemClick:(NSMenuItem*)sender
{
  [_delegate reportAProblem:self];
}

- (IBAction)onSettingsClick:(NSMenuItem*)sender
{
  [_delegate settings:self];
}

- (IBAction)onWebProfileClick:(NSMenuItem*)sender
{
  InfinitStateManager* manager = [InfinitStateManager sharedInstance];
  [manager webLoginTokenWithCompletionBlock:^(InfinitStateResult* result,
                                              NSString* token,
                                              NSString* email)
  {
    if (!result.success || !token.length || !email.length)
      return;
    NSString* url_str =
      [kInfinitWebProfileURL stringByAppendingFormat:@"&login_token=%@&email=%@", token, email];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url_str]];
  }];
}

- (IBAction)onGetMoreStorageClicked:(NSMenuItem*)sender
{
  InfinitStateManager* manager = [InfinitStateManager sharedInstance];
  [manager webLoginTokenWithCompletionBlock:^(InfinitStateResult* result,
                                              NSString* token,
                                              NSString* email)
   {
     if (!result.success || !token.length || !email.length)
       return;
     NSString* url_str =
       [kInfinitReferalMoreStorageURL stringByAppendingFormat:@"&login_token=%@&email=%@",
        token, email];
     [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url_str]];
   }];
}

#pragma mark - Quota Handling

- (void)updateQuotaInformation
{
  if (self.current_controller == self.transaction_controller)
  {
    InfinitAccountUsageQuota* self_quota =
      [InfinitAccountManager sharedInstance].send_to_self_quota;
    if (self_quota.quota)
    {
      self.usage_bar.doubleValue = self_quota.proportion_used.doubleValue;
      NSString* label_str = nil;
      switch (self_quota.remaining.unsignedIntegerValue)
      {
        case 0:
          label_str = NSLocalizedString(@"No monthly transfers to yourself left", nil);
          break;
        case 1:
          label_str = NSLocalizedString(@"1 monthly transfer to yourself left", nil);
          break;
        default:
          label_str = [NSString localizedStringWithFormat:@"%@ monthly transfers to yourself left",
                       self_quota.remaining];
          break;
      }
      NSMutableDictionary* attrs =
        [[self.usage_label.attributedTitle attributesAtIndex:0 effectiveRange:NULL] mutableCopy];
      attrs[NSForegroundColorAttributeName] = [NSColor whiteColor];
      self.usage_label.attributedTitle =
        [[NSAttributedString alloc] initWithString:label_str attributes:attrs];
      self.usage_bar.hidden = NO;
      self.usage_label.hidden = NO;
    }
    else
    {
      self.usage_bar.hidden = YES;
      self.usage_label.hidden = YES;
    }
  }
  else if (self.current_controller == self.link_controller)
  {
    InfinitAccountUsageQuota* link_quota = [InfinitAccountManager sharedInstance].link_quota;
    if (link_quota.quota)
    {
      self.usage_bar.doubleValue = link_quota.proportion_used.doubleValue;
      NSString* label_str = nil;
      if (link_quota.remaining.unsignedLongLongValue <= 0)
      {
        label_str = NSLocalizedString(@"No storage space left", nil);
      }
      else
      {
        NSString* remaining_str = link_quota.remaining.infinit_fileSize;
        label_str = [NSString localizedStringWithFormat:@"%@ storage left", remaining_str];
      }
      NSMutableDictionary* attrs =
        [[self.usage_label.attributedTitle attributesAtIndex:0 effectiveRange:NULL] mutableCopy];
      attrs[NSForegroundColorAttributeName] = [NSColor whiteColor];
      self.usage_label.attributedTitle =
        [[NSAttributedString alloc] initWithString:label_str attributes:attrs];
      self.usage_bar.hidden = NO;
      self.usage_label.hidden = NO;
    }
    else
    {
      self.usage_bar.hidden = YES;
      self.usage_label.hidden = YES;
    }
  }
}

- (IBAction)quotaClicked:(id)sender
{
  InfinitStateManager* manager = [InfinitStateManager sharedInstance];
  [manager webLoginTokenWithCompletionBlock:^(InfinitStateResult* result,
                                              NSString* token,
                                              NSString* email)
   {
     if (!result.success || !token.length || !email.length)
       return;
     NSString* url_str =
       [kInfinitWebProfileQuotaURL stringByAppendingFormat:@"&login_token=%@&email=%@",
        token, email];
     [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url_str]];
   }];
}

#pragma mark - IAViewController

- (BOOL)closeOnFocusLost
{
  [self.transaction_controller closeToolTips];
  return YES;
}

- (void)viewActive
{
  [super viewActive];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(userUpdated:)
                                               name:INFINIT_USER_STATUS_NOTIFICATION
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(linkAdded:)
                                               name:INFINIT_NEW_LINK_TRANSACTION_NOTIFICATION 
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(linkUpdated:)
                                               name:INFINIT_LINK_TRANSACTION_STATUS_NOTIFICATION
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(linkUpdated:)
                                               name:INFINIT_LINK_TRANSACTION_DATA_NOTIFICATION
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(linkUpdated:)
                                               name:INFINIT_LINK_TRANSACTION_DELETED_NOTIFICATION
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(transactionAdded:)
                                               name:INFINIT_NEW_PEER_TRANSACTION_NOTIFICATION
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(transactionUpdated:)
                                               name:INFINIT_PEER_TRANSACTION_STATUS_NOTIFICATION
                                             object:nil];
  // WORKAROUND stop flashing when changing subview by enabling layer backing. Need to do this once
  // the view has opened so that we get a shadow during opening animation.
  self.main_view.wantsLayer = YES;
  self.main_view.layer.masksToBounds = YES;
}

- (void)aboutToChangeView
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  if (self.current_controller == _transaction_controller)
    _transaction_controller.changing = YES;
  else if (self.current_controller == _link_controller)
    _link_controller.changing = YES;
  [_tooltip close];
  [_transaction_controller closeToolTips];
  [_transaction_controller markTransactionsRead];
}

@end
