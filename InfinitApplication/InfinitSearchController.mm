//
//  InfinitSearchController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 21/11/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "InfinitSearchController.h"

#import "IAUserPrefs.h"
#import "InfinitAddressBookManager.h"
#import "InfinitMetricsManager.h"

#import <Gap/InfinitDeviceManager.h>
#import <Gap/InfinitStateManager.h>
#import <Gap/InfinitStateResult.h>
#import <Gap/InfinitUserManager.h>

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("OSX.SearchController");

@interface InfinitSearchController ()

@property (nonatomic, readonly) NSArray* all_address_book;
@property (nonatomic, readonly) NSMutableArray* address_book_results;
@property (nonatomic, readonly) NSArray* all_devices;
@property (nonatomic, readonly) NSMutableArray* device_results;
@property (nonatomic, readonly) NSArray* all_swaggers;
@property (nonatomic, readonly) NSMutableArray* swagger_results;
@property (nonatomic, readonly) InfinitSearchPersonResult* email_result;

@end

@implementation InfinitSearchController
{
@private
  // WORKAROUND: 10.7 doesn't allow weak references to certain classes (like NSViewController)
  __unsafe_unretained id<InfinitSearchControllerProtocol> _delegate;

  BOOL _searching_email;
  BOOL _has_searched;
}

#pragma mark - Init

@synthesize result_list = _result_list;

- (id)initWithDelegate:(id<InfinitSearchControllerProtocol>)delegate
{
  if (self = [super init])
  {
    _delegate = delegate;
    [self performSelectorInBackground:@selector(cacheInitialResults) withObject:nil];
  }
  return self;
}

- (void)dealloc
{
  [self cancelCallbacks];
}

- (void)cancelCallbacks
{
  _delegate = nil;
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  for (InfinitSearchPersonResult* person in self.result_list)
  {
    [person cancelCallbacks];
  }
}

#pragma mark - Address Book

- (BOOL)accessToAddressBook
{
  if ([ABAddressBook sharedAddressBook] == nil)
  {
    ELLE_LOG("%s: no access to addressbook", self.description.UTF8String);
    return NO;
  }
  else
  {
    ELLE_DEBUG("%s: addressbook accessible", self.description.UTF8String);
    [[InfinitAddressBookManager sharedInstance] uploadContacts];
    return YES;
  }
}

- (void)firstAddressbookAccess
{
  [[IAUserPrefs sharedInstance] setPref:@"1" forKey:@"accessed_addressbook"];
  // Get Address Book access
  if ([ABAddressBook sharedAddressBook] == nil)
    [InfinitMetricsManager sendMetric:INFINIT_METRIC_NO_ADRESSBOOK_ACCESS];
  else
  {
    NSInteger count = 0;
    for (ABPerson* person in [[ABAddressBook sharedAddressBook] people])
    {
      ABMultiValue* emails = [person valueForProperty:kABEmailProperty];
      if (emails.count > 0)
        count++;
    }
    [InfinitMetricsManager sendMetric:INFINIT_METRIC_HAVE_ADDRESSBOOK_ACCESS
                       withDictionary:@{@"people_with_email": [NSNumber numberWithInteger:count]}];
  }
}

- (void)cacheInitialResults
{
  _has_searched = NO;
  NSMutableArray* temp_swaggers = [NSMutableArray array];
  for (InfinitUser* user in [InfinitUserManager sharedInstance].favorites)
  {
    if (!user.deleted)
    {
      [temp_swaggers addObject:[InfinitSearchPersonResult personWithInfinitUser:user
                                                                    andDelegate:self]];
    }
  }
  for (InfinitUser* user in [InfinitUserManager sharedInstance].time_ordered_swaggers)
  {
    if (!user.deleted)
    {
      [temp_swaggers addObject:[InfinitSearchPersonResult personWithInfinitUser:user
                                                                    andDelegate:self]];
    }
  }
  _all_swaggers = temp_swaggers;
  _swagger_results = [self.all_swaggers mutableCopy];
  NSMutableArray* temp_devices = [NSMutableArray array];
  [[InfinitDeviceManager sharedInstance] updateDevices];
  for (InfinitDevice* device in [InfinitDeviceManager sharedInstance].other_devices)
  {
    [temp_devices addObject:[InfinitSearchPersonResult personWithDevice:device andDelegate:self]];
  }
  if (temp_devices.count == 0)
  {
    InfinitSearchPersonResult* me =
    [InfinitSearchPersonResult personWithInfinitUser:[InfinitUserManager sharedInstance].me
                                         andDelegate:self];
    if (![self.all_swaggers containsObject:me])
      [temp_devices addObject:me];
  }
  _all_devices = temp_devices;
  _device_results = [self.all_devices mutableCopy];
  _all_address_book = @[];
  _address_book_results = [self.address_book_results mutableCopy];

  [self performSelectorOnMainThread:@selector(sortAndAggregateResults)
                         withObject:nil
                      waitUntilDone:NO];

  if (![[[IAUserPrefs sharedInstance] prefsForKey:@"accessed_addressbook"] isEqualToString:@"1"])
  {
    [self firstAddressbookAccess];
  }
  if (![self accessToAddressBook])
  {
    _all_address_book = @[];
    _address_book_results = [self.address_book_results mutableCopy];
  }
  else
  {
    NSMutableArray* temp_ab = [NSMutableArray array];
    for (ABPerson* person in [ABAddressBook sharedAddressBook].people)
    {
      InfinitSearchPersonResult* result = [InfinitSearchPersonResult personWithABPerson:person 
                                                                            andDelegate:self];
      if (result.emails.count > 0)
      {
        [temp_ab addObject:result];
      }
    }
    NSSortDescriptor* descriptor =
      [NSSortDescriptor sortDescriptorWithKey:@"fullname"
                                    ascending:YES
                                     selector:@selector(caseInsensitiveCompare:)];
    [temp_ab sortUsingDescriptors:@[descriptor]];
    _all_address_book = temp_ab;
    if (_has_searched)
      return;
    _address_book_results = [self.all_address_book mutableCopy];
    [self performSelectorOnMainThread:@selector(sortAndAggregateResults)
                           withObject:nil
                        waitUntilDone:NO];
  }
}

