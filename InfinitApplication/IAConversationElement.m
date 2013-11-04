//
//  IAConversationElement.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/26/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAConversationElement.h"

@implementation IAConversationElement

@synthesize historic = _historic;
@synthesize mode = _mode;
@synthesize on_left = _on_left;
@synthesize transaction = _transaction;

- (id)initWithTransaction:(IATransaction*)transaction
{
    if (self = [super init])
    {
        self.mode = CONVERSATION_CELL_VIEW_NORMAL;
        _transaction = transaction;
        // Which side of the view the item should appear on
        if (self.transaction.from_me)
            _on_left = NO;
        else
            _on_left = YES;
        // If the view is current or historic
        if (self.transaction.is_active || self.transaction.is_new || self.transaction.needs_action)
            _historic = NO;
        else
            _historic = YES;
    }
    return self;
}

@end
