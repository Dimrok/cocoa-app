//
//  IAMainController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 7/26/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "IAStatusBarIcon.h"
#import "IAMainViewController.h"
#import "IANotLoggedInView.h"

@protocol IAMainControllerProtocol;

@interface IAMainController : NSObject <IAMainViewControllerProtocol,
                                        IANotLoggedInViewProtocol,
                                        IAStatusBarIconProtocol>
{
@private
    id<IAMainControllerProtocol> _delegate;
    NSStatusItem* _status_item;
    IAStatusBarIcon* _status_bar_icon;
    IAMainViewController* _view_controller;
}

- (id)initWithDelegate:(id<IAMainControllerProtocol>)delegate;

- (void)handleQuit;

@end

@protocol IAMainControllerProtocol <NSObject>

- (void)quitApplication:(IAMainController*)sender;

@end