//
//  IAAppDelegate.m
//  InfinitApplication
//
//  Created by Christopher Crone on 7/26/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAAppDelegate.h"

#import <Sparkle/Sparkle.h>

#import "IAAutoStartup.h"

@implementation IAAppDelegate

//- Initialisation ---------------------------------------------------------------------------------

- (void)setupUpdater
{
//    [[SUUpdater sharedUpdater] setDelegate:self];
//    [[SUUpdater sharedUpdater] setUpdateCheckInterval:3600]; // check every 1 hours
//    [[SUUpdater sharedUpdater] checkForUpdatesInBackground];
}

- (void)checkInLoginItems
{
//    if (![[IAAutoStartup sharedInstance] appInLoginItemList])
//        [[IAAutoStartup sharedInstance] addAppAsLoginItem];
}

- (void)awakeFromNib
{
    [self setupUpdater];
}

- (void)dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
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

//- Quit Handling ----------------------------------------------------------------------------------

- (void)handleQuitEvent:(NSAppleEventDescriptor*)event
         withReplyEvent:(NSAppleEventDescriptor*)reply_event
{
    NSLog(@"%@ Handle quit event", self);
    [_controller handleQuit];
}

- (IBAction)cleanQuit:(id)sender
{
    [_controller handleQuit];
    [self performSelector:@selector(delayedTerminate)
               withObject:nil
               afterDelay:10.0];
}

- (void)delayedTerminate
{
    [NSApp terminate:self];
}

//- Main Controller Protocol -----------------------------------------------------------------------

- (void)terminateApplication:(IAMainController*)sender
{
    NSLog(@"%@ Terminating application", self);
    [NSApp terminate:self];
}

@end
