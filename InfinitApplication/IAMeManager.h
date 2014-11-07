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

#import <surface/gap/enums.hh>

@protocol IAMeManagerProtocol;

@interface IAMeManager : NSObject

@property (nonatomic, readwrite) BOOL connection_status;
@property (nonatomic, readonly) BOOL still_trying;
@property (nonatomic, readonly) NSString* last_error;

- (id)initWithDelegate:(id<IAMeManagerProtocol>)delegate;

@end

@protocol IAMeManagerProtocol <NSObject>

- (void)meManager:(IAMeManager*)sender hadConnectionStateChange:(BOOL)status;
- (void)meManagerKickedOut:(IAMeManager*)sender;

@end
