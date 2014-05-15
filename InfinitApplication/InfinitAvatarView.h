//
//  InfinitAvatarView.h
//  InfinitApplication
//
//  Created by Christopher Crone on 12/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface InfinitAvatarView : NSView

@property (nonatomic, setter = setAvatar:) NSImage* avatar;
@property (nonatomic, readwrite) CGFloat progress;

@end
