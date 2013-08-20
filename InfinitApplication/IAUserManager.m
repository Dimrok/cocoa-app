//
//  IAUserManager.m
//  InfinitApplication
//
//  Created by Christopher Crone on 7/30/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAUserManager.h"

#import <Gap/IAGapState.h>

@implementation IAUserManager
{
@private
    id<IAUserManagerProtocol> _delegate;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithDelegate:(id<IAUserManagerProtocol>)delegate
{
    if (self = [super init])
    {
        _delegate = delegate;
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(onUserStatusNotification:)
                                                   name:IA_GAP_EVENT_USER_STATUS_NOTIFICATION
                                                 object:nil];
    }
    return self;
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObject:self];
}

//- Callback ---------------------------------------------------------------------------------------

- (void)onUserStatusNotification:(NSNotification*)notification
{
    NSNumber* user_id = [notification.userInfo objectForKey:@"user_id"];
    IAUser* user = [IAUser userWithId:user_id];
    if (user == nil)
        return;
    
    [_delegate userManager:self hasNewStatusFor:user];
}

@end
