//
//  IAFWAvatarManager.m
//  InfinitApplication
//
//  Created by infinit on 2/15/13.
//  Copyright (c) 2013 infinit. All rights reserved.
//

#import "IAAvatarManager.h"

#import <Gap/IAGapState.h>
#import <Gap/IAUserManager.h>

#import "IAFunctions.h"

@implementation IAAvatarManager

//- Initialisation ---------------------------------------------------------------------------------

- (id)init
{
    if (self = [super init])
    {
        _cache = [[NSMutableDictionary alloc] init];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(receivedAvatarNotification:)
                                                   name:IA_GAP_EVENT_USER_AVATAR_NOTIFICATION
                                                 object:nil];
    }
    return self;
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

+ (IAAvatarManager*)_instance
{
    static IAAvatarManager* instance = nil;
    if (instance == nil)
    {
        instance = [[IAAvatarManager alloc] init];
    }
    return instance;
}

//- Fetch Avatar -----------------------------------------------------------------------------------

+ (NSImage*)getAvatarForUser:(IAUser*)user
             andLoadIfNeeded:(BOOL)load
{
    return [[IAAvatarManager _instance] _getAvatarForUser:user
                                          andLoadIfNeeded:load];
}

- (NSImage*)_getAvatarForUser:(IAUser*)user
              andLoadIfNeeded:(BOOL)load
{
    if (user.user_id == nil)
    {
        IALog(@"%@ WARNING: User id is nil", self);
        return nil;
    }

    NSImage* res = [_cache objectForKey:user.user_id];

    if (res == nil) // Avatar not in cache so fetch it
    {
        res = [user fetchAvatar];
        if (res == nil) // Avatar not in Gap either so make a fake one
        {
            res = [IAFunctions makeAvatarFor:user.fullname];
        }
    }
    return res;
}

//- Callbacks --------------------------------------------------------------------------------------

- (void)receivedAvatarNotification:(NSNotification*)notification
{
    NSNumber* user_id = [notification.userInfo objectForKey:@"user_id"];
    if (user_id.unsignedIntValue == 0)
    {
        IALog(@"%@ WARNING: user_id is zero, unable to get avatar", self);
        return;
    }
    IAUser* user = [IAUserManager userWithId:user_id];
    NSImage* avatar = [user fetchAvatar];
    if (avatar == nil) // If we don't get an avatar, make one
        avatar = [IAFunctions makeAvatarFor:user.fullname];
    [_cache setObject:avatar forKey:user.user_id];
    NSDictionary* result = @{@"user": user, @"avatar": avatar};
    [[NSNotificationCenter defaultCenter] postNotificationName:IA_AVATAR_MANAGER_AVATAR_FETCHED
                                                        object:self
                                                      userInfo:result];
}

@end
