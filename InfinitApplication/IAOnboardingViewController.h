//
//  IAOnboardingViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 9/10/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface IAOnboardingWindow : NSWindow
@end

@protocol IAOnboardingViewProtocol;

@interface IAOnboardingViewController : NSViewController <NSWindowDelegate>

@property (nonatomic, strong) IBOutlet NSTextField* message;
@property (nonatomic, strong) IBOutlet NSButton* back_button;
@property (nonatomic, strong) IBOutlet NSButton* close_button;
@property (nonatomic, strong) IBOutlet NSImageView* files_icon;
@property (nonatomic, strong) IBOutlet NSButton* next_button;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* view_height;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* view_width;

- (id)initWithDelegate:(id<IAOnboardingViewProtocol>)delegate;

- (void)startOnboarding;

- (void)closeOnboarding;

@end

@protocol IAOnboardingViewProtocol <NSObject>

- (NSPoint)onboardingViewWantsInfinitIconPosition:(IAOnboardingViewController*)sender;

- (void)onboardingComplete:(IAOnboardingViewController*)sender;

@end