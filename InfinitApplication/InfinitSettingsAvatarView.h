//
//  InfinitSettingsAvatarView.h
//  InfinitApplication
//
//  Created by Christopher Crone on 22/08/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol InfinitSettingsAvatarProtocol;

@interface InfinitSettingsAvatarView : NSView <NSDraggingDestination>

@property (nonatomic, readwrite) id<InfinitSettingsAvatarProtocol> delegate;
@property (nonatomic, readwrite) NSImage* image;
@property (nonatomic, readwrite) BOOL uploading;

@end

@protocol InfinitSettingsAvatarProtocol <NSObject>

- (void)settingsAvatarGotImage:(NSImage*)image;

@end