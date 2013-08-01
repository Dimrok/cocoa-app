//
//  IANotLoggedInView.h
//  InfinitApplication
//
//  Created by Christopher Crone on 7/26/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IAViewController.h"

@protocol IANotLoggedInViewProtocol;

@interface IANotLoggedInViewController : IAViewController
{
@private
    id<IANotLoggedInViewProtocol> _delegate;
}

@property (nonatomic, strong) IBOutlet NSTextField* not_logged_message;
@property (nonatomic, strong) IBOutlet NSButton* login_button;

- (id)initWithDelegate:(id<IANotLoggedInViewProtocol>)delegate;

@end

@protocol IANotLoggedInViewProtocol <NSObject>

- (void)notLoggedInViewControllerWantsOpenLoginWindow:(IANotLoggedInViewController*)sender;

@end
