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

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithFrame:(NSRect)frameRect
{
    if (self = [super initWithFrame:frameRect])
    {
    }
    return self;
}


//- Setup Cell -------------------------------------------------------------------------------------

- (void)setUserFullName:(NSString*)fullname
{
    NSDictionary* attrs = [IAFunctions textStyleWithFont:[NSFont boldSystemFontOfSize:12.0]
                                          paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                                  colour:IA_GREY_COLOUR(29.0)
                                                  shadow:nil];
    self.user_full_name.attributedStringValue = [[NSAttributedString alloc] initWithString:fullname
                                                                                attributes:attrs];
}

- (void)setFileName:(NSString*)file_name
{
    NSDictionary* attrs = [IAFunctions textStyleWithFont:[NSFont systemFontOfSize:11.5]
                                          paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                                  colour:IA_GREY_COLOUR(153.0)
                                                  shadow:nil];
    self.file_name.attributedStringValue = [[NSAttributedString alloc] initWithString:file_name
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
    [self.avatar_view setAvatar:[IAFunctions makeRoundAvatar:[IAAvatarManager getAvatarForUser:user
                                                                     andLoadIfNeeded:YES]
                                        ofDiameter:50.0
                             withBorderOfThickness:2.0
                                          inColour:IA_GREY_COLOUR(255.0)
                                 andShadowOfRadius:1.0]];
}

- (void)setTransferStatusIcon:(IATransactionViewMode)view_mode
{
    switch (view_mode)
    {
        case TRANSACTION_VIEW_FAILED:
            self.transfer_status.image = [IAFunctions imageNamed:@"icon-error"];
            [self.transfer_status setHidden:NO];
            break;
            
        case TRANSACTION_VIEW_FINISHED:
            self.transfer_status.image = [IAFunctions imageNamed:@"icon-check"];
            [self.transfer_status setHidden:NO];
            break;
            
        default:
            [self.transfer_status setHidden:YES];
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

- (void)setAvatarMode:(IATransactionViewMode)view_mode
           whenFromMe:(BOOL)from_me
{
    switch (view_mode)
    {            
        case TRANSACTION_VIEW_WAITING_ACCEPT:
            if (from_me)
                [self.avatar_view setViewMode:AVATAR_VIEW_CANCEL];
            else
                [self.avatar_view setViewMode:AVATAR_VIEW_ACCEPT_REJECT];
            break;
            
        case TRANSACTION_VIEW_RUNNING:
            [self.avatar_view setViewMode:AVATAR_VIEW_CANCEL];
            break;
            
        default:
            [self.avatar_view setViewMode:AVATAR_VIEW_NORMAL];
            break;
    }
}

- (void)setupCellWithTransaction:(IATransaction*)transaction
         withRunningTransactions:(NSUInteger)count
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
    
    if (transaction.files_count == 1)
    {
        [self setFileName:transaction.files[0]];
    }
    else
    {
        [self setFileName:[NSString stringWithFormat:@"%ld %@", transaction.files_count,
                           NSLocalizedString(@"files", @"files")]];
    }
    [self setLastActionTime:transaction.last_edit_timestamp];
    [self setTransferStatusIcon:transaction.view_mode];
    
    // Configure avatar view
    [self setBadgeCount:count];
    [self.avatar_view setTotalProgress:progress];
    [self setAvatarMode:transaction.view_mode
             whenFromMe:transaction.from_me];
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
