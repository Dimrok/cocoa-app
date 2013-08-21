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
    IATransaction* _transaction;
    IAUser* _user;
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
    NSDictionary* attrs = [IAFunctions textStyleWithFont:[NSFont systemFontOfSize:11.0]
                                          paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                                  colour:IA_GREY_COLOUR(153.0)
                                                  shadow:nil];
    NSString* res = file_name;
    NSInteger str_len = 25;
    if (res.length > str_len)
    {
        NSString* file_extension = [file_name pathExtension];
        NSString* temp = [[file_name stringByDeletingPathExtension]
                          substringToIndex:(str_len - file_extension.length)];
        res = [temp stringByAppendingFormat:@"...%@", file_extension];
    }
    self.file_name.attributedStringValue = [[NSAttributedString alloc] initWithString:res
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
    NSImage* avatar = [IAFunctions makeRoundAvatar:[IAAvatarManager getAvatarForUser:user
                                                                     andLoadIfNeeded:YES]
                                        ofDiameter:50.0
                             withBorderOfThickness:3.0
                                          inColour:IA_GREY_COLOUR(255.0)
                                 andShadowOfRadius:1.0];
    self.avatar.image = avatar;
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
    if (count == 0)
        return;
    
    [self.badge_view setBadgeCount:count];
}

- (void)setupCellWithTransaction:(IATransaction*)transaction
          andRunningTransactions:(NSUInteger)count
{
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
    
    _transaction = transaction;
    [self setFileName:transaction.first_filename];
    [self setLastActionTime:transaction.last_edit_timestamp];
    [self setTransferStatusIcon:transaction.view_mode];
    [self setBadgeCount:count];
}

@end
