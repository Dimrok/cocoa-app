//
//  InfinitGhostSendWindowController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 25/06/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface InfinitGhostSendWindowController : NSWindowController

@property (nonatomic, copy) void (^send_block)();

@end
