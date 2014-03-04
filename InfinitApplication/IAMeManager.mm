//
//  IAMeManager.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/30/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAMeManager.h"

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("OSX.MeManager");

@implementation IAMeManager
{
@private
    id<IAMeManagerProtocol> _delegate;
}

//- Initialisation ---------------------------------------------------------------------------------

@synthesize connection_status = _connection_status;

- (id)initWithDelegate:(id<IAMeManagerProtocol>)delegate
{
    if (self = [super init])
    {
        _delegate = delegate;
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(onConnectionStatus:)
                                                   name:IA_GAP_EVENT_CONNECTION_STATUS_NOTIFICATION
                                                 object:nil];
    }
    return self;
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

//- Connection Callback ----------------------------------------------------------------------------

- (void)onConnectionStatus:(NSNotification*)notification
{
    NSDictionary* dict = notification.userInfo;
    NSNumber* received_status = [dict valueForKey:@"connection_status"];
    if (received_status == nil)
    {
        ELLE_WARN("%s: problem with receiving connection status", self.description.UTF8String);
        return;
    }
    
    _connection_status = (gap_UserStatus)received_status.intValue;
    [_delegate meManager:self
hadConnectionStateChange:_connection_status];
}

//- General Functions ------------------------------------------------------------------------------

@end
