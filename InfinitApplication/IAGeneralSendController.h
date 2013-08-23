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

#import "IAAdvancedSendViewController.h"
#import "IAFavouritesSendViewController.h"
#import "IASimpleSendViewController.h"

@protocol IAGeneralSendControllerProtocol;

@interface IAGeneralSendController : NSObject <IAAdvancedSendViewProtocol,
                                               IAFavouritesSendViewProtocol,
                                               IASimpleSendViewProtocol>

- (id)initWithDelegate:(id<IAGeneralSendControllerProtocol>)delegate;

- (void)openWithNoFile;
- (void)openWithFiles:(NSArray*)files
              forUser:(IAUser*)user;
- (void)filesOverStatusBarIcon;

@end

@protocol IAGeneralSendControllerProtocol <NSObject>

- (void)sendController:(IAGeneralSendController*)sender
 wantsActiveController:(IAViewController*)controller;

- (void)sendControllerWantsClose:(IAGeneralSendController*)sender;

- (NSPoint)sendControllerWantsMidpoint:(IAGeneralSendController*)sender;

- (void)sendController:(IAGeneralSendController*)sender
        wantsSendFiles:(NSArray*)files
               toUsers:(NSArray*)users
           withMessage:(NSString*)message;

- (NSArray*)sendControllerWantsFavourites:(IAGeneralSendController*)sender;

- (void)sendController:(IAGeneralSendController*)sender
     wantsAddFavourite:(IAUser*)user;

- (void)sendController:(IAGeneralSendController*)sender
  wantsRemoveFavourite:(IAUser*)user;

@end
