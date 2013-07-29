//
//  IAAppDelegate.m
//  InfinitApplication
//
//  Created by Christopher Crone on 7/26/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAAppDelegate.h"

#import <Sparkle/Sparkle.h>

@implementation IAAppDelegate

- (void)awakeFromNib
{
//    [[SUUpdater sharedUpdater] setDelegate:self];
//    [[SUUpdater sharedUpdater] setUpdateCheckInterval:3600]; // check every 1 hours
//    [[SUUpdater sharedUpdater] checkForUpdatesInBackground];
}

- (NSString*)description
{
    return @"[IAAppDelegate]";
}

- (void)applicationDidFinishLaunching:(NSNotification*)aNotification
{
    _controller = [[IAMainController alloc] initWithDelegate:self];
    NSAppleEventManager* appleEventManager = [NSAppleEventManager sharedAppleEventManager];
    [appleEventManager setEventHandler:self
                           andSelector:@selector(handleQuitEvent:withReplyEvent:)
                         forEventClass:kCoreEventClass
                            andEventID:kAEQuitApplication];
}

- (void)applicationWillResignActive:(NSNotification*)notification
{
    
}

- (void)updaterWillRelaunchApplication:(SUUpdater*)updater
{
    NSLog(@"%@ Sparkle updating, will relaunch", self);
}

- (void)handleQuitEvent:(NSAppleEventDescriptor*)event
         withReplyEvent:(NSAppleEventDescriptor*)reply_event
{
    NSLog(@"%@ Handle quit event", self);
    [_controller handleQuit];
}

- (void)quitApplication:(IAMainController*)sender
{
    NSLog(@"%@ Terminating application", self);
    [NSApp terminate:self];
}

@end
