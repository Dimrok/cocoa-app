//
//  InfinitConversationElement.m
//  InfinitApplication
//
//  Created by Christopher Crone on 17/03/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitConversationElement.h"

@implementation InfinitConversationElement

- (id)initWithTransaction:(InfinitPeerTransaction*)transaction
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
    if (transaction.sender.is_self && transaction.recipient.is_self)
      _on_left = !transaction.from_device;
    else if (transaction.sender.is_self)
      _on_left = NO;
    else
      _on_left = YES;
    if (!transaction.done)
      _important = YES;
    else
      _important = NO;
  }
  return self;
}

+ (id)initWithTransaction:(InfinitPeerTransaction*)transaction
{
  return [[InfinitConversationElement alloc] initWithTransaction:transaction];
}

@end
