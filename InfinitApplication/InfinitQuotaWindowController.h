//
//  InfinitQuotaWindowController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 12/05/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol InfinitQuotaWindowProtocol;

@interface InfinitQuotaWindowController : NSWindowController

@property (nonatomic, weak) id<InfinitQuotaWindowProtocol> delegate;

- (void)showWithTitleText:(NSString*)title
                  details:(NSString*)details
      inviteButtonEnabled:(BOOL)invite_enabled;

@end

@protocol InfinitQuotaWindowProtocol <NSObject>

- (void)gotCancel;
- (void)gotInvite;
- (void)gotUpgrade;

@end
