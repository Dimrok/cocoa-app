//
//  IAFWAutoStartup.h
//  FinderWindow
//
//  Created by Christopher Crone on 3/22/13.
//  Copyright (c) 2013 infinit. All rights reserved.
//
// Functions for checking and editing the login items of a user for the Infinit application

#import <Foundation/Foundation.h>

@interface IAAutoStartup : NSObject

+ (IAAutoStartup*)sharedInstance;

- (void)addAppAsLoginItem;

- (BOOL)appInLoginItemList;

- (void)removeAppFromLoginItem;

@end
