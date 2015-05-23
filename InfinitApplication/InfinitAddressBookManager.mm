//
//  InfinitAddressBookManager.m
//  InfinitApplication
//
//  Created by Christopher Crone on 21/05/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitAddressBookManager.h"

#import "IAUserPrefs.h"
#import "InfinitDesktopNotifier.h"

#import <Gap/InfinitStateManager.h>
#import <Gap/InfinitUserManager.h>
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
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contactJoined:)
                                                 name:INFINIT_CONTACT_JOINED_NOTIFICATION
                                               object:nil];
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
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
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^
  {
    [self _uploadContacts];
  });
}

- (void)_uploadContacts
{
  if (![self accessToAddressBook] ||
      [[[IAUserPrefs sharedInstance] prefsForKey:@"addressbook_uploaded"] isEqualTo:@YES])
  {
    return;
  }
  [[IAUserPrefs sharedInstance] setPref:@YES forKey:@"addressbook_uploaded"];
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

#pragma mark - Contact Joined

- (void)contactJoined:(NSNotification*)notification
{
  NSString* contact = notification.userInfo[kInfinitUserContact];
  ABPerson* person = [self personFromContact:contact];
  NSString* first_name = [person valueForProperty:kABFirstNameProperty];
  NSString* last_name = [person valueForProperty:kABLastNameProperty];
  NSMutableString* name = [[NSMutableString alloc] init];
  if (first_name.length)
    [name appendString:first_name];
  if (last_name.length)
    [name appendFormat:@"%@%@", (first_name.length ? @" " : @""), last_name];
  if (!name.length)
  {
    NSNumber* id_ = notification.userInfo[kInfinitUserId];
    InfinitUser* user = [[InfinitUserManager sharedInstance] userWithId:id_];
    name = [user.fullname mutableCopy];
  }
  if (!name.length)
  {
    ELLE_WARN("%s: unable to show contact joined notification, no name", self.description.UTF8String);
    return;
  }
  [[InfinitDesktopNotifier sharedInstance] desktopNotificationForContactJoined:name];
}

#pragma mark - Helpers

- (ABPerson*)personFromContact:(NSString*)contact
{
  if (![self accessToAddressBook] || !contact.length)
    return nil;
  NSMutableArray* search_elements = [NSMutableArray array];
  [search_elements addObject:[ABPerson searchElementForProperty:kABEmailProperty
                                                          label:nil
                                                            key:nil
                                                          value:contact
                                                     comparison:kABPrefixMatchCaseInsensitive]];
  NSMutableArray* res = [NSMutableArray array];
  for (ABSearchElement* search_element in search_elements)
  {
    [res addObjectsFromArray:[[ABAddressBook sharedAddressBook] recordsMatchingSearchElement:search_element]];
  }
  if (res.count)
    return res.firstObject;
  return nil;
}

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
