//
//  InfinitTransactionCellView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 12/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitTransactionCellView.h"

#import <Gap/InfinitTime.h>
#import <Gap/InfinitUserManager.h>

@implementation InfinitTransactionCellView
{
  InfinitUser* _user;
  NSTrackingArea* _tracking_area;
  BOOL _hover;
  NSUInteger _unread;

  NSString* _last_indicator_text;
  NSString* _last_indicator_tooltip;
  NSImage* _last_indicator_image;
  BOOL _last_indicator_hidden;
}

//- Mouse Tracking ---------------------------------------------------------------------------------

- (void)createTrackingArea
{
  _tracking_area = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                options:(NSTrackingMouseEnteredAndExited |
                                                         NSTrackingActiveAlways)
                                                  owner:self
                                               userInfo:nil];

  [self addTrackingArea:_tracking_area];

  NSPoint mouse_loc = self.window.mouseLocationOutsideOfEventStream;
  mouse_loc = [self convertPoint:mouse_loc fromView:nil];
  if (NSPointInRect(mouse_loc, self.bounds))
    [self mouseEntered:nil];
  else
    [self mouseExited:nil];
}

- (void)updateTrackingAreas
{
  [self removeTrackingArea:_tracking_area];
  [self createTrackingArea];
  [super updateTrackingAreas];
}

- (void)mouseEntered:(NSEvent*)theEvent
{
  _hover = YES;
  [self setIndicatorOnHover];
}

- (void)mouseExited:(NSEvent*)theEvent
{
  _hover = NO;
  [self setIndicatorOnUnhover];
}

//- Drawing ----------------------------------------------------------------------------------------

- (BOOL)isOpaque
{
  return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
  if (_unread > 0)
    [IA_GREY_COLOUR(255) set];
  else
    [IA_GREY_COLOUR(248) set];
  NSRectFill(self.bounds);
  NSBezierPath* dark_line =
    [NSBezierPath bezierPathWithRect:NSMakeRect(0.0, 1.0, NSWidth(self.bounds), 1.0)];
  [IA_GREY_COLOUR(230) set];
  [dark_line fill];
  NSBezierPath* light_line =
    [NSBezierPath bezierPathWithRect:NSMakeRect(0.0, 0.0, NSWidth(self.bounds), 1.0)];
  [IA_GREY_COLOUR(255) set];
  [light_line fill];
}

//- Setup Cell -------------------------------------------------------------------------------------

- (void)setBadgeCount:(NSUInteger)count
{
  self.badge.count = count;
}

- (void)setAvatarFromAvatarManagerForUser:(InfinitUser*)user
{
  [self loadAvatarImage:user.avatar];
}

- (void)loadAvatarImage:(NSImage*)image
{
  [self.avatar_view setAvatar:[IAFunctions makeRoundAvatar:image
                                                ofDiameter:48.0
                                     withBorderOfThickness:0.0
                                                  inColour:IA_GREY_COLOUR(255.0)
                                         andShadowOfRadius:0.0]];
}

- (void)setIndicatorOnHover
{
  self.indicator.image = [IAFunctions imageNamed:@"main-icon-expand"];
  self.indicator.hidden = NO;
  self.indicator.toolTip = NSLocalizedString(@"Click to expand", nil);
  self.indicator_text.stringValue = NSLocalizedString(@"Open", nil);
}

- (void)setIndicatorOnUnhover
{
  self.indicator.hidden = _last_indicator_hidden;
  self.indicator.image = _last_indicator_image;
  self.indicator.toolTip = _last_indicator_tooltip;
  self.indicator_text.stringValue = _last_indicator_text;
}

