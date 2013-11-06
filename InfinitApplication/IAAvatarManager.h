//
//  IAFWAvatarManager.h
//  InfinitApplication
//
//  Created by infinit on 2/15/13.
//  Copyright (c) 2013 infinit. All rights reserved.
//
//  The avatar manager fetches and caches avatars as they're needed.

#import <Foundation/Foundation.h>

#import <Gap/IAUser.h>

#define IA_AVATAR_MANAGER_AVATAR_FETCHED @"IA_AVATAR_MANAGER_AVATAR_FETCHED"

@interface IAAvatarManager : NSObject
{
    NSMutableDictionary* _cache;
}

+ (NSImage*)getAvatarForUser:(IAUser*)user
             andLoadIfNeeded:(BOOL)load;

@end
