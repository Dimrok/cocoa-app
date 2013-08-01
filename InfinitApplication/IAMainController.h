//
//  IAMainController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 7/26/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "IALoginViewController.h"
#import "IAMainViewController.h"
#import "IANotificationListViewController.h"
#import "IANotLoggedInViewController.h"
#import "IAStatusBarIcon.h"
#import "IAWindowController.h"

@protocol IAMainControllerProtocol;

@interface IAMainController : NSObject <IALoginViewControllerProtocol,
                                        IAMainViewControllerProtocol,
                                        IANotificationListViewProtocol,
                                        IANotLoggedInViewProtocol,
                                        IAStatusBarIconProtocol,
                                        IAWindowControllerProtocol>

- (id)initWithDelegate:(id<IAMainControllerProtocol>)delegate;

- (void)handleQuit;

@end

@protocol IAMainControllerProtocol <NSObject>

- (void)quitApplication:(IAMainController*)sender;

@end