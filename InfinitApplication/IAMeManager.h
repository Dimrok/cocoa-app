//
//  IAMeManager.h
//  InfinitApplication
//
//  Created by Christopher Crone on 8/30/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//
// This manager is responsible for managing information related to the user. This currently includes
// connection status and will later include things like avatar, handle, etc.

#import <Foundation/Foundation.h>

@protocol IAMeManagerProtocol;

@interface IAMeManager : NSObject

@property (nonatomic) gap_UserStatus connection_status;

- (id)initWithDelegate:(id<IAMeManagerProtocol>)delegate;

@end

@protocol IAMeManagerProtocol <NSObject>

- (void)meManager:(IAMeManager*)sender
hadConnectionStateChange:(gap_UserStatus)status;

@end
