//
//  InfinitConversationElement.m
//  InfinitApplication
//
//  Created by Christopher Crone on 17/03/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitConversationElement.h"

@implementation InfinitConversationElement

@synthesize transaction = _transaction;
@synthesize important = _important;
@synthesize spacer = _spacer;
@synthesize on_left = _on_left;

- (id)initWithTransaction:(IATransaction*)transaction
{
  if (self = [super init])
  {
    self.showing_files = NO;
    if (transaction == nil)
    {
      _spacer = YES;
      return self;
    }
    else
      _spacer = NO;
    _transaction = transaction;
    if (transaction.from_me)
      _on_left = NO;
    else
      _on_left = YES;
    if (transaction.is_active || transaction.is_new || transaction.needs_action)
      _important = YES;
    else
      _important = NO;
  }
  return self;
}

@end
