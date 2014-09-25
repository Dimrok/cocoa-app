//
//  InfinitNetworkManager.h
//  InfinitApplication
//
//  Created by Christopher Crone on 22/09/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "InfinitProxyWindow.h"

@protocol InfinitNetworkManagerProtocol;

@interface InfinitNetworkManager : NSObject <InfinitProxyWindowProtocol>

- (id)initWithDelegate:(id<InfinitNetworkManagerProtocol>)delegate;

@end

@protocol InfinitNetworkManagerProtocol <NSObject>

@end