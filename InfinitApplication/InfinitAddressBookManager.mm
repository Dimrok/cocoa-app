//
//  InfinitAddressBookManager.m
//  InfinitApplication
//
//  Created by Christopher Crone on 21/05/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitAddressBookManager.h"

#import "IAUserPrefs.h"

#import <Gap/InfinitStateManager.h>
#import <Gap/NSString+email.h>
#import <Gap/NSString+PhoneNumber.h>

#import <AddressBook/AddressBook.h>

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("OSX.AddressBookManager");

static InfinitAddressBookManager* _instance = nil;
static dispatch_once_t _instance_token = 0;

@implementation InfinitAddressBookManager

#pragma mark - Init

- (id)init
{
  NSCAssert(_instance == nil, @"Use sharedInstance.");
  if (self = [super init])
  {
    if ([self accessToAddressBook] &&
        ![[[IAUserPrefs sharedInstance] prefsForKey:@"addressbook_uploaded"] isEqualTo:@YES])
    {
      [[IAUserPrefs sharedInstance] setPref:@YES forKey:@"addressbook_uploaded"];
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^
      {
        [self uploadContacts];
      });
    }
  }
  return self;
}

+ (instancetype)sharedInstance
{
  dispatch_once(&_instance_token, ^
  {
    _instance = [[InfinitAddressBookManager alloc] init];
  });
  return _instance;
}

#pragma mark - Upload

- (void)uploadContacts
{
  NSMutableArray* res = [NSMutableArray array];
  for (ABPerson* person in [ABAddressBook sharedAddressBook].people)
  {
    NSDictionary* dict = [self dictionaryFromABPerson:person];
    if (dict)
      [res addObject:dict];
  }
  if (!res.count)
    return;
  ELLE_LOG("%s: uploading %lu contacts", self.description.UTF8String, res.count);
  [[InfinitStateManager sharedInstance] uploadContacts:res completionBlock:nil];
}

#pragma mark - Helpers

- (NSDictionary*)dictionaryFromABPerson:(ABPerson*)person
{
  NSMutableArray* emails = [NSMutableArray array];
  NSMutableArray* numbers = [NSMutableArray array];
  ABMultiValue* contact_emails = [person valueForProperty:kABEmailProperty];
  if (contact_emails.count)
  {
    for (NSUInteger i = 0; i < contact_emails.count; i++)
    {
      NSString* email = [contact_emails valueAtIndex:i];
      if (email.infinit_isEmail)
        [emails addObject:email];
    }
  }
  ABMultiValue* contact_numbers = [person valueForProperty:kABPhoneProperty];
  if (contact_numbers.count)
  {
    for (NSUInteger i = 0; i < contact_numbers.count; i++)
    {
      NSString* number = [contact_numbers valueAtIndex:i];
      if (number.infinit_isPhoneNumber)
        [numbers addObject:number];
    }
  }
  if (!emails.count && !numbers.count)
    return nil;
  return @{@"email_addresses": emails, @"phone_numbers": numbers};
}

- (BOOL)accessToAddressBook
{
  if ([ABAddressBook sharedAddressBook] == nil)
    return NO;
  else
    return YES;
}

@end
