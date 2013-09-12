//
//  IAOnboardingViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 9/10/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol IAOnboardingViewProtocol;

@class IAOnboardingView;

@interface IAOnboardingViewController : NSViewController <NSWindowDelegate>

@property (nonatomic, strong) IBOutlet NSButton* back_button;
@property (nonatomic, strong) IBOutlet NSButton* close_button;
@property (nonatomic, strong) IBOutlet NSImageView* files_icon;
@property (nonatomic, strong) IBOutlet NSTextField* message;
@property (nonatomic, strong) IBOutlet IAOnboardingView* message_view;
@property (nonatomic, strong) IBOutlet NSButton* next_button;

- (id)initWithDelegate:(id<IAOnboardingViewProtocol>)delegate;

- (void)startOnboarding;

- (void)closeOnboarding;

@end

@protocol IAOnboardingViewProtocol <NSObject>

- (NSPoint)onboardingViewWantsInfinitIconPosition:(IAOnboardingViewController*)sender;
- (void)onboardingViewWantsStartPulseStatusBarIcon:(IAOnboardingViewController*)sender;
- (void)onboardingViewWantsStopPulseStatusBarIcon:(IAOnboardingViewController*)sender;

- (void)onboardingComplete:(IAOnboardingViewController*)sender;

@end