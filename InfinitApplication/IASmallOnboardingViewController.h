//
//  IASmallOnboardingViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 9/27/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol IASmallOnboardingProtocol;

@interface IASmallOnboardingViewController : NSViewController <NSPopoverDelegate>

@property (nonatomic, strong) IBOutlet NSButton* back_button;
@property (nonatomic, strong) IBOutlet NSTextField* heading;
@property (nonatomic, strong) IBOutlet NSTextField* message;
@property (nonatomic, strong) IBOutlet NSButton* next_button;
@property (nonatomic, strong) IBOutlet NSPopover* popover;
@property (nonatomic, strong) IBOutlet NSButton* skip_button;

- (id)initWithDelegate:(id<IASmallOnboardingProtocol>)delegate;

- (void)startOnboardingWithStatusBarItem:(NSStatusItem*)item;

- (void)skipOnboarding;

@end


@protocol IASmallOnboardingProtocol <NSObject>

- (void)smallOnboardingDoneOnboarding:(IASmallOnboardingViewController*)sender;

@end