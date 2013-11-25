//
//  InfinitSearchPersonResult.m
//  InfinitApplication
//
//  Created by Christopher Crone on 21/11/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "InfinitSearchPersonResult.h"

#import "IAAvatarManager.h"
#import <Gap/IAUserManager.h>

@implementation InfinitSearchPersonResult
{
@private
    id<InfinitSearchPersonResultProtocol> _delegate;
}

//- Initialisation ---------------------------------------------------------------------------------

@synthesize avatar = _avatar;
@synthesize emails = _emails;
@synthesize fullname = _fullname;
@synthesize infinit_user = _user;

//- Addressbook User -------------------------------------------------------------------------------

- (void)dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (id)initWithABPerson:(ABPerson*)person
           andDelegate:(id<InfinitSearchPersonResultProtocol>)delegate;
{
    if (self = [super init])
    {
        _delegate = delegate;
        _user = nil;
        ABMultiValue* emails = [person valueForProperty:kABEmailProperty];
        _emails = [NSMutableArray array];
        if (emails.count > 0)
        {
            for (NSInteger i = 0; i < emails.count; i++)
            {
                NSString* email = [emails valueAtIndex:i];
                NSMutableDictionary* mail_check = [NSMutableDictionary
                                                   dictionaryWithDictionary:@{@"email": email}];
                [[IAGapState instance] getUserIdfromEmail:email
                                          performSelector:@selector(userIdFromEmailCallback:)
                                                 onObject:self
                                                 withData:mail_check];
                [_emails addObject:email];
            }
        }
        NSString* first_name = [person valueForProperty:kABFirstNameProperty];
        NSString* last_name = [person valueForProperty:kABLastNameProperty];
        if (first_name.length > 0 &&  last_name > 0)
            _fullname = [[NSString alloc] initWithFormat:@"%@ %@", first_name, last_name];
        else if (first_name > 0)
            _fullname = [[NSString alloc] initWithFormat:@"%@", first_name];
        else if (last_name > 0)
            _fullname = [[NSString alloc] initWithFormat:@"%@", last_name];
        else
            _fullname = @"Unknown";
        
        _avatar = [[NSImage alloc] initWithData:person.imageData];
        if (_avatar == nil)
            _avatar = [IAFunctions makeAvatarFor:_fullname];
    }
    return self;
}

- (void)userIdFromEmailCallback:(IAGapOperationResult*)result
{
    if (!result.success)
    {
        IALog(@"%@ WARNING: problem checking for user id", self);
        return;
    }
    NSDictionary* dict = result.data;
    NSNumber* user_id = [dict valueForKey:@"user_id"];
    
    if (user_id.integerValue != 0)
    {
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(avatarReceivedCallback:)
                                                   name:IA_AVATAR_MANAGER_AVATAR_FETCHED
                                                 object:nil];
        _user = [IAUserManager userWithId:user_id];
        NSImage* infinit_avatar = [IAAvatarManager getAvatarForUser:_user];
        // Only replace avatar if we didn't get one from the address book
        if (_avatar == nil)
            _avatar = infinit_avatar;
    }
}

//- Infinit User -----------------------------------------------------------------------------------

- (id)initWithInfinitPerson:(IAUser*)user
                andDelegate:(id<InfinitSearchPersonResultProtocol>)delegate;
{
    if (self = [super init])
    {
        _delegate = delegate;
        _user = user;
        _avatar = [IAAvatarManager getAvatarForUser:_user];
        _fullname = _user.fullname;
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(avatarReceivedCallback:)
                                                   name:IA_AVATAR_MANAGER_AVATAR_FETCHED
                                                 object:nil];
    }
    return self;
}


//- General Functions ------------------------------------------------------------------------------

- (void)avatarReceivedCallback:(NSNotification*)notification
{
    if (_user == nil)
        return;

    IAUser* user = [notification.userInfo objectForKey:@"user"];
    if (user != _user)
        return;
    
    _avatar = [notification.userInfo objectForKey:@"avatar"];
    [_delegate personGotNewAvatar:self];
}

- (NSComparisonResult)compare:(IAUser*)other
{
    return [self.fullname compare:other.fullname options:NSCaseInsensitiveSearch];
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"<%@> name: %@\nidentifiers: %@\n",
            self,
            _fullname,
            _emails];
}

@end
