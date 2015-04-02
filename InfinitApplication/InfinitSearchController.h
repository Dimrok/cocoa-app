//
//  InfinitSearchController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 21/11/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "InfinitSearchPersonResult.h"

@protocol InfinitSearchControllerProtocol;

@interface InfinitSearchController : NSObject <InfinitSearchPersonResultProtocol>

@property (atomic, readonly) NSMutableArray* result_list;

- (id)initWithDelegate:(id<InfinitSearchControllerProtocol>)delegate;

- (void)clearResults;
- (void)emptyResults;

- (void)searchWithString:(NSString*)search_string;
- (void)searchForEmailString:(NSString*)email;

- (void)cancelCallbacks;

@end

@protocol InfinitSearchControllerProtocol <NSObject>

- (void)searchControllerGotEmailResult:(InfinitSearchController*)sender;

- (void)searchControllerGotResults:(InfinitSearchController*)sender;

- (void)searchController:(InfinitSearchController*)sender
      gotUpdateForPerson:(InfinitSearchPersonResult*)person;

@end
