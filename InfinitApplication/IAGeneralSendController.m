//
//  IAGeneralSendController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/2/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAGeneralSendController.h"

@implementation IAGeneralSendController
{
@private
    // Delegate
    id<IAGeneralSendControllerProtocol> _delegate;
    
    // Send views
    IASimpleSendViewController* _simple_send_controller;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithDelegate:(id<IAGeneralSendControllerProtocol>)delegate
{
    if (self = [super init])
    {
        _delegate = delegate;
    }
    return self;
}

//- General Functions ------------------------------------------------------------------------------

- (void)simpleFileDrop
{
    _simple_send_controller = [[IASimpleSendViewController alloc] initWithDelegate:self];
    [_delegate sendController:self wantsActiveController:_simple_send_controller];
}

@end
