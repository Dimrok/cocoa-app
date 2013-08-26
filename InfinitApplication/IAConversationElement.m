//
//  IAConversationElement.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/26/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAConversationElement.h"

@implementation IAConversationElement

@synthesize on_left = _on_left;
@synthesize transaction = _transaction;
@synthesize mode = _mode;

- (id)initWithTransaction:(IATransaction*)transaction
{
    if (self = [super init])
    {
        self.mode = CONVERSATION_CELL_VIEW_NORMAL;
        _transaction = transaction;
        if (self.transaction.from_me)
            _on_left = NO;
        else
            _on_left = YES;
    }
    return self;
}

@end
