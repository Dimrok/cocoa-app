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
  INFINIT_ONBOARDING_RECEIVE_NOTIFICATION, // start of onboarding: desktop notification receieved
  INFINIT_ONBOARDING_RECEIVE_NO_ACTION, // if the user doesn't respond to the notification
  INFINIT_ONBOARDING_RECEIVE_CLICKED_ICON, // user clicks on infinit icon with transaction waiting
  INFINIT_ONBOARDING_RECEIVE_IN_CONVERSATION_VIEW, // user goes into conversation view
  INFINIT_ONBOARDING_RECEIVE_ACTION_DONE, // user has chosen to accept/decline
  INFINIT_ONBOARDING_RECEIVE_VIEW_DOWNLOAD, // user clicked to show in finder
  INFINIT_ONBOARDING_RECEIVE_CONVERSATION_VIEW_DONE, // finished in conversation view
  INFINIT_ONBOARDING_RECEIVE_DONE, // receive onboarding complete
  INFINIT_ONBOARDING_SEND_FILES_NO_DESTINATION, // file dragged onto icon
  INFINIT_ONBOARDING_SEND_NO_FILES_NO_DESTINATION, // user clicked through infinit icon to send view
  INFINIT_ONBOARDING_SEND_NO_FILES_DESTINATION, // user clicked through conversation view to send view
  INFINIT_ONBOARDING_SEND_FILES_DESTINATION, // ready to send
  INFINIT_ONBOARDING_SEND_FILE_SENDING, // send clicked
  INFINIT_ONBOARDING_SEND_FILE_SENT, // send completed
  INFINIT_ONBOARDING_DONE, // onboarding complete
} InfinitOnboardingState;

@protocol InfinitOnboardingProtocol;

@interface InfinitOnboardingController : NSObject

@property (nonatomic, readwrite) InfinitOnboardingState state;
@property (nonatomic, readonly) IATransaction* receive_transaction;
@property (nonatomic, readwrite) IATransaction* send_transaction;
@property (nonatomic, readonly) BOOL receive_onboarding_done;

- (id)initWithDelegate:(id<InfinitOnboardingProtocol>)delegate
       andReceiveTransaction:(IATransaction*)transaction;

- (id)initForSendOnboardingWithDelegate:(id<InfinitOnboardingProtocol>)delegate;

- (BOOL)inSendOnboarding;

@end

@protocol InfinitOnboardingProtocol <NSObject>

- (void)onboardingStateChanged:(InfinitOnboardingController*)sender
                       toState:(InfinitOnboardingState)state;

@end
