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
@synthesize rank = _rank;

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
        _rank = 5;
        _delegate = delegate;
        _user = nil;
        ABMultiValue* emails = [person valueForProperty:kABEmailProperty];
        _emails = [NSMutableArray array];
        if (emails.count > 0)
        {
            for (NSInteger i = 0; i < emails.count; i++)
            {
                NSString* email = [emails valueAtIndex:i];
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

- (void)checkAddressBookUserOnInfinit
{
    for (NSString* email in _emails)
    {
        NSMutableDictionary* mail_check = [NSMutableDictionary
                                           dictionaryWithDictionary:@{@"email": email}];
        [[IAGapState instance] getUserIdfromEmail:email
                                  performSelector:@selector(userIdFromEmailCallback:)
                                         onObject:self
                                         withData:mail_check];
    }
}

//- Email User -------------------------------------------------------------------------------------

- (id)initWithEmail:(NSString*)email
        andDelegate:(id<InfinitSearchPersonResultProtocol>)delegate
{
    if (self = [super init])
    {
        _rank = 10;
        _delegate = delegate;
        NSMutableDictionary* mail_check = [NSMutableDictionary
                                           dictionaryWithDictionary:@{@"email": email}];
        [[IAGapState instance] getUserIdfromEmail:email
                                  performSelector:@selector(userIdFromEmailCallback:)
                                         onObject:self
                                         withData:mail_check];
        _avatar = [IAFunctions makeAvatarFor:email];
        _emails = [NSMutableArray arrayWithObject:email];
        _fullname = email;
        _user = nil;
    }
    return self;
}

//- Infinit User -----------------------------------------------------------------------------------

- (id)initWithInfinitPerson:(IAUser*)user
                andDelegate:(id<InfinitSearchPersonResultProtocol>)delegate;
{
    if (self = [super init])
    {
        _rank = 1;
        _delegate = delegate;
        _user = user;
        if (_user.is_favourite)
            _rank += 10;
        if ([self userIsSwagger])
            _rank += 5;
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

- (BOOL)userIsSwagger
{
    NSArray* swaggers = [[IAGapState instance] swaggers_list];
    for (NSNumber* user_id in swaggers)
    {
        if (user_id.integerValue != 0 && _user.user_id.integerValue == user_id.integerValue)
            return YES;
    }
    return NO;
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
    
    if (user_id.integerValue != 0 &&
        user_id.integerValue != [[[IAGapState instance] self_id] integerValue])
    {
        _rank += 10;
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(avatarReceivedCallback:)
                                                   name:IA_AVATAR_MANAGER_AVATAR_FETCHED
                                                 object:nil];
        _user = [IAUserManager userWithId:user_id];
        if (_user.is_favourite)
            _rank += 10;
        if ([self userIsSwagger])
            _rank += 5;
        _fullname = _user.fullname;
        NSImage* infinit_avatar = [IAAvatarManager getAvatarForUser:_user];
        _avatar = infinit_avatar;
        [_delegate personUpdated:self];
    }
    [_delegate personNotOnInfinit:self];
}

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

- (NSComparisonResult)compare:(InfinitSearchPersonResult*)other
{
    if (self.rank > other.rank)
        return (NSComparisonResult)NSOrderedAscending;
    else if (self.rank < other.rank)
        return (NSComparisonResult)NSOrderedDescending;
    else // same score so sort alphabetically by name
        return [self.fullname compare:other.fullname options:NSCaseInsensitiveSearch];
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"<InfinitSearchPersonResult %p> name: %@\nidentifiers: %@\nrank: %ld",
            self,
            _fullname,
            _emails,
            _rank];
}

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:InfinitSearchPersonResult.class])
        return NO;

    if (self.infinit_user != nil && [object infinit_user] != nil &&
        self.infinit_user == [object infinit_user])
    {
        return YES;
    }
    else if ([self.fullname isEqualToString:[object fullname]])
    {
        return YES;
    }
    return NO;
}

@end
