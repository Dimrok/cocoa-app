//
//  IAMainController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 7/26/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//
//  This controller has several responsibilities. It's responsible for login/logout operations,
//  selecting which views should be shown and communicating with the IATransactionManager and
//  IAUserManager. It also acts as a proxy between the views and the managers so that all
//  information passes through the same place.

#import <Foundation/Foundation.h>

@protocol IAMainControllerProtocol;

@interface IAMainController : NSObject

- (id)initWithDelegate:(id<IAMainControllerProtocol>)delegate;

- (void)handleInfinitLink:(NSURL*)link;

- (void)openPreferences;

- (void)handleContextualSendFiles:(NSArray*)files;
- (void)handleContextualCreateLink:(NSArray*)files;

- (void)handleQuit;

- (BOOL)canUpdate;

@end

@protocol IAMainControllerProtocol <NSObject>

- (void)terminateApplication:(IAMainController*)sender;

- (void)mainControllerWantsCheckForUpdate:(IAMainController*)sender;

- (void)mainControllerWantsBackgroundUpdateChecks:(IAMainController*)sender;

- (BOOL)applicationUpdating;

@end