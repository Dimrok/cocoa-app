//
//  InfinitSearchPersonResult.h
//  InfinitApplication
//
//  Created by Christopher Crone on 21/11/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Gap/InfinitUser.h>

typedef enum __InfinitSearchUserSource
{
    INFINIT_ADDRESSBOOK_USER = 0,
    INFINIT_SEARCH_USER = 1,
} InfinitSearchUserSource;

static NSInteger address_book_match_rank = 5;
static NSInteger address_book_subsequent_match_rank = 1;
static NSInteger infinit_match_rank = 3;
static NSInteger infinit_swagger_rank = 6;
static NSInteger infinit_favourite_rank = 10;

@protocol InfinitSearchPersonResultProtocol;

@interface InfinitSearchPersonResult : NSObject

@property (nonatomic, readonly) NSImage* avatar;
@property (nonatomic, readonly) NSString* fullname;
@property (nonatomic, readonly) NSMutableArray* emails;
@property (nonatomic, readonly) InfinitUser* infinit_user;
@property (nonatomic, readwrite) NSInteger rank;

- (id)initWithABPerson:(ABPerson*)person
           andDelegate:(id<InfinitSearchPersonResultProtocol>)delegate;
- (id)initWithInfinitPerson:(InfinitUser*)user
                andDelegate:(id<InfinitSearchPersonResultProtocol>)delegate;

- (void)email:(NSString*)email
isInfinitUser:(InfinitUser*)user;

- (void)cancelCallbacks;

@end


@protocol InfinitSearchPersonResultProtocol <NSObject>

- (void)personGotNewAvatar:(InfinitSearchPersonResult*)sender;

@end