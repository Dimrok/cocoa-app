//
//  InfinitSearchController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 21/11/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "InfinitSearchController.h"

@implementation InfinitSearchController
{
@private
    id<InfinitSearchControllerProtocol> _delegate;
    
    ABAddressBook* _addressbook;
    
    NSString* _last_search_string;
}

//- Initialisation ---------------------------------------------------------------------------------

@synthesize result_list = _result_list;

- (id)initWithDelegate:(id<InfinitSearchControllerProtocol>)delegate
{
    if (self == [super init])
    {
        _delegate = delegate;
        _addressbook = [ABAddressBook addressBook];
        _result_list = [NSMutableArray array];
        _last_search_string = @"";
    }
    return self;
}

//- Address Book Handling --------------------------------------------------------------------------

- (BOOL)accessToAddressBook
{
    return _addressbook == nil ? NO : YES;
}

- (void)searchAddressBookWithString:(NSString*)search_string
{
    if (search_string == nil || search_string.length == 0)
        return;
    
    NSMutableArray* strings;
    NSMutableArray* search_elements = [NSMutableArray array];
    
    if ([search_string rangeOfString:@" "].location != NSNotFound)
    {
        // Break up search string
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
        [all_results addObjectsFromArray:[_addressbook recordsMatchingSearchElement:search_element]];

    NSMutableArray* address_book_results = [NSMutableArray array];
    for (ABPerson* search_result in all_results)
    {
        // XXX remove me from search results
        if (search_result != _addressbook.me)
        {
            InfinitSearchPersonResult* person = [[InfinitSearchPersonResult alloc] initWithABPerson:search_result
                                                                                        andDelegate:self];
            if ([address_book_results indexOfObject:person] == NSNotFound)
            {
                [address_book_results addObject:person];
            }
            else
            {
                InfinitSearchPersonResult* existing_person =
                    [address_book_results objectAtIndex:[address_book_results indexOfObject:person]];
                existing_person.rank += 1;
            }
        }
    }
    
    NSArray* temp = [NSArray arrayWithArray:address_book_results];
    
    for (InfinitSearchPersonResult* person in temp)
    {
        NSInteger required_rank = (NSInteger)(search_elements.count / 2) - 5;
        if (person.rank < required_rank)
            [address_book_results removeObject:person];
        else
            [person checkAddressBookUserOnInfinit];
    }
    
    [_result_list addObjectsFromArray:address_book_results];
    
    [self sortResultsOnRank];
    [_delegate searchControllerGotResults:self];
}

//- Email Search Handling --------------------------------------------------------------------------

- (void)searchForEmailString:(NSString*)email
{
    InfinitSearchPersonResult* new_person = [[InfinitSearchPersonResult alloc] initWithEmail:email
                                                                                 andDelegate:self];
    [_result_list addObject:new_person];
    [_delegate searchControllerGotEmailResult:self];
}

//- Infinit Search Handling ------------------------------------------------------------------------

- (void)infinitSearchResultsCallback:(IAGapOperationResult*)result
{
    if (!result.success)
    {
        IALog(@"%@ WARNING: Searching for users failed with error: %d", self, result.status);
        return;
    }
    
    NSInteger result_length = _result_list.count;
    
    NSArray* infinit_results = [NSMutableArray arrayWithArray:
                                       [result.data sortedArrayUsingSelector:@selector(compare:)]];
    infinit_results = [[infinit_results reverseObjectEnumerator] allObjects];
    for (IAUser* user in infinit_results)
    {
        // XXX don't include self in search results
        if (![user isEqual:[[IAGapState instance] self_user]])
            [self addInfinitUserToList:user];
    }
    if (result_length != _result_list.count)
    {
        [self sortResultsOnRank];
        [_delegate searchControllerGotResults:self];
    }
}


//- Aggregation ------------------------------------------------------------------------------------

- (void)addInfinitUserToList:(IAUser*)user
{
    BOOL found = NO;
    for (InfinitSearchPersonResult* person in _result_list)
    {
        if (person.infinit_user == user)
        {
            found = YES;
            return;
        }
    }
    InfinitSearchPersonResult* new_person = [[InfinitSearchPersonResult alloc]
                                             initWithInfinitPerson:user andDelegate:self];
    NSInteger index = 0;
    for (InfinitSearchPersonResult* person in _result_list)
    {
        if (person.infinit_user != nil)
            index++;
        else
            break;
    }
    if (index > _result_list.count)
        index = 0;

    [_result_list insertObject:new_person atIndex:index];
}

- (void)searchCurrentResultsForString:(NSString*)search_string
{
    NSArray* temp = [NSArray arrayWithArray:_result_list];
    for (InfinitSearchPersonResult* person in temp)
    {
        if ([person.fullname rangeOfString:search_string options:NSCaseInsensitiveSearch].location == NSNotFound)
            [_result_list removeObject:person];
    }
    [_delegate searchControllerGotResults:self];
}

//- General Functions ------------------------------------------------------------------------------

- (void)clearResults
{
    [_result_list removeAllObjects];
}

- (void)sortResultsOnRank
{
    NSArray* temp = [NSArray arrayWithArray:_result_list];
    _result_list = [NSMutableArray arrayWithArray:[temp sortedArrayUsingSelector:@selector(compare:)]];
}

- (void)searchString:(NSString*)search_string
{
    if ([IAFunctions stringIsValidEmail:search_string])
    {
        [_result_list removeAllObjects];
        [self searchForEmailString:search_string];
    }
    else
    {
        if (search_string.length > _last_search_string.length &&
            [search_string rangeOfString:@" "].location == NSNotFound &&
            [search_string rangeOfString:_last_search_string].location != NSNotFound)
        {
            [self searchCurrentResultsForString:search_string];
        }
        else
        {
            [_result_list removeAllObjects];
            if ([self accessToAddressBook])
            {
                [self searchAddressBookWithString:search_string];
            }
        }
        
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

- (void)personNotOnInfinit:(InfinitSearchPersonResult*)sender
{
    if (_result_list.count == 1)
        [_delegate searchControllerGotResults:self];
}

- (void)personUpdated:(InfinitSearchPersonResult*)sender
{
    if (_result_list.count == 1)
    {
        [_result_list replaceObjectAtIndex:0 withObject:sender];
    }
    else
    {
        [_result_list removeObject:sender];
        [_result_list insertObject:sender atIndex:0];
    }
    [self sortResultsOnRank];
    [_delegate searchControllerGotResults:self];
}



@end
