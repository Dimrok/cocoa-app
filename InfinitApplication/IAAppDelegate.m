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
#import "IALogFileManager.h"

//- Automatic Relaunching --------------------------------------------------------------------------

@implementation IAAppDelegate
{
@private
    IALogFileManager* _log_manager;
    BOOL _updating;
    NSInvocation* _update_invocation;
}

//- Sparkle Updater --------------------------------------------------------------------------------

- (void)setupUpdater
{
#ifdef BUILD_PRODUCTION
    [[SUUpdater sharedUpdater] setAutomaticallyChecksForUpdates:YES];
    [[SUUpdater sharedUpdater] setUpdateCheckInterval:3600]; // check every 1 hours
    [[SUUpdater sharedUpdater] checkForUpdatesInBackground];
#endif
}

// Overloaded so that we check for updates on the first launch
// https://github.com/andymatuschak/Sparkle/wiki/customization
- (BOOL)updaterShouldPromptForPermissionToCheckForUpdates:(SUUpdater*)bundle
{
    return YES;
}

- (BOOL)updater:(SUUpdater*)updater
shouldPostponeRelaunchForUpdate:(SUAppcastItem*)update
  untilInvoking:(NSInvocation*)invocation
{
    _updating = YES;
    [_controller handleQuit];
    _update_invocation = invocation;
    return YES;
}

- (void)updaterWillRelaunchApplication:(SUUpdater*)updater
{
    NSLog(@"%@ Will relaunch", self);
}

//- Login Items ------------------------------------------------------------------------------------

// XXX This will later be managed in settings
- (void)checkInLoginItems
{
#ifdef BUILD_PRODUCTION
    if (![[IAAutoStartup sharedInstance] appInLoginItemList])
        [[IAAutoStartup sharedInstance] addAppAsLoginItem];
#endif
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)init
{
    if (self = [super init])
    {
        // Log manager must be initialised here, before the new log file is written.
        _log_manager = [IALogFileManager sharedInstance];
        _updating = NO;
    }
    return self;
}

- (void)dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)applicationWillFinishLaunching:(NSNotification*)notification
{
    [self setupUpdater];
}

- (void)applicationDidFinishLaunching:(NSNotification*)aNotification
{
    _controller = [[IAMainController alloc] initWithDelegate:self];
    [self checkInLoginItems];
    NSAppleEventManager* appleEventManager = [NSAppleEventManager sharedAppleEventManager];
    [appleEventManager setEventHandler:self
                           andSelector:@selector(handleQuitEvent:withReplyEvent:)
                         forEventClass:kCoreEventClass
                            andEventID:kAEQuitApplication];
}

- (void)applicationWillResignActive:(NSNotification*)notification
{
    
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
    // If there's a problem quiting after 10 sec, terminate
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
    if (_updating)
    {
        [_update_invocation invoke];
        return;
    }
    NSLog(@"%@ Terminating application", self);
    [NSApp terminate:self];
}

@end
