//
//  IANotificationListCellView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/9/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IANotificationListCellView.h"

#import <surface/gap/enums.hh>

#import "IAAvatarManager.h"
#import "IAAvatarBadgeView.h"

@implementation IANotificationListCellView
{
  IAUser* _user;
  id<IANotificationListCellProtocol> _delegate;
}

//- Setup Cell -------------------------------------------------------------------------------------

- (BOOL)isOpaque
{
  return NO;
}

- (void)setUserFullName:(NSString*)fullname
{
  NSFont* name_font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica"
                                                                 traits:NSUnboldFontMask
                                                                 weight:7
                                                                   size:13.0];
  NSDictionary* attrs = [IAFunctions textStyleWithFont:name_font
                                        paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                                colour:IA_GREY_COLOUR(29.0)
                                                shadow:nil];
  self.user_full_name.attributedStringValue = [[NSAttributedString alloc] initWithString:fullname
                                                                              attributes:attrs];
}

- (void)setInformationField:(NSString*)message
{
  NSFont* file_font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica"
                                                                 traits:NSUnboldFontMask
                                                                 weight:0
                                                                   size:11.5];
  NSMutableParagraphStyle* para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
  para.lineBreakMode = NSLineBreakByTruncatingMiddle;
  NSDictionary* attrs = [IAFunctions textStyleWithFont:file_font
                                        paragraphStyle:para
                                                colour:IA_GREY_COLOUR(153.0)
                                                shadow:nil];
  self.information.attributedStringValue = [[NSAttributedString alloc] initWithString:message
                                                                           attributes:attrs];
}


- (void)setLastActionTime:(NSTimeInterval)timestamp
{
  NSMutableParagraphStyle* para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
  para.alignment = NSRightTextAlignment;
  NSDictionary* attrs = [IAFunctions textStyleWithFont:[NSFont systemFontOfSize:10.0]
                                        paragraphStyle:para
                                                colour:IA_GREY_COLOUR(206.0)
                                                shadow:nil];
  NSString* time_str = [IAFunctions relativeDateOf:timestamp];
  
  self.time_since_change.attributedStringValue = [[NSAttributedString alloc]
                                                  initWithString:time_str
                                                  attributes:attrs];
}

- (void)setAvatarFromAvatarManagerForUser:(IAUser*)user
{
  [self loadAvatarImage:[IAAvatarManager getAvatarForUser:user]];
}

- (void)loadAvatarImage:(NSImage*)image
{
  [self.avatar_view setAvatar:[IAFunctions makeRoundAvatar:image
                                                ofDiameter:55.0
                                     withBorderOfThickness:2.0
                                                  inColour:IA_GREY_COLOUR(255.0)
                                         andShadowOfRadius:2.0]];
}

- (void)setStatusIndicatorForTransaction:(IATransaction*)transaction
{
  switch (transaction.view_mode)
  {
    case TRANSACTION_VIEW_WAITING_ACCEPT:
      if (!transaction.from_me)
      {
        self.status_indicator.image = [IAFunctions imageNamed:@"icon-main-unread"];
        self.status_indicator.hidden = NO;
      }
      else
      {
        self.status_indicator.hidden = YES;
      }
      break;

    case TRANSACTION_VIEW_RUNNING:
      if (transaction.from_me)
      {
        self.status_indicator.image = [IAFunctions imageNamed:@"icon-main-upload"];
        self.status_indicator.toolTip = @"Uploading";
      }
      else
      {
        self.status_indicator.image = [IAFunctions imageNamed:@"icon-main-download"];
        self.status_indicator.toolTip = @"Downloading";
      }
      self.status_indicator.hidden = NO;
      break;
      
    case TRANSACTION_VIEW_FAILED:
      self.status_indicator.image = [IAFunctions imageNamed:@"icon-error"];
      self.status_indicator.toolTip = @"Failed";
      self.status_indicator.hidden = NO;
      break;
      
    case TRANSACTION_VIEW_CLOUD_BUFFERED:
      self.status_indicator.image = [IAFunctions imageNamed:@"conversation-icon-bufferised"];
      self.status_indicator.toolTip = @"Uploaded";
      self.status_indicator.hidden = NO;
      break;
      
    default:
      self.status_indicator.hidden = YES;
      break;
  }
}

- (void)setBadgeCount:(NSUInteger)count
{
  [self.badge_view.animator setBadgeCount:count];
}

- (void)setTotalTransactionProgress:(CGFloat)progress
{
  if (self.avatar_view.totalProgress < progress)
  {
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
     {
       context.duration = 1.0;
       [self.avatar_view.animator setTotalProgress:progress];
     }
                        completionHandler:^
     {
     }];
  }
  else
  {
    [self.avatar_view setTotalProgress:progress];
  }
}

- (void)setupCellWithTransaction:(IATransaction*)transaction
         withRunningTransactions:(NSUInteger)running_transactions
          andNotDoneTransactions:(NSUInteger)not_done_transactions
                     andProgress:(CGFloat)progress
                     andDelegate:(id<IANotificationListCellProtocol>)delegate
{
  self.status_indicator.toolTip = @"";
  _delegate = delegate;
  if (transaction.from_me)
    _user = transaction.recipient;
  else
    _user = transaction.sender;
  
  [self setUserFullName:_user.fullname];
  [self setAvatarFromAvatarManagerForUser:_user];
  if (_user.status == gap_user_status_online)
    [self.user_online setHidden:NO];
  else
    [self.user_online setHidden:YES];
  
  [self.status_indicator setHidden:YES];
  
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
    
    [self setInformationField:message];
    
    self.status_indicator.image = [IAFunctions imageNamed:@"icon-main-unread"];
    [self.status_indicator setHidden:NO];
  }
  else
  {
    if (transaction.files_count == 1)
    {
      [self setInformationField:transaction.files[0]];
    }
    else
    {
      [self setInformationField:[NSString stringWithFormat:@"%ld %@", transaction.files_count,
                                 NSLocalizedString(@"files", @"files")]];
    }
    [self setStatusIndicatorForTransaction:transaction];
  }
  
  [self setLastActionTime:transaction.last_edit_timestamp];
  
  // Configure avatar view
  [self setBadgeCount:not_done_transactions];
  [self.avatar_view setTotalProgress:progress];
  [self.avatar_view setDelegate:self];
}

//- Avatar Protocol --------------------------------------------------------------------------------

- (void)avatarHadAcceptClicked:(IANotificationAvatarView*)sender
{
  [_delegate notificationListCellAcceptClicked:self];
}

- (void)avatarHadCancelClicked:(IANotificationAvatarView*)sender
{
  [_delegate notificationListCellCancelClicked:self];
}

- (void)avatarHadRejectClicked:(IANotificationAvatarView*)sender
{
  [_delegate notificationListCellRejectClicked:self];
}

- (void)avatarClicked:(IANotificationAvatarView*)sender
{
  [_delegate notificationListCellAvatarClicked:self];
}

@end
