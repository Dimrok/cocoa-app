//
//  IAGeneralSendController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 8/2/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//
//  The send controller is responsible for selecting which send views are shown. It's simply a layer
//  between each send view and the main controller to reduce the amount of logic in the main
//  controller.

#import <Foundation/Foundation.h>

#import "IAFavouritesSendViewController.h"
#import "InfinitSendViewController.h"

@protocol IAGeneralSendControllerProtocol;

@interface IAGeneralSendController : NSObject <IAFavouritesSendViewProtocol,
                                               IAViewProtocol,
                                               InfinitSendViewProtocol>

- (id)initWithDelegate:(id<IAGeneralSendControllerProtocol>)delegate;

- (void)openWithNoFileForLink:(BOOL)for_link;
- (void)openWithFiles:(NSArray*)files
              forUser:(InfinitUser*)user;
- (void)filesOverStatusBarIcon;

@end

@protocol IAGeneralSendControllerProtocol <IAViewProtocol>

- (void)sendController:(IAGeneralSendController*)sender
 wantsActiveController:(IAViewController*)controller;

- (void)sendControllerWantsClose:(IAGeneralSendController*)sender;

- (void)sendControllerWantsBack:(IAGeneralSendController*)sender;

- (NSPoint)sendControllerWantsMidpoint:(IAGeneralSendController*)sender;

- (void)sendControllerGotDropOnFavourite:(IAGeneralSendController*)sender;

- (NSArray*)sendControllerWantsFriendsByLastInteraction:(IAGeneralSendController*)sender;

//- Onboarding -------------------------------------------------------------------------------------

- (void)sendController:(IAGeneralSendController*)sender
wantsSetOnboardingSendTransactionId:(NSNumber*)transaction_id;

@end
