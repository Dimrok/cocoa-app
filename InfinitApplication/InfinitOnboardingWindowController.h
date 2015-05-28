//
//  InfinitOnboardingWindowController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 27/05/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol InfinitOnboardingWindowProtocol;

@interface InfinitOnboardingWindowController : NSWindowController

@property (nonatomic, unsafe_unretained) id<InfinitOnboardingWindowProtocol> delegate;

@end

@protocol InfinitOnboardingWindowProtocol <NSObject>

- (void)onboardingWindowDidClose:(InfinitOnboardingWindowController*)sender;

@end
