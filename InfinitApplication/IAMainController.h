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

#import <Gap/IATransactionManager.h>
#import <Gap/IAUserManager.h>
#import <Gap/InfinitLinkManager.h>

#import "IADesktopNotifier.h"
#import "IAGeneralSendController.h"
#import "IAMeManager.h"
#import "IANoConnectionViewController.h"
#import "IANotLoggedInViewController.h"
#import "IAReportProblemWindowController.h"
#import "IAStatusBarIcon.h"
#import "IAViewController.h"
#import "IAWindowController.h"
#import "InfinitClippyViewController.h"
#import "InfinitConversationViewController.h"
#import "InfinitLoginViewController.h"
#import "InfinitMainViewController.h"
#import "InfinitOnboardingController.h"
#import "InfinitStayAwakeManager.h"
#import "InfinitScreenshotManager.h"

@protocol IAMainControllerProtocol;

@interface IAMainController : NSObject <IADesktopNotifierProtocol,
                                        IAGeneralSendControllerProtocol,
                                        IAMeManagerProtocol,
                                        IANoConnectionViewProtocol,
                                        IANotLoggedInViewProtocol,
                                        IAReportProblemProtocol,
                                        IAStatusBarIconProtocol,
                                        IATransactionManagerProtocol,
                                        IAUserManagerProtocol,
                                        IAViewProtocol,
                                        IAWindowControllerProtocol,
                                        InfinitClippyProtocol,
                                        InfinitConversationViewProtocol,
                                        InfinitLinkManagerProtocol,
                                        InfinitLoginViewControllerProtocol,
                                        InfinitMainViewProtocol,
                                        InfinitOnboardingProtocol,
                                        InfinitScreenshotManagerProtocol,
                                        InfinitStayAwakeProtocol>

- (id)initWithDelegate:(id<IAMainControllerProtocol>)delegate;

- (void)handleInfinitLink:(NSURL*)link;

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