- (void)searchAddressBookWithString:(NSString*)search_string
{
  if (!search_string.length || ![self accessToAddressBook])
    return;

  ELLE_DEBUG("%s: search addressbook for: %s", self.description.UTF8String,
             search_string.UTF8String);

  NSMutableArray* strings;
  NSMutableArray* search_elements = [NSMutableArray array];
  
  if ([search_string rangeOfString:@" "].location != NSNotFound)
  {
    // Break up search string on spaces for first/last name.
    strings = [NSMutableArray arrayWithArray:[search_string componentsSeparatedByString:@" "]];
  }
  else
  {
    strings = [NSMutableArray arrayWithObject:search_string];
  }
  for (NSString* string in strings)
  {
    NSString* temp = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (!temp.length)
    {
      continue;
    }
    else
    {
      [search_elements addObject:[ABPerson searchElementForProperty:kABFirstNameProperty
                                                              label:nil
                                                                key:nil
                                                              value:temp
                                                         comparison:kABPrefixMatchCaseInsensitive]];
      [search_elements addObject:[ABPerson searchElementForProperty:kABLastNameProperty
                                                              label:nil
                                                                key:nil
                                                              value:temp
                                                         comparison:kABPrefixMatchCaseInsensitive]];
    }
  }
  
  NSMutableArray* all_results = [NSMutableArray array];
  for (ABSearchElement* search_element in search_elements)
  {
    [all_results addObjectsFromArray:[[ABAddressBook sharedAddressBook] recordsMatchingSearchElement:search_element]];
  }
  
  NSMutableArray* filtered_results = [NSMutableArray array];
  for (ABPerson* search_result in all_results)
  {
    InfinitSearchPersonResult* person = [InfinitSearchPersonResult personWithABPerson:search_result
                                                                          andDelegate:self];
    // We only care about people who have email addresses as we're going to use these to search
    // for them or to invite them.
    if (person.emails.count > 0)
    {
      if ([filtered_results indexOfObject:person] == NSNotFound)
      {
        [filtered_results addObject:person];
      }
      else
      {
        InfinitSearchPersonResult* existing_person =
          [filtered_results objectAtIndex:[filtered_results indexOfObject:person]];
        existing_person.rank += address_book_subsequent_match_rank;
      }
    }
  }
  
  NSMutableArray* res = [NSMutableArray array];
  NSMutableArray* emails = [NSMutableArray array];
  
  double required_rank = address_book_match_rank - 1.0f +
    ((search_elements.count / 2.0f) * address_book_subsequent_match_rank);

  for (InfinitSearchPersonResult* person in filtered_results)
  {
    if (person.rank >= (NSInteger)floor(required_rank))
    {
      [res addObject:person];
      [emails addObjectsFromArray:person.emails];
    }
  }
  NSSortDescriptor* descriptor =
    [NSSortDescriptor sortDescriptorWithKey:@"fullname"
                                  ascending:YES
                                   selector:@selector(caseInsensitiveCompare:)];
  [res sortUsingDescriptors:@[descriptor]];
  _address_book_results = res;
}

#pragma mark - Device Search

