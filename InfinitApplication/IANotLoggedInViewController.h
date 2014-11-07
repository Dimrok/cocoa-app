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

#import "IAHoverButton.h"

typedef enum __IANotLoggedInViewMode
{
  INFINIT_LOGGING_IN = 0,
  INFINIT_WAITING_FOR_CONNECTION = 1,
} IANotLoggedInViewMode;

@interface InfinitNotLoggedInButtonCell : NSButtonCell
@end;

@protocol IANotLoggedInViewProtocol;

@interface IANotLoggedInViewController : IAViewController

@property (nonatomic, strong) IBOutlet NSTextField* not_logged_message;
@property (nonatomic, strong) IBOutlet NSButton* bottom_button;
@property (nonatomic, setter = setMode:) IANotLoggedInViewMode mode;
@property (nonatomic, strong) IBOutlet IAHoverButton* problem_button;
@property (nonatomic, strong) IBOutlet NSProgressIndicator* spinner;

- (id)initWithMode:(IANotLoggedInViewMode)mode
       andDelegate:(id<IANotLoggedInViewProtocol>)delegate;

@end

@protocol IANotLoggedInViewProtocol <NSObject>

- (void)notLoggedInViewWantsQuit:(IANotLoggedInViewController*)sender;

@end
