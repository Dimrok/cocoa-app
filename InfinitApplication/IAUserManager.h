//
//  IAUserManager.h
//  InfinitApplication
//
//  Created by Christopher Crone on 7/30/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//
//  The user manager is responsible for all users. This currently involves informing other parts of
//  the application when a user's status has changed.

#import <Foundation/Foundation.h>

@protocol IAUserManagerProtocol;

@interface IAUserManager : NSObject

- (id)initWithDelegate:(id<IAUserManagerProtocol>)delegate;

@end

@protocol IAUserManagerProtocol <NSObject>

- (void)userManager:(IAUserManager*)sender
    hasNewStatusFor:(IAUser*)user;

@end