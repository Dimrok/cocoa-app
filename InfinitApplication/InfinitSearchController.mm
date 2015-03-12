//
//  InfinitSearchController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 21/11/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "InfinitSearchController.h"

#import "IAUserPrefs.h"
#import "InfinitMetricsManager.h"

#import <Gap/IAUserManager.h>

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("OSX.SearchController");

@implementation InfinitSearchController
{
@private
  // WORKAROUND: 10.7 doesn't allow weak references to certain classes (like NSViewController)
  __unsafe_unretained id<InfinitSearchControllerProtocol> _delegate;
  
  ABAddressBook* _addressbook;

  NSMutableArray* _address_book_results; // Results from the address book.
  NSMutableArray* _swagger_results; // Results from swaggers.
  NSMutableArray* _infinit_name_results; // Results from handle and fullname matches in the Infinit database.
  NSMutableArray* _infinit_email_results; // Results from batch email searches using the address book.
  InfinitSearchPersonResult* _single_email_result; // Result from a search done with a single email address.

  BOOL _got_infinit_results;
  NSOperation* _current_name_search;
  NSOperation* _current_emails_search;
  NSOperation* _current_single_email_search;
}

//- Initialisation ---------------------------------------------------------------------------------

@synthesize result_list = _result_list;

- (id)initWithDelegate:(id<InfinitSearchControllerProtocol>)delegate
{
  if (self = [super init])
  {
    _delegate = delegate;
    _result_list = [NSMutableArray array];
    _address_book_results = [NSMutableArray array];
    _infinit_name_results = [NSMutableArray array];
    _swagger_results = [NSMutableArray array];
    _single_email_result = nil;
    if (![[[IAUserPrefs sharedInstance] prefsForKey:@"accessed_addressbook"] isEqualToString:@"1"])
    {
      [self performSelector:@selector(firstAddressbookAccess) withObject:nil afterDelay:0.5];
    }
  }
  return self;
}

- (void)dealloc
{
  [self cancelRunningSearches];
  [self cancelCallbacks];
}

- (void)cancelCallbacks
{
  _delegate = nil;
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  for (InfinitSearchPersonResult* person in _result_list)
  {
    [person cancelCallbacks];
  }
}

//- Address Book Handling --------------------------------------------------------------------------

- (BOOL)accessToAddressBook
{
  _addressbook = [ABAddressBook addressBook];
  if (_addressbook == nil)
  {
    ELLE_LOG("%s: no access to addressbook", self.description.UTF8String);
  }
  else
  {
    ELLE_DEBUG("%s: addressbook accessible", self.description.UTF8String);
  }
  return _addressbook == nil ? NO : YES;
}

- (void)firstAddressbookAccess
{
  [[IAUserPrefs sharedInstance] setPref:@"1" forKey:@"accessed_addressbook"];
  // Get Address Book access
  if ([ABAddressBook sharedAddressBook] == nil)
    [InfinitMetricsManager sendMetric:INFINIT_METRIC_NO_ADRESSBOOK_ACCESS];
  else
  {
    _addressbook = [ABAddressBook sharedAddressBook];
    NSInteger count = 0;
    for (ABPerson* person in [_addressbook people])
    {
      ABMultiValue* emails = [person valueForProperty:kABEmailProperty];
      if (emails.count > 0)
        count++;
    }
    [InfinitMetricsManager sendMetric:INFINIT_METRIC_HAVE_ADDRESSBOOK_ACCESS
                       withDictionary:@{@"people_with_email": [NSNumber numberWithInteger:count]}];
  }
}

