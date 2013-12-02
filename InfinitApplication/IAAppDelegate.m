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
    
    NSURL* _infinit_url;
}

//- Sparkle Updater --------------------------------------------------------------------------------

- (void)setupUpdater
{
#ifdef BUILD_PRODUCTION
    [[SUUpdater sharedUpdater] setAutomaticallyChecksForUpdates:YES];
    [[SUUpdater sharedUpdater] setUpdateCheckInterval:3600]; // check every 1 hours
    [[SUUpdater sharedUpdater] checkForUpdatesInBackground];
    [[SUUpdater sharedUpdater] setAutomaticallyDownloadsUpdates:NO];
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
    [self performSelector:@selector(updateOnTimeout) withObject:nil afterDelay:10.0];
    return YES;
}

- (void)updateOnTimeout
{
    NSLog(@"%@ Took too long cleaning up, invoking update", self);
    [_update_invocation invoke];
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
        _infinit_url = nil;
    }
    return self;
}

- (void)dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)applicationWillFinishLaunching:(NSNotification*)notification
{
    [self setupUpdater];
    NSAppleEventManager* appleEventManager = [NSAppleEventManager sharedAppleEventManager];
    [appleEventManager setEventHandler:self
                           andSelector:@selector(handleQuitEvent:withReplyEvent:)
                         forEventClass:kCoreEventClass
                            andEventID:kAEQuitApplication];

    [appleEventManager setEventHandler:self
                           andSelector:@selector(getURL:withReplyEvent:)
                         forEventClass:kInternetEventClass
                            andEventID:kAEGetURL];
}

- (void)applicationDidFinishLaunching:(NSNotification*)aNotification
{
    _controller = [[IAMainController alloc] initWithDelegate:self];
    [self checkInLoginItems];
    if (_infinit_url != nil) // Infinit was launched with a link
        [_controller handleInfinitLink:_infinit_url];
}

- (void)applicationWillResignActive:(NSNotification*)notification
{
    
}

//- Infinit URL Handling ---------------------------------------------------------------------------

- (void)getURL:(NSAppleEventDescriptor*)event
withReplyEvent:(NSAppleEventDescriptor*)reply_event
{
    NSURL* infinit_url = [NSURL URLWithString:[[event paramDescriptorForKeyword:keyDirectObject]
                                               stringValue]];
    if (_controller == nil) // We haven't created a controller yet as we're being launched by a link
        _infinit_url = infinit_url;
    else
        [_controller handleInfinitLink:infinit_url];
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
    IALog(@"%@ Cleaning up took to long, killing application", self);
    [NSApp terminate:self];
}

//- Main Controller Protocol -----------------------------------------------------------------------

- (void)terminateApplication:(IAMainController*)sender
{
    if (_updating)
    {
        NSLog(@"%@ Invoking update", self);
        [_update_invocation invoke];
        return;
    }
    NSLog(@"%@ Terminating application", self);
    [NSApp terminate:self];
}

- (void)mainControllerWantsCheckForUpdate:(IAMainController*)sender
{
    NSLog(@"%@ Checking for update verbosely", self);
#ifdef BUILD_PRODUCTION
    [[SUUpdater sharedUpdater] checkForUpdates:nil];
#endif
}

@end
