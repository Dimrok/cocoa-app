//
//  OldInfinitSearchController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 21/11/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "InfinitSearchPersonResult.h"

@protocol OldInfinitSearchControllerProtocol;

@interface OldInfinitSearchController : NSObject <InfinitSearchPersonResultProtocol>

@property (atomic, readonly) NSMutableArray* result_list;

- (id)initWithDelegate:(id<OldInfinitSearchControllerProtocol>)delegate;

- (void)clearResults;

- (void)searchString:(NSString*)search_string;

- (void)cancelCallbacks;

@end

@protocol OldInfinitSearchControllerProtocol <NSObject>

- (void)searchControllerGotEmailResult:(OldInfinitSearchController*)sender;

- (void)searchControllerGotResults:(OldInfinitSearchController*)sender;

- (void)searchController:(OldInfinitSearchController*)sender
      gotUpdateForPerson:(InfinitSearchPersonResult*)person;

@end
