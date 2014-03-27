//
//  IANotificationListCellView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/9/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IANotificationListCellView.h"

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

- (void)resetCursorRects
{
    [super resetCursorRects];
    NSCursor* cursor = [NSCursor pointingHandCursor];
    [self addCursorRect:self.bounds cursor:cursor];
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

- (void)setAvatarForUser:(IAUser*)user
{
    [self.avatar_view setAvatar:[IAFunctions makeRoundAvatar:[IAAvatarManager getAvatarForUser:user]
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
          break;
        case TRANSACTION_VIEW_RUNNING:
            if (transaction.from_me)
                self.status_indicator.image = [IAFunctions imageNamed:@"icon-main-upload"];
            else
                self.status_indicator.image = [IAFunctions imageNamed:@"icon-main-download"];
            [self.status_indicator setHidden:NO];
            break;
            
        case TRANSACTION_VIEW_FAILED:
            self.status_indicator.image = [IAFunctions imageNamed:@"icon-error"];
            [self.status_indicator setHidden:NO];
            break;
            
        case TRANSACTION_VIEW_FINISHED:
            self.status_indicator.image = [IAFunctions imageNamed:@"icon-check"];
            [self.status_indicator setHidden:NO];
            break;
            
        default:
            [self.status_indicator setHidden:YES];
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
          andUnreadNotifications:(NSUInteger)unread_notifications
                     andProgress:(CGFloat)progress
                     andDelegate:(id<IANotificationListCellProtocol>)delegate
{
    _delegate = delegate;
    if (transaction.from_me)
        _user = transaction.recipient;
    else
        _user = transaction.sender;

    [self setUserFullName:_user.fullname];
    [self setAvatarForUser:_user];
    if (_user.status == gap_user_status_online)
        [self.user_online setHidden:NO];
    else
        [self.user_online setHidden:YES];
    
    [self.status_indicator setHidden:YES];
    
    if (unread_notifications + running_transactions > 1)
    {
        NSString* message;
        if (unread_notifications == 0)
        {
            message = [NSString stringWithFormat:
                       @"%ld %@", running_transactions,
                                  NSLocalizedString(@"running transfers", @"running transfers")];
        }
        else if(running_transactions == 0)
        {
            message = [NSString stringWithFormat:
                       @"%ld %@", unread_notifications,
                                  NSLocalizedString(@"unread notifications", @"unread notifications")];
        }
        else
        {
            message = [NSString stringWithFormat:
                       @"%ld %@ %ld %@", unread_notifications,
                                         NSLocalizedString(@"unread and", @"unread and"),
                                         running_transactions,
                                         NSLocalizedString(@"running", @"running")];
        }
        
        [self setInformationField:message];
        
        self.status_indicator.image = [IAFunctions imageNamed:@"icon-main-unread"];
        [self.status_indicator setHidden:NO];
    }
    // XXX Unread transaction is not latest. Should handle this better.
    else if (running_transactions == 0 && unread_notifications == 1 &&
             !transaction.is_new && !transaction.needs_action)
    {

        NSString* message = NSLocalizedString(@"1 unread notification",
                                              @"1 unread notification");
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
    [self setBadgeCount:running_transactions];
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
