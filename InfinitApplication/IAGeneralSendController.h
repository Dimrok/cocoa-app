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

#import "IASimpleSendViewController.h"

@protocol IAGeneralSendControllerProtocol;

@interface IAGeneralSendController : NSObject <IASimpleSendViewProtocol>

- (id)initWithDelegate:(id<IAGeneralSendControllerProtocol>)delegate;

- (void)openWithNoFile;
- (void)openWithFiles:(NSArray*)files;

@end

@protocol IAGeneralSendControllerProtocol <NSObject>

- (void)sendController:(IAGeneralSendController*)sender
 wantsActiveController:(IAViewController*)controller;

@end
