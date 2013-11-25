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
    
    NSMutableSet* result_set = [NSMutableSet set];
    for (ABSearchElement* search_element in search_elements)
        [result_set addObjectsFromArray:[_addressbook recordsMatchingSearchElement:search_element]];

    NSMutableArray* address_book_results = [NSMutableArray array];
    for (ABPerson* search_result in result_set)
    {
        // XXX remove me from search results
        if (search_result != _addressbook.me)
        {
            InfinitSearchPersonResult* person = [[InfinitSearchPersonResult alloc] initWithABPerson:search_result
                                                                                        andDelegate:self];
            [address_book_results addObject:person];
        }
    }
    [_result_list addObjectsFromArray:[address_book_results
                                       sortedArrayUsingSelector:@selector(compare:)]];
    
    [_delegate searchControllerGotResults:self];
}

//- Infinit Search Handling ------------------------------------------------------------------------

- (void)infinitSearchResultsCallback:(IAGapOperationResult*)result
{
    if (!result.success)
    {
        IALog(@"%@ WARNING: Searching for users failed with error: %d", self, result.status);
        return;
    }
    
    NSArray* infinit_results = [NSMutableArray arrayWithArray:
                                       [result.data sortedArrayUsingSelector:@selector(compare:)]];
    infinit_results = [[infinit_results reverseObjectEnumerator] allObjects];
    for (IAUser* user in infinit_results)
    {
        // XXX don't include self in search results
        if (![user isEqual:[[IAGapState instance] self_user]])
            [self addInfinitUserToList:user];
    }
    [_delegate searchControllerGotResults:self];
}


//- Aggregation ------------------------------------------------------------------------------------

- (void)addInfinitUserToList:(IAUser*)user
{
    for (InfinitSearchPersonResult* person in _result_list)
    {
        if (person.infinit_user == user)
        {
            [_result_list removeObject:person];
            break;
        }
    }
    InfinitSearchPersonResult* new_person = [[InfinitSearchPersonResult alloc]
                                             initWithInfinitPerson:user andDelegate:self];
    [_result_list insertObject:new_person atIndex:0];
}

- (void)searchCurrentResultsForString:(NSString*)search_string
{
    NSArray* temp = [NSArray arrayWithArray:_result_list];
    for (InfinitSearchPersonResult* person in temp)
    {
        if ([person.fullname rangeOfString:search_string options:NSCaseInsensitiveSearch].location == NSNotFound)
            [_result_list removeObject:person];
    }
}

//- General Functions ------------------------------------------------------------------------------

- (void)clearResults
{
    [_result_list removeAllObjects];
}

- (void)searchString:(NSString*)search_string
{
    // If we add letters, don't redo the address book search
    if (search_string.length > 0 || _last_search_string.length > 0 ||
        [search_string rangeOfString:_last_search_string options:NSCaseInsensitiveSearch].location == NSNotFound)
    {
        [_result_list removeAllObjects];
        if ([self accessToAddressBook])
        {
            [self searchAddressBookWithString:search_string];
        }
        
    }
    else
    {
        [self searchCurrentResultsForString:search_string];
    }
    
    [[IAGapState instance] searchUsers:search_string
                       performSelector:@selector(infinitSearchResultsCallback:)
                              onObject:self];
    _last_search_string = search_string;
}

//- Result Person Protocol -------------------------------------------------------------------------

- (void)personGotNewAvatar:(InfinitSearchPersonResult*)sender
{
    [_delegate searchController:self gotNewAvatarForPerson:sender];
}

@end
