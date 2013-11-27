//
//  InfinitSearchPersonResult.h
//  InfinitApplication
//
//  Created by Christopher Crone on 21/11/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum __InfinitSearchUserSource
{
    INFINIT_ADDRESSBOOK_USER = 0,
    INFINIT_SEARCH_USER = 1,
} InfinitSearchUserSource;

@protocol InfinitSearchPersonResultProtocol;

@interface InfinitSearchPersonResult : NSObject

@property (nonatomic, readonly) NSImage* avatar;
@property (nonatomic, readonly) NSString* fullname;
@property (nonatomic, readonly) NSMutableArray* emails;
@property (nonatomic, readonly) IAUser* infinit_user;
@property (nonatomic, readwrite) NSInteger rank;

- (id)initWithABPerson:(ABPerson*)person
           andDelegate:(id<InfinitSearchPersonResultProtocol>)delegate;
- (id)initWithEmail:(NSString*)email
        andDelegate:(id<InfinitSearchPersonResultProtocol>)delegate;
- (id)initWithInfinitPerson:(IAUser*)user
                andDelegate:(id<InfinitSearchPersonResultProtocol>)delegate;

- (void)checkAddressBookUserOnInfinit;

@end


@protocol InfinitSearchPersonResultProtocol <NSObject>

- (void)emailPersonUpdated:(InfinitSearchPersonResult*)sender;

- (void)personGotNewAvatar:(InfinitSearchPersonResult*)sender;

- (void)personNotOnInfinit:(InfinitSearchPersonResult*)sender;

- (void)personUpdated:(InfinitSearchPersonResult*)sender;

@end