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
    
    NSMutableArray* _files;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithDelegate:(id<IAGeneralSendControllerProtocol>)delegate
{
    if (self = [super init])
    {
        _delegate = delegate;
        _files = [NSMutableArray array];
    }
    return self;
}

//- Open Functions ---------------------------------------------------------------------------------

- (void)openWithNoFile
{
    _simple_send_controller = [[IASimpleSendViewController alloc] initWithDelegate:self];
    [_delegate sendController:self wantsActiveController:_simple_send_controller];
}

- (void)openWithFiles:(NSArray*)files
{
    [_files addObjectsFromArray:files];
}

@end
