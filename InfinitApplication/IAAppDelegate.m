//
//  IAAppDelegate.m
//  InfinitApplication
//
//  Created by Christopher Crone on 7/26/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAAppDelegate.h"

@implementation IAAppDelegate

- (void)awakeFromNib
{
    _controller = [IAMainController instance];
}

- (void)applicationDidFinishLaunching:(NSNotification*)aNotification
{
    // Insert code here to initialize your application
}

- (void)applicationWillResignActive:(NSNotification*)notification
{
    
}

@end
