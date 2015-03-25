//
//  InfinitSearchRowModel.m
//  InfinitApplication
//
//  Created by Christopher Crone on 22/03/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitSearchRowModel.h"

#import <Gap/InfinitUserManager.h>

@interface InfinitSearchRowModel ()

@end

@implementation InfinitSearchRowModel

#pragma mark - Init

+ (instancetype)rowModelWithSearchPersonResult:(InfinitSearchPersonResult*)person
{
  return [[InfinitSearchRowModel alloc] _initWithSearchPersonResult:person emailIndex:NSNotFound];
}

+ (instancetype)rowModelWithSearchPersonResult:(InfinitSearchPersonResult*)person
                                    emailIndex:(NSInteger)index
{
  return [[InfinitSearchRowModel alloc] _initWithSearchPersonResult:person emailIndex:index];
}

- (instancetype)_initWithSearchPersonResult:(InfinitSearchPersonResult*)person
                       emailIndex:(NSInteger)index;
{
  if (self = [super init])
  {
    _avatar = person.avatar;
    _fullname = person.fullname;
    _user = person.infinit_user;
    if (person.device)
      _destination = person.device;
    else if (person.infinit_user)
      _destination = person.infinit_user;
    else if (index != NSNotFound)
      _destination = person.emails[index];
    else
      _destination = nil;
  }
  return self;
}

+ (instancetype)rowModelWithUser:(InfinitUser*)user
{
  return [[InfinitSearchRowModel alloc] _initWithUser:user];
}

- (instancetype)_initWithUser:(InfinitUser*)user
{
  if (self = [super init])
  {
    _user = user;
    _avatar = self.user.avatar;
    _fullname = self.user.fullname;
    _destination = self.user;
  }
  return self;
}

+ (instancetype)rowModelWithEmail:(NSString*)email
{
  return [[InfinitSearchRowModel alloc] _initWithEmail:email];
}

- (instancetype)_initWithEmail:(NSString*)email
{
  if (self = [super init])
  {
    _avatar = [NSImage imageNamed:@"send-icon-email-results"];
    _fullname = email;
    _user = nil;
    _destination = email;
  }
  return self;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object
{
  if (![object isKindOfClass:self.class])
    return NO;
  InfinitSearchRowModel* other = (InfinitSearchRowModel*)object;
  if ([self.destination isEqual:other.destination])
    return YES;
  return NO;
}

@end