- (void)searchAddressBookWithString:(NSString*)search_string
{
  if (search_string == nil || search_string.length == 0 || ![self accessToAddressBook])
    return;

  ELLE_DEBUG("%s: search addressbook for: %s", self.description.UTF8String,
             search_string.UTF8String);

  [_address_book_results removeAllObjects];

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
    if (temp.length == 0)
    {
      break;
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
    [all_results addObjectsFromArray:[_addressbook recordsMatchingSearchElement:search_element]];
  }
  
  NSMutableArray* filtered_results = [NSMutableArray array];
  for (ABPerson* search_result in all_results)
  {
    InfinitSearchPersonResult* person =
      [[InfinitSearchPersonResult alloc] initWithABPerson:search_result
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
  
  NSArray* temp = [NSArray arrayWithArray:filtered_results];
  NSMutableArray* emails = [NSMutableArray array];
  
  NSInteger required_rank = address_book_match_rank - 1 +
    ((NSInteger)(search_elements.count / 2) * address_book_subsequent_match_rank);
  for (InfinitSearchPersonResult* person in temp)
  {
    if (person.rank < required_rank)
    {
      [filtered_results removeObject:person];
    }
    else
    {
      [emails addObjectsFromArray:person.emails];
    }
  }
  [self searchEmails:emails];
  
  _address_book_results = filtered_results;
}

//- Swagger Search Handling ------------------------------------------------------------------------

- (BOOL)user:(IAUser*)user containsSearchString:(NSString*)search_string
{
  if (!user.deleted &&
      ([user.fullname rangeOfString:search_string options:NSCaseInsensitiveSearch].location != NSNotFound ||
       [user.handle.lowercaseString rangeOfString:search_string options:NSCaseInsensitiveSearch].location != NSNotFound))
    return YES;
  return NO;
}

- (void)searchSwaggers:(NSString*)search_string
{
  [_swagger_results removeAllObjects];
  BOOL self_result = NO;
  NSNumber* self_id = [IAGapState instance].self_id;
  NSArray* swaggers = [IAUserManager swaggerList];
  for (IAUser* user in swaggers)
  {
    if ([self user:user containsSearchString:search_string])
    {
      if ([user.user_id isEqualTo:self_id])
        self_result = YES;
      InfinitSearchPersonResult* person = [[InfinitSearchPersonResult alloc] initWithInfinitPerson:user
                                                                                       andDelegate:self];
      [_swagger_results addObject:person];
    }
  }
  if (!self_result)
  {
    IAUser* self_user = [IAUserManager userWithId:self_id];
    if ([self user:self_user containsSearchString:search_string])
    {
      InfinitSearchPersonResult* person = [[InfinitSearchPersonResult alloc] initWithInfinitPerson:self_user
                                                                                       andDelegate:self];
      [_swagger_results addObject:person];
    }
  }
}

//- Email Search Handling --------------------------------------------------------------------------

- (void)searchEmails:(NSArray*)emails
{
  if (emails.count == 0)
    return;

  _current_emails_search =
    [[IAGapState instance] searchUsersByEmails:emails
                               performSelector:@selector(searchUsersByEmailsCallback:)
                                      onObject:self];
}

- (void)searchUsersByEmailsCallback:(IAGapOperationResult*)result
{
  if (!result.success)
  {
    ELLE_WARN("%s: searching for emails failed with error: %d", self.description.UTF8String,
              result.status);
    return;
  }

  for (NSString* email in result.data)
  {
    [self updatePersonWithEmail:email andInfinitUser:[result.data objectForKey:email]];
  }
  
  [self sortAndAggregateResults];
}

- (void)updatePersonWithEmail:(NSString*)email
               andInfinitUser:(IAUser*)user
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
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  NSMutableDictionary* mail_check =
    [NSMutableDictionary dictionaryWithDictionary:@{@"email": email}];
  _current_single_email_search =
    [[IAGapState instance] getUserIdfromEmail:email
                              performSelector:@selector(singleEmailSearchCallback:)
                                     onObject:self
                                     withData:mail_check];
}

- (void)singleEmailSearchCallback:(IAGapOperationResult*)result
{
  if (!result.success)
  {
    ELLE_WARN("%s: problem checking for user id", self.description.UTF8String);
    return;
  }
  NSDictionary* dict = result.data;
  NSNumber* user_id = [dict valueForKey:@"user_id"];
  if (user_id.unsignedIntegerValue != 0)
  {
    IAUser* user = [IAUserManager userWithId:user_id];
    InfinitSearchPersonResult* new_person =
      [[InfinitSearchPersonResult alloc] initWithInfinitPerson:user andDelegate:self];
    [_result_list addObject:new_person];
  }
  [_delegate searchControllerGotEmailResult:self];
}

//- Infinit Search Handling ------------------------------------------------------------------------

- (void)infinitSearchResultsCallback:(IAGapOperationResult*)result
{
  if (!result.success)
  {
    ELLE_WARN("%s: searching for users failed with error: %d", self.description.UTF8String,
              result.status);
    return;
  }
  
  NSArray* infinit_results = result.data;
  [_infinit_name_results removeAllObjects];
  for (IAUser* user in infinit_results)
  {
    InfinitSearchPersonResult* new_person =
      [[InfinitSearchPersonResult alloc] initWithInfinitPerson:user andDelegate:self];
    [_infinit_name_results addObject:new_person];
  }
  _got_infinit_results = YES;
  [self sortAndAggregateResults];
}


//- Aggregation ------------------------------------------------------------------------------------

- (BOOL)userInResults:(InfinitSearchPersonResult*)person
{
  for (InfinitSearchPersonResult* other_person in _result_list)
  {
    if ([person isEqual:other_person])
      return YES;
  }
  return NO;
}

- (void)sortAndAggregateResults
{
  // Aggregate results.
  @synchronized(_result_list)
  {
    // If we're searching on Infinit, wait for results to be in before displaying them.
    if (_include_infinit_results && !_got_infinit_results)
      return;
    [_result_list removeAllObjects];
    for (InfinitSearchPersonResult* person in _swagger_results)
    {
      [_result_list addObject:person];
    }
    for (InfinitSearchPersonResult* person in _address_book_results)
    {
      if (![self userInResults:person])
        [_result_list addObject:person];
    }
    if (_include_infinit_results)
    {
      for (InfinitSearchPersonResult* person in _infinit_name_results)
      {
        if (![self userInResults:person])
          [_result_list addObject:person];
      }
    }
    [self sortResultsOnRank];
    [_delegate searchControllerGotResults:self];
  }
}

- (void)sortResultsOnRank
{
  NSArray* temp = [NSArray arrayWithArray:_result_list];
  _result_list = [NSMutableArray arrayWithArray:[temp sortedArrayUsingSelector:@selector(compare:)]];
}

//- General Functions ------------------------------------------------------------------------------

- (void)setInclude_infinit_results:(BOOL)include_infinit_results
{
  _include_infinit_results = include_infinit_results;
  // If we've got results from Infinit, show them now. If not the result callback will send them.
  if (_got_infinit_results)
    [self sortAndAggregateResults];
}

- (void)clearResults
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  [_result_list removeAllObjects];
  [_address_book_results removeAllObjects];
  [_infinit_name_results removeAllObjects];
  _single_email_result = nil;
  _include_infinit_results = NO;
  _got_infinit_results = NO;
}

- (void)cancelRunningSearches
{
  [_current_name_search cancel];
  [_current_emails_search cancel];
  [_current_single_email_search cancel];
}

- (void)searchWithString:(NSString*)search_string
{
  [self cancelRunningSearches];
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  _include_infinit_results = NO;
  _got_infinit_results = NO;
  [_infinit_name_results removeAllObjects];
  [self searchSwaggers:search_string];
  [self searchAddressBookWithString:search_string];

  [self sortAndAggregateResults];
  _current_name_search = [[IAGapState instance] searchUsers:search_string
                                            performSelector:@selector(infinitSearchResultsCallback:)
                                                   onObject:self];
}

//- Result Person Protocol -------------------------------------------------------------------------

- (void)personGotNewAvatar:(InfinitSearchPersonResult*)sender
{
  [_delegate searchController:self gotUpdateForPerson:sender];
}

@end
