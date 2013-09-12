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

@implementation NSApplication (Relaunch)

- (void)relaunchAfterDelay:(float)seconds
{
	NSTask* task = [[NSTask alloc] init];
	NSMutableArray* args = [NSMutableArray array];
	[args addObject:[NSString stringWithFormat:@"sleep %f; open \"%@\"",
                                               seconds,
                                               [[NSBundle mainBundle] bundlePath]]];
	[task setLaunchPath:@"/bin/sh"];
	[task setArguments:args];
	[task launch];
	
	[self terminate:nil];
}

@end

@implementation IAAppDelegate
{
@private
    IALogFileManager* _log_manager;
}

//- Sparkle Updator --------------------------------------------------------------------------------

#ifdef BUILD_PRODUCTION

- (void)setupUpdater
{
    [[SUUpdater sharedUpdater] setDelegate:self];
    [[SUUpdater sharedUpdater] setUpdateCheckInterval:3600]; // check every 1 hours
    [[SUUpdater sharedUpdater] checkForUpdatesInBackground];
}

#endif

//- Login Items ------------------------------------------------------------------------------------

#ifdef BUILD_PRODUCTION

// XXX This will later be managed in settings
- (void)checkInLoginItems
{
    if (![[IAAutoStartup sharedInstance] appInLoginItemList])
        [[IAAutoStartup sharedInstance] addAppAsLoginItem];
}

#endif

//- Initialisation ---------------------------------------------------------------------------------

- (id)init
{
    if (self = [super init])
    {
        // Log manager must be initialised here, before the new log file is written.
        _log_manager = [IALogFileManager sharedInstance];
    }
    return self;
}

- (void)dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)awakeFromNib
{
#ifdef BUILD_PRODUCTION
    [self setupUpdater];
#endif
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
    NSLog(@"%@ Terminating application", self);
    [NSApp terminate:self];
}

@end
