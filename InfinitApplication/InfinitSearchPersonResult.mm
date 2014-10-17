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

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("OSX.SearchPersonResult");

@implementation InfinitSearchPersonResult
{
@private
  // WORKAROUND: 10.7 doesn't allow weak references to certain classes (like NSViewController)
  __unsafe_unretained id<InfinitSearchPersonResultProtocol> _delegate;
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
  [self cancelCallbacks];
}

- (void)cancelCallbacks
{
  _delegate = nil;
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (id)initWithABPerson:(ABPerson*)person
           andDelegate:(id<InfinitSearchPersonResultProtocol>)delegate;
{
  if (self = [super init])
  {
    _rank = address_book_match_rank;
    _delegate = delegate;
    _user = nil;
    ABMultiValue* emails = [person valueForProperty:kABEmailProperty];
    _emails = [NSMutableArray array];
    if (emails.count > 0)
    {
      for (NSInteger i = 0; i < emails.count; i++)
      {
        NSString* email = [emails valueAtIndex:i];
        // Remove Facebook mails.
        if ([email rangeOfString:@"@facebook.com"].location == NSNotFound)
        {
          [_emails addObject:email];
        }
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

//- Email User -------------------------------------------------------------------------------------

- (void)email:(NSString*)email
isInfinitUser:(IAUser*)user
{
  _rank += infinit_match_rank;
  [NSNotificationCenter.defaultCenter addObserver:self
                                         selector:@selector(avatarReceivedCallback:)
                                             name:IA_AVATAR_MANAGER_AVATAR_FETCHED
                                           object:nil];
  _user = user;
  if (_user.favourite)
    _rank += infinit_favourite_rank;
  if ([self userIsSwagger])
    _rank += infinit_swagger_rank;
  _fullname = _user.fullname;
  NSImage* infinit_avatar = [IAAvatarManager getAvatarForUser:_user];
  _avatar = infinit_avatar;
}

//- Infinit User -----------------------------------------------------------------------------------

- (id)initWithInfinitPerson:(IAUser*)user
                andDelegate:(id<InfinitSearchPersonResultProtocol>)delegate;
{
  if (self = [super init])
  {
    _rank = infinit_match_rank;
    _delegate = delegate;
    _user = user;
    if (_user.favourite)
      _rank += infinit_favourite_rank;
    if ([self userIsSwagger])
      _rank += infinit_swagger_rank;
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
  NSArray* swaggers = [IAUserManager swaggerList];
  if ([swaggers containsObject:_user])
    return YES;
  else
    return NO;
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
  return [NSString stringWithFormat:@"<InfinitSearchPersonResult %p> name: %@\nuser: %@\nemails: %@\nrank: %ld",
          self,
          _fullname,
          _user,
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
