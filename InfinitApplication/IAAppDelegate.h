//
//  IAAppDelegate.h
//  InfinitApplication
//
//  Created by Christopher Crone on 7/26/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IAMainController.h"

@interface IAAppDelegate : NSObject <NSApplicationDelegate,
                                     IAMainControllerProtocol>
{
@private
    IAMainController* _controller;
}

@property (assign) IBOutlet NSWindow *window;

@end
