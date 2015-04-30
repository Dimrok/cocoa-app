//
//  InfinitSearchPersonResult.m
//  InfinitApplication
//
//  Created by Christopher Crone on 21/11/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "InfinitSearchPersonResult.h"

#import <Gap/InfinitUserManager.h>

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("OSX.SearchPersonResult");

@implementation InfinitSearchPersonResult
{
@private
  // WORKAROUND: 10.7 doesn't allow weak references to certain classes (like NSViewController)
  __unsafe_unretained id<InfinitSearchPersonResultProtocol> _delegate;
}

#pragma mark - Infinit

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

#pragma mark - Address Book User

+ (instancetype)personWithABPerson:(ABPerson*)person
                       andDelegate:(id<InfinitSearchPersonResultProtocol>)delegate
{
  return [[InfinitSearchPersonResult alloc] initWithABPerson:person andDelegate:delegate];
}

- (id)initWithABPerson:(ABPerson*)person
           andDelegate:(id<InfinitSearchPersonResultProtocol>)delegate;
{
  if (self = [super init])
  {
    _rank = address_book_match_rank;
    _delegate = delegate;
    _device = nil;
    _infinit_user = nil;
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
          [self.emails addObject:email];
        }
      }
    }
    NSString* first_name = [person valueForProperty:kABFirstNameProperty];
    NSString* last_name = [person valueForProperty:kABLastNameProperty];
    if (first_name.length && last_name.length)
      _fullname = [[NSString alloc] initWithFormat:@"%@ %@", first_name, last_name];
    else if (first_name.length)
      _fullname = [[NSString alloc] initWithFormat:@"%@", first_name];
    else if (last_name.length)
      _fullname = [[NSString alloc] initWithFormat:@"%@", last_name];
    else
      _fullname = @"Unknown";
    
    _avatar = [[NSImage alloc] initWithData:person.imageData];
    if (_avatar == nil)
      _avatar = [IAFunctions makeAvatarFor:_fullname];
  }
  return self;
}

#pragma mark - Email User

- (void)email:(NSString*)email
isInfinitUser:(InfinitUser*)user
{
  _rank += infinit_match_rank;
  [NSNotificationCenter.defaultCenter addObserver:self
                                         selector:@selector(avatarReceivedCallback:)
                                             name:INFINIT_USER_AVATAR_NOTIFICATION
                                           object:nil];
  _infinit_user = user;
  if (self.infinit_user.favorite)
    _rank += infinit_favourite_rank;
  if (self.infinit_user.swagger)
    _rank += infinit_swagger_rank;
  _fullname = self.infinit_user.fullname;
  _avatar = self.infinit_user.avatar;
}

#pragma mark - Infinit User

+ (instancetype)personWithInfinitUser:(InfinitUser*)user
                          andDelegate:(id<InfinitSearchPersonResultProtocol>)delegate
{
  return [[InfinitSearchPersonResult alloc] initWithInfinitPerson:user andDelegate:delegate];
}

- (id)initWithInfinitPerson:(InfinitUser*)user
                andDelegate:(id<InfinitSearchPersonResultProtocol>)delegate;
{
  if (self = [super init])
  {
    _rank = infinit_match_rank;
    _delegate = delegate;
    _device = nil;
    _infinit_user = user;
    if (self.infinit_user.favorite)
      _rank += infinit_favourite_rank;
    if (self.infinit_user.swagger)
      _rank += infinit_swagger_rank;
    else
      _rank += infinit_match_rank;
    _avatar = self.infinit_user.avatar;
    _fullname = self.infinit_user.fullname;
  }
  return self;
}

#pragma mark - Device

+ (instancetype)personWithDevice:(InfinitDevice*)device
                     andDelegate:(id<InfinitSearchPersonResultProtocol>)delegate
{
  return [[InfinitSearchPersonResult alloc] initWithDevice:device andDelegate:delegate];
}

- (id)initWithDevice:(InfinitDevice*)device
         andDelegate:(id<InfinitSearchPersonResultProtocol>)delegate
{
  if (self = [super init])
  {
    _rank = infinit_device_rank;
    _delegate = delegate;
    _device = device;
    _emails = nil;
    _fullname = self.device.name;
    _infinit_user = [InfinitUserManager sharedInstance].me;
    switch (self.device.type)
    {
      case InfinitDeviceTypeAndroid:
        _avatar = [NSImage imageNamed:@"send-icon-device-android-avatar"];
        break;
      case InfinitDeviceTypeiPhone:
      case InfinitDeviceTypeiPad:
        _avatar = [NSImage imageNamed:@"send-icon-device-ios-avatar"];
        break;
      case InfinitDeviceTypeMacLaptop:
        _avatar = [NSImage imageNamed:@"send-icon-device-mac-avatar"];
        break;
      case InfinitDeviceTypeMacDesktop:
      case InfinitDeviceTypePCWindows:
        _avatar = [NSImage imageNamed:@"send-icon-device-windows-avatar"];
        break;
      case InfinitDeviceTypePCLinux:
      case InfinitDeviceTypeUnknown:
      default:
        _avatar = [NSImage imageNamed:@"send-icon-device-default-avatar"];
        break;
    }
  }
  return self;
}

#pragma mark - General

- (void)avatarReceivedCallback:(NSNotification*)notification
{
  if (!self.infinit_user)
    return;
  NSNumber* id_ = notification.userInfo[kInfinitUserId];
  InfinitUser* user = [[InfinitUserManager sharedInstance] userWithId:id_];
  if (![user isEqual:self.infinit_user])
    return;
  
  _avatar = user.avatar;
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
          self.fullname,
          self.infinit_user,
          self.emails,
          self.rank];
}

- (BOOL)isEqual:(id)object
{
  if (![object isKindOfClass:InfinitSearchPersonResult.class])
    return NO;
  
  if (self.infinit_user && [object infinit_user] &&
      [self.infinit_user isEqual:[object infinit_user]])
  {
    return YES;
  }
  else if (self.device && [object device] && [self.device isEqual:[object device]])
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
