//
//  IAConversationViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/5/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAConversationViewController.h"

@interface IAConversationViewController ()

@end

@implementation IAConversationViewController
{
@private
    id<IAConversationViewProtocol> _delegate;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithDelegate:(id<IAConversationViewProtocol>)delegate
{
    if (self = [super initWithNibName:self.className bundle:nil])
    {
        _delegate = delegate;
    }
    return self;
}

- (NSString*)description
{
    return @"[ConversationView]";
}

- (BOOL)closeOnFocusLost
{
    return YES;
}

- (void)awakeFromNib
{
    
}

@end
