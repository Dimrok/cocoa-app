//
//  IAAppDelegate.m
//  InfinitApplication
//
//  Created by Christopher Crone on 7/26/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAAppDelegate.h"

#import <Sparkle/Sparkle.h>

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
  [[SUUpdater sharedUpdater] setAutomaticallyDownloadsUpdates:YES];
  [[SUUpdater sharedUpdater] setAutomaticallyChecksForUpdates:YES];
  [[SUUpdater sharedUpdater] setUpdateCheckInterval:3600]; // check every 1 hours
  [[SUUpdater sharedUpdater] checkForUpdatesInBackground];
#endif
}

// Overloaded so that we check for updates on the first launch
// https://github.com/andymatuschak/Sparkle/wiki/customization
- (BOOL)updaterShouldPromptForPermissionToCheckForUpdates:(SUUpdater*)bundle
{
  return NO;
}

- (BOOL)updater:(SUUpdater*)updater
shouldPostponeRelaunchForUpdate:(SUAppcastItem*)update
  untilInvoking:(NSInvocation*)invocation
{
  _updating = YES;
  _update_invocation = invocation;
  [_controller handleQuit];
  return YES;
}

- (void)updaterWillRelaunchApplication:(SUUpdater*)updater
{
  NSLog(@"%@ Will relaunch", self);
}

- (void)delayedTryUpdate:(NSInvocation*)invocation
{
  if (_controller == nil || [_controller canUpdate])
  {
    _updating = YES;
    [invocation invoke];
  }
  else
  {
    [self performSelector:@selector(delayedTryUpdate:) withObject:invocation afterDelay:(10 * 60)];
  }
}

- (void)updater:(SUUpdater*)updater
willInstallUpdateOnQuit:(SUAppcastItem*)update
immediateInstallationInvocation:(NSInvocation*)invocation
{
  if (_controller == nil || [_controller canUpdate])
  {
    _updating = YES;
    [invocation invoke];
  }
  else
  {
    [self performSelector:@selector(delayedTryUpdate:) withObject:invocation afterDelay:(10 * 60)];
  }
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
  // If there's a problem quiting after 15 sec, terminate
  [self performSelector:@selector(delayedTerminate)
             withObject:nil
             afterDelay:15.0];
}

- (void)delayedTerminate
{
  NSLog(@"%@ Cleaning up took to long, killing application", self);
  [NSApp terminate:self];
}

//- Main Controller Protocol -----------------------------------------------------------------------

- (void)terminateApplication:(IAMainController*)sender
{
  if (_updating)
  {
    NSLog(@"%@ Invoking update: %@", self, _update_invocation);
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [_update_invocation invoke];
    NSLog(@"%@ Update invoked", self);
  }
  else
  {
    NSLog(@"%@ Terminating application", self);
    [NSApp terminate:self];
  }
}

- (void)mainControllerWantsCheckForUpdate:(IAMainController*)sender
{
  NSLog(@"%@ Checking for update verbosely", self);
#ifdef BUILD_PRODUCTION
  [[SUUpdater sharedUpdater] checkForUpdates:nil];
#endif
}

- (BOOL)applicationUpdating
{
  return _updating;
}

@end
