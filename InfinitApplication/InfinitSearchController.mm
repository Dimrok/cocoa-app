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
  
  NSString* _last_search_string;
  NSMutableArray* _address_book_results; // Results from the address book.
  NSMutableArray* _infinit_name_results; // Results from handle and fullname matches in the Infinit database.
  NSMutableArray* _infinit_email_results; // Results from batch email searches using the address book.
  InfinitSearchPersonResult* _single_email_result; // Result from a search done with a single email address.
  // When we're doing a clean search, we're not sure if we're going to get the email results back
  // first or the fullname/handle results. In order to avoid the results drastically changing, we're
  // going to wait for both. In the dirty case (i.e.: text added, so address book results only get
  // less), we only need to wait for the fullname/handle results from Meta.
  BOOL _first_results_in;
}

//- Initialisation ---------------------------------------------------------------------------------

@synthesize result_list = _result_list;

- (id)initWithDelegate:(id<InfinitSearchControllerProtocol>)delegate
{
  if (self = [super init])
  {
    _delegate = delegate;
    _result_list = [NSMutableArray array];
    _last_search_string = @"";
    _address_book_results = [NSMutableArray array];
    _infinit_name_results = [NSMutableArray array];
    _single_email_result = nil;
    _first_results_in = NO;
    if (![[[IAUserPrefs sharedInstance] prefsForKey:@"accessed_addressbook"] isEqualToString:@"1"])
    {
      [self performSelector:@selector(firstAddressbookAccess) withObject:nil afterDelay:0.5];
    }
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
    [InfinitMetricsManager sendMetric:INFINIT_METRIC_HAVE_ADDRESSBOOK_ACCESS];
}

- (void)searchAddressBookWithString:(NSString*)search_string
{
  if (search_string == nil || search_string.length == 0)
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
    // Remove me from search results.
    if (search_result != _addressbook.me)
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

//- Email Search Handling --------------------------------------------------------------------------

- (void)searchEmails:(NSArray*)emails
{
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
  NSMutableDictionary* mail_check =
    [NSMutableDictionary dictionaryWithDictionary:@{@"email": email}];
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
  for (IAUser* user in infinit_results)
  {
    InfinitSearchPersonResult* new_person =
      [[InfinitSearchPersonResult alloc] initWithInfinitPerson:user andDelegate:self];
    [_infinit_name_results addObject:new_person];
  }
  
  [self sortAndAggregateResults];
}


//- Aggregation ------------------------------------------------------------------------------------

- (BOOL)userInResults:(InfinitSearchPersonResult*)person
{
  for (InfinitSearchPersonResult* other_person in _result_list)
  {
    if (person.infinit_user == other_person.infinit_user)
      return YES;
  }
  return NO;
}

- (void)sortAndAggregateResults
{
  // Aggregate results.
  @synchronized(_result_list)
  {
    [_result_list removeAllObjects];
    for (InfinitSearchPersonResult* person in _address_book_results)
    {
      [_result_list addObject:person];
    }
    for (InfinitSearchPersonResult* person in _infinit_name_results)
    {
      if ([self userInResults:person] == NO)
        [_result_list addObject:person];
    }
    [self sortResultsOnRank];
    // Wait for us to have both sets of server results before alerting the delegate.
    if (_first_results_in)
      [_delegate searchControllerGotResults:self];
    else
      _first_results_in = YES;
  }
}

- (void)sortResultsOnRank
{
  NSArray* temp = [NSArray arrayWithArray:_result_list];
  _result_list = [NSMutableArray arrayWithArray:[temp sortedArrayUsingSelector:@selector(compare:)]];
}

- (void)searchCurrentResultsForString:(NSString*)search_string
{
  NSArray* temp = [NSArray arrayWithArray:_address_book_results];
  for (InfinitSearchPersonResult* person in temp)
  {
    if ([person.fullname rangeOfString:search_string options:NSCaseInsensitiveSearch].location == NSNotFound)
      [_address_book_results removeObject:person];
  }
}

//- General Functions ------------------------------------------------------------------------------

- (void)clearResults
{
  _first_results_in = NO;
  _last_search_string = @"";
  [_result_list removeAllObjects];
  [_address_book_results removeAllObjects];
  [_infinit_name_results removeAllObjects];
  _single_email_result = nil;
}

- (void)searchString:(NSString*)search_string
{
  // If the string is of the form of an email, we will only search for a single email result.
  if ([IAFunctions stringIsValidEmail:search_string])
  {
    _first_results_in = YES;
    _single_email_result = nil;
    [_result_list removeAllObjects];
    [self searchForEmailString:search_string];
  }
  else
  {
    // If the last search string is a substring of the current, then the address book results are
    // going to be less than before. This means we don't need to batch search the emails, only clear
    // out no longer relevant results.
    if ([search_string rangeOfString:_last_search_string].location != NSNotFound)
    {
      _first_results_in = YES; // We've got the address book and email results already.
      [self searchCurrentResultsForString:search_string];
    }
    // Otherwise we're doing a full search.
    else
    {
      [self clearResults];
      if ([self accessToAddressBook])
      {
        [self searchAddressBookWithString:search_string];
      }
      // In the case we don't have access to the address book, we're only going to get one set of
      // results; those from the handle/fullname search.
      else
      {
        _first_results_in = YES;
      }
    }
    
    // In both the cases above, however, we need to do an Infinit fullname/handle search. Meta only
    // returns some of the search results and so we may need to fetch more.
    [_infinit_name_results removeAllObjects];
    [[IAGapState instance] searchUsers:search_string
                       performSelector:@selector(infinitSearchResultsCallback:)
                              onObject:self];
  }
  _last_search_string = search_string;
}

//- Result Person Protocol -------------------------------------------------------------------------

- (void)personGotNewAvatar:(InfinitSearchPersonResult*)sender
{
  [_delegate searchController:self gotUpdateForPerson:sender];
}

@end
