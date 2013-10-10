//
//  IANotLoggedInView.h
//  InfinitApplication
//
//  Created by Christopher Crone on 7/26/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//
//  This view controller manages the view shown in the window when the user is not logged in.

#import <Cocoa/Cocoa.h>

#import "IAViewController.h"

#import "IABottomButton.h"

typedef enum __IANotLoggedInViewMode
{
    LOGGED_OUT = 0,
    LOGGING_IN = 1,
} IANotLoggedInViewMode;

@protocol IANotLoggedInViewProtocol;

@interface IANotLoggedInViewController : IAViewController
{
@private
    id<IANotLoggedInViewProtocol> _delegate;
}

@property (nonatomic, strong) IBOutlet NSTextField* not_logged_message;
@property (nonatomic, strong) IBOutlet IABottomButton* login_button;
@property (nonatomic, setter = setMode:) IANotLoggedInViewMode mode;

- (id)initWithDelegate:(id<IANotLoggedInViewProtocol>)delegate
              withMode:(IANotLoggedInViewMode)mode;

@end

@protocol IANotLoggedInViewProtocol <NSObject>

- (void)notLoggedInViewControllerWantsOpenLoginWindow:(IANotLoggedInViewController*)sender;

@end
