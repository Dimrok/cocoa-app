//
//  InfinitOnboardingController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 02/04/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitOnboardingController.h"

@implementation InfinitOnboardingController
{
@private
  id<InfinitOnboardingProtocol> _delegate;
}

@synthesize state = _state;

- (id)initWithDeleage:(id<InfinitOnboardingProtocol>)delegate
{
  if (self = [super init])
  {
    _delegate = delegate;
  }
  return self;
}

- (InfinitOnboardingState)state
{
  NSLog(@"xxx fetch state: %@", [self print:_state]);
  return _state;
}

- (void)setState:(InfinitOnboardingState)state
{
  _state = state;
  NSLog(@"xxx set state: %@", [self print:state]);
  [_delegate onboardingStateChanged:self toState:_state];
}

- (BOOL)inSendOnboarding
{
  switch (_state)
  {
    case INFINIT_ONBOARDING_SEND_NO_FILES_NO_DESTINATION:
    case INFINIT_ONBOARDING_SEND_FILES_NO_DESTINATION:
    case INFINIT_ONBOARDING_SEND_NO_FILES_DESTINATION:
      return YES;
      
    default:
      return NO;
  }
}

- (NSString*)print:(InfinitOnboardingState)state
{
  switch (state)
  {
    case INFINIT_ONBOARDING_RECEIVE_NOTIFICATION:
      return @"INFINIT_ONBOARDING_RECEIVE_NOTIFICATION";
    case INFINIT_ONBOARDING_RECEIVE_NO_ACTION:
      return @"INFINIT_ONBOARDING_RECEIVE_NO_ACTION";
    case INFINIT_ONBOARDING_RECEIVE_CLICKED_ICON:
      return @"INFINIT_ONBOARDING_RECEIVE_CLICKED_ICON";
    case INFINIT_ONBOARDING_RECEIVE_IN_CONVERSATION_VIEW:
      return @"INFINIT_ONBOARDING_RECEIVE_IN_CONVERSATION_VIEW";
    case INFINIT_ONBOARDING_RECEIVE_DONE:
      return @"INFINIT_ONBOARDING_RECEIVE_DONE";
    case INFINIT_ONBOARDING_SEND_FILES_NO_DESTINATION:
      return @"INFINIT_ONBOARDING_SEND_FILES_NO_DESTINATION";
    case INFINIT_ONBOARDING_SEND_NO_FILES_NO_DESTINATION:
      return @"INFINIT_ONBOARDING_SEND_NO_FILES_NO_DESTINATION";
    case INFINIT_ONBOARDING_SEND_NO_FILES_DESTINATION:
      return @"INFINIT_ONBOARDING_SEND_NO_FILES_DESTINATION";
    case INFINIT_ONBOARDING_SEND_FILES_DESTINATION:
      return @"INFINIT_ONBOARDING_SEND_FILES_DESTINATION";
    case INFINIT_ONBOARDING_SEND_FILE_SENDING:
      return @"INFINIT_ONBOARDING_SEND_FILE_SENDING";
    case INFINIT_ONBOARDING_SEND_FILE_SENT:
      return @"INFINIT_ONBOARDING_SEND_FILE_SENT";
    case INFINIT_ONBOARDING_SEND_CANCELLED:
      return @"INFINIT_ONBOARDING_SEND_CANCELLED";
    case INFINIT_ONBOARDING_DONE:
      return @"INFINIT_ONBOARDING_DONE";
    default:
      return @"unknown";
  }
}

@end
