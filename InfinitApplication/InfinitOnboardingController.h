//
//  InfinitOnboardingController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 02/04/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum __InfinitOnboardingState
{
  INFINIT_ONBOARDING_RECEIVE_NOTIFICATION,
  INFINIT_ONBOARDING_RECEIVE_NO_ACTION, // for main controller
  INFINIT_ONBOARDING_RECEIVE_CLICKED_ICON,
  INFINIT_ONBOARDING_RECEIVE_IN_CONVERSATION_VIEW,
  INFINIT_ONBOARDING_RECEIVE_ACTION_DONE,
  INFINIT_ONBOARDING_RECEIVE_CONVERSATION_VIEW_DONE,
  INFINIT_ONBOARDING_RECEIVE_DONE, // for main controller
  INFINIT_ONBOARDING_SEND_FILES_NO_DESTINATION,
  INFINIT_ONBOARDING_SEND_NO_FILES_NO_DESTINATION,
  INFINIT_ONBOARDING_SEND_NO_FILES_DESTINATION,
  INFINIT_ONBOARDING_SEND_FILES_DESTINATION,
  INFINIT_ONBOARDING_SEND_FILE_SENDING, // for main controller
  INFINIT_ONBOARDING_SEND_FILE_SENT, // for main controller
  INFINIT_ONBOARDING_SEND_CANCELLED, // for main controller
  INFINIT_ONBOARDING_DONE, // for main controller
} InfinitOnboardingState;

@protocol InfinitOnboardingProtocol;

@interface InfinitOnboardingController : NSObject

@property (nonatomic, readwrite) InfinitOnboardingState state;

- (id)initWithDeleage:(id<InfinitOnboardingProtocol>)delegate;

- (BOOL)inSendOnboarding;

@end

@protocol InfinitOnboardingProtocol <NSObject>

- (void)onboardingStateChanged:(InfinitOnboardingController*)sender
                       toState:(InfinitOnboardingState)state;

@end
