//
//  IAOnboardingViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 9/27/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IAHoverButton.h"
#import "IAViewController.h"

@protocol IAOnboardingProtocol;

@interface IAOnboardingViewController : IAViewController

@property (nonatomic, strong) IBOutlet NSButton* back_button;
@property (nonatomic, strong) IBOutlet NSTextField* heading;
@property (nonatomic, strong) IBOutlet NSTextField* message;
@property (nonatomic, strong) IBOutlet NSButton* next_button;
@property (nonatomic, strong) IBOutlet IAHoverButton* skip_button;

- (id)initWithDelegate:(id<IAOnboardingProtocol>)delegate;

@end


@protocol IAOnboardingProtocol <NSObject>

- (void)onboardingControllerDone:(IAOnboardingViewController*)sender;

- (void)onboardingControllerStarted:(IAOnboardingViewController*)sender;

@end