- (void)searchDevices:(NSString*)search_string
{
  NSArray* devices = [InfinitDeviceManager sharedInstance].other_devices;
  if (self.device_results == nil)
    _device_results = [NSMutableArray array];
  else
    [self.device_results removeAllObjects];
  for (InfinitDevice* device in devices)
  {
    if ([self string:device.name containsString:search_string])
    {
      InfinitSearchPersonResult* result = [InfinitSearchPersonResult personWithDevice:device
                                                                          andDelegate:self];
      [self.device_results addObject:result];
    }
  }
}

#pragma mark - Swagger Search

- (BOOL)user:(InfinitUser*)user
containsSearchString:(NSString*)search_string
{
  if (!user.deleted &&
      ([self string:user.fullname containsString:search_string] ||
       [self string:user.handle containsString:search_string]))
    return YES;
  return NO;
}

- (void)searchSwaggers:(NSString*)search_string
{
  if (self.swagger_results == nil)
    _swagger_results = [NSMutableArray array];
  else
    [self.swagger_results removeAllObjects];
  NSArray* local_results = [[InfinitUserManager sharedInstance] searchLocalUsers:search_string];
  for (InfinitUser* user in local_results)
  {
    InfinitSearchPersonResult* person = [InfinitSearchPersonResult personWithInfinitUser:user
                                                                             andDelegate:self];
    [self.swagger_results addObject:person];
  }
}

#pragma mark - Email Search

- (void)updatePersonWithEmail:(NSString*)email
               andInfinitUser:(InfinitUser*)user
{
  for (InfinitSearchPersonResult* person in _address_book_results)
  {
    if ([person.emails containsObject:email])
    {
      [person email:email isInfinitUser:user];
    }
  }
}

- (void)searchForEmailString:(NSString*)email
{
  _searching_email = YES;
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  NSMutableDictionary* mail_check = [NSMutableDictionary dictionary];
  [[InfinitStateManager sharedInstance] userByEmail:email
                                    performSelector:@selector(singleEmailSearchCallback:)
                                           onObject:self
                                           withData:mail_check];
}

- (void)singleEmailSearchCallback:(InfinitStateResult*)result
{
  if (!_searching_email)
    return;
  if (!result.success)
  {
    ELLE_WARN("%s: problem checking for user id", self.description.UTF8String);
    return;
  }
  NSDictionary* dict = result.data;
  NSNumber* user_id = dict[kInfinitUserId];
  if (user_id.unsignedIntegerValue != 0)
  {
    InfinitUser* user = [[InfinitUserManager sharedInstance] userWithId:user_id];
    InfinitSearchPersonResult* new_person = [InfinitSearchPersonResult personWithInfinitUser:user
                                                                                 andDelegate:self];
    [_result_list addObject:new_person];
  }
  [_delegate searchControllerGotEmailResult:self];
}


#pragma mark - Aggregation

- (BOOL)userInResults:(InfinitSearchPersonResult*)person
{
  for (InfinitSearchPersonResult* other_person in self.result_list)
  {
    if ([person isEqual:other_person])
      return YES;
  }
  return NO;
}

- (void)sortAndAggregateResults
{
  // Aggregate results.
  if (_result_list == nil)
    _result_list = [NSMutableArray array];
  @synchronized(self.result_list)
  {
    [self.result_list removeAllObjects];
    [self.result_list addObjectsFromArray:self.device_results];
    [self.result_list addObjectsFromArray:self.swagger_results];
    [self.result_list addObjectsFromArray:self.address_book_results];
    [_delegate searchControllerGotResults:self];
  }
}

#pragma mark - General Functions

- (void)clearResults
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  if (self.result_list)
    [self.result_list removeAllObjects];
  if (self.address_book_results)
    [self.address_book_results removeAllObjects];
  _email_result = nil;
}

- (void)emptyResults
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  _address_book_results = [self.all_address_book mutableCopy];
  _swagger_results = [self.all_swaggers mutableCopy];
  _device_results = [self.all_devices mutableCopy];
  [self sortAndAggregateResults];
}

- (void)searchWithString:(NSString*)search_string
{
  _has_searched = YES;
  _searching_email = NO;
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  [self searchDevices:search_string];
  [self searchSwaggers:search_string];
  [self searchAddressBookWithString:search_string];

  [self sortAndAggregateResults];
}

#pragma mark - Person Delegate

- (void)personGotNewAvatar:(InfinitSearchPersonResult*)sender
{
  [_delegate searchController:self gotUpdateForPerson:sender];
}

#pragma mark - Helpers

- (BOOL)string:(NSString*)string_ containsString:(NSString*)search_string_
{
  NSString* string = string_.lowercaseString;
  NSString* search_string = search_string_.lowercaseString;
  if ([string rangeOfString:search_string].location != NSNotFound)
    return YES;
  return NO;
}

@end
