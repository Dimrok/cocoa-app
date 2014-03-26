//
//  IANotificationAvatarView.h
//  InfinitApplication
//
//  Created by Christopher Crone on 8/21/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol IANotificationAvatarProtocol;

@interface IANotificationAvatarView : NSView

@property (nonatomic, setter = setAvatar:) NSImage* avatar;
@property (nonatomic, setter = setDelegate:) id<IANotificationAvatarProtocol> delegate;
@property (nonatomic, setter = setTotalProgress:) CGFloat totalProgress;

@end


@protocol IANotificationAvatarProtocol <NSObject>

- (void)avatarClicked:(IANotificationAvatarView*)sender;

@end