- (void)setStatusIndicatorForTransaction:(InfinitPeerTransaction*)transaction
{
  switch (transaction.status)
  {
    case gap_transaction_waiting_accept:
      if (transaction.receivable)
      {
        self.indicator.image = [IAFunctions imageNamed:@"main-icon-unread"];
        self.indicator.hidden = NO;
      }
      else
      {
        self.indicator.hidden = YES;
      }
      break;

    case gap_transaction_connecting:
    case gap_transaction_transferring:
      if (transaction.sender.is_self)
      {
        self.indicator.image = [IAFunctions imageNamed:@"main-icon-upload"];
        self.indicator.toolTip = @"Uploading";
      }
      else
      {
        self.indicator.image = [IAFunctions imageNamed:@"main-icon-download"];
        self.indicator.toolTip = @"Downloading";
      }
      self.indicator.hidden = NO;
      break;

    case gap_transaction_failed:
      self.indicator.image = [IAFunctions imageNamed:@"main-icon-error"];
      self.indicator.toolTip = @"Failed";
      self.indicator.hidden = NO;
      break;

    case gap_transaction_cloud_buffered:
      self.indicator.image = [IAFunctions imageNamed:@"main-icon-bufferised"];
      self.indicator.toolTip = @"Uploaded";
      self.indicator.hidden = NO;
      break;

    default:
      self.indicator.hidden = YES;
      break;
  }
  _last_indicator_hidden = self.indicator.isHidden;
}

- (void)setProgress:(CGFloat)progress
{
  if (self.avatar_view.progress < progress)
  {
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
     {
       context.duration = 1.0;
       [self.avatar_view.animator setProgress:progress];
     }
                        completionHandler:^
     {
     }];
  }
  else
  {
    self.avatar_view.progress = progress;
  }
}

- (void)setupCellWithTransaction:(InfinitPeerTransaction*)transaction
         withRunningTransactions:(NSUInteger)running_transactions
          andNotDoneTransactions:(NSUInteger)not_done_transactions
           andUnreadTransactions:(NSUInteger)unread
                     andProgress:(CGFloat)progress
{
  _unread = unread;
  self.indicator.toolTip = @"";
  if (transaction.sender.is_self)
    _user = transaction.recipient;
  else
    _user = transaction.sender;

  self.fullname.stringValue = _user.fullname;
  [self setAvatarFromAvatarManagerForUser:_user];
  if (_user.status == gap_user_status_online)
    [self.user_status setHidden:NO];
  else
    [self.user_status setHidden:YES];

  [self.indicator setHidden:YES];

  if (not_done_transactions > 1)
  {
    NSString* message;
    if (not_done_transactions - running_transactions == 0)
    {
      message = [NSString stringWithFormat:@"%ld %@", running_transactions,
                 NSLocalizedString(@"running transfers", nil)];
    }
    else if (running_transactions == 0)
    {
      message = [NSString stringWithFormat:@"%ld %@", not_done_transactions - running_transactions,
                 NSLocalizedString(@"pending transfers", nil)];
    }
    else
    {
      message = [NSString stringWithFormat:@"%ld %@ %ld %@", not_done_transactions - running_transactions,
                 NSLocalizedString(@"pending and", nil),
                 running_transactions,
                 NSLocalizedString(@"running", nil)];
    }

    self.information.stringValue = message;

    self.indicator.image = [IAFunctions imageNamed:@"main-icon-unread"];
    [self.indicator setHidden:NO];
  }
  else
  {
    if (transaction.files.count == 1)
    {
      self.information.stringValue = transaction.files[0];
    }
    else
    {
      self.information.stringValue = [NSString stringWithFormat:@"%ld %@", transaction.files.count,
                                      NSLocalizedString(@"files", @"files")];
    }
    [self setStatusIndicatorForTransaction:transaction];
  }

  self.indicator_text.stringValue = [InfinitTime relativeDateOf:transaction.mtime
                                                   longerFormat:NO];

  _last_indicator_image = self.indicator.image;
  _last_indicator_text = self.indicator_text.stringValue;
  _last_indicator_tooltip = self.indicator.toolTip;

  // Configure avatar view
  self.badge.count = not_done_transactions;
  self.avatar_view.progress = progress;
}

@end
