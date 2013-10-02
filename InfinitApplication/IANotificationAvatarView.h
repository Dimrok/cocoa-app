//
//  IANotificationAvatarView.h
//  InfinitApplication
//
//  Created by Christopher Crone on 8/21/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol IANotificationAvatarProtocol;

typedef enum __IANotificationAvatarMode
{
    AVATAR_VIEW_NORMAL = 0,
    AVATAR_VIEW_ACCEPT_REJECT = 1,
    AVATAR_VIEW_CANCEL = 2
} IANotificationAvatarMode;

@interface IANotificationAvatarView : NSView

@property (nonatomic, setter = setAvatar:) NSImage* avatar;
@property (nonatomic, setter = setDelegate:) id<IANotificationAvatarProtocol> delegate;
@property (nonatomic, setter = setViewMode:) IANotificationAvatarMode mode;
@property (nonatomic, setter = setTotalProgress:) CGFloat totalProgress;

@end


@protocol IANotificationAvatarProtocol <NSObject>

- (void)avatarHadAcceptClicked:(IANotificationAvatarView*)sender;
- (void)avatarHadCancelClicked:(IANotificationAvatarView*)sender;
- (void)avatarHadRejectClicked:(IANotificationAvatarView*)sender;
- (void)avatarClicked:(IANotificationAvatarView*)sender;

@end