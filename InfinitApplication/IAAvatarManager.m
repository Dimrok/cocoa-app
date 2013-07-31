//
//  IAFWAvatarManager.m
//  InfinitApplication
//
//  Created by infinit on 2/15/13.
//  Copyright (c) 2013 infinit. All rights reserved.
//

#import "IAAvatarManager.h"

#import <Gap/IAGapState.h>

#import "IAFunctions.h"

@implementation IAAvatarManager

//- Initialisation ---------------------------------------------------------------------------------

- (id)init
{
    if (self = [super init])
    {
        _download_queue = [[NSMutableSet alloc] init];
        _cache = [[NSMutableDictionary alloc] init];
    }
    return self;
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

- (NSString*)description
{
    return @"[AvatarManager]";
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
        res = [IAFunctions imageNamed:@"avatar_default"];
        if (load && [_download_queue member:user] == nil)
        {
            [_download_queue addObject:user];
            [user fetchAvatarForTarget:self];
        }
        
    }
    return res;
}

//- Callbacks --------------------------------------------------------------------------------------

- (void)user:(IAUser*)user
   gotAvatar:(NSImage*)avatar
{
    if (user == nil || user.user_id == nil || avatar == nil)
    {
        IALog(@"%@ WARNING: Got empty avatar or unknown user", self);
        return;
    }
    
    if ([_download_queue member:user] == nil)
    {
        IALog(@"%@ WARNING: Got unexpected avatar", self);
        return;
    }
    
    [_cache setObject:avatar
               forKey:user.user_id];
    [_download_queue removeObject:user];
    NSDictionary* result = @{@"user": user, @"avatar": avatar};
    [[NSNotificationCenter defaultCenter] postNotificationName:IA_AVATAR_MANAGER_AVATAR_FETCHED
                                                        object:self
                                                      userInfo:result];
    
}

- (void)user:(IAUser*)user
failedToGetAvatar:(NSError*)error
{
    IALog(@"%@ WARNING: Couldn't fetch avatar for %@: %@", self, user, error);
    [_download_queue removeObject:user.user_id];
}

@end
