//
//  IAAppDelegate.m
//  InfinitApplication
//
//  Created by Christopher Crone on 7/26/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAAppDelegate.h"

#include <sys/mount.h>

#import <Sparkle/Sparkle.h>

#import "IAUserPrefs.h"
#import "InfinitDownloadDestinationManager.h"
#import "InfinitFeatureManager.h"

#import <Gap/InfinitGhostCodeManager.h>
#import <Gap/InfinitStateManager.h>
#import <Gap/InfinitURLParser.h>

@interface IAAppDelegate () <NSApplicationDelegate,
                             IAMainControllerProtocol>

@property (assign) IBOutlet NSWindow* window;

@property NSArray* contextual_link_files;
@property NSArray* contextual_send_files;
@property (nonatomic) IAMainController* controller;
@property NSString* fingerprint;
@property NSURL* infinit_url;
@property (nonatomic, readonly) BOOL readonly_volume;
@property NSInvocation* update_invocation;
@property BOOL updating;

@end

static NSTimeInterval _auto_update_check_interval = 24 * 60 * 60.0f; // Automatic update check period.
static NSTimeInterval _startup_install_timeout = 20 * 60.0f; // Timeout for startup download and install.
static NSTimeInterval _startup_update_check_timeout = 45.0f; // Timeout for startup check for update.
static NSTimeInterval _update_install_retry_cooldown = 2 * 60.0f; // Install retry period.

@implementation IAAppDelegate

#pragma mark - Init

- (void)dealloc
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
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
  NSArray* arguments = [NSProcessInfo processInfo].arguments;
  for (int i = 0; i < arguments.count; i++)
  {
    NSString* arg = arguments[i];
    if ([arg isEqualToString:@"code"] && (i < arguments.count))
    {
      NSString* code = arguments[i + 1];
      if (code.length)
        self.fingerprint = code;
    }
  }
  // Check for updates before anything else unless we were launched with a fingerpirnt.
  //If there are no updates then continue, otherwise do nothing as the update will be performed.
#if DEBUG
  [self startMainController];
#else
  if (self.fingerprint.length || self.readonly_volume)
  {
    NSLog(@"Skip startup update check because of fingerprint or read only volume");
    [self startMainController];
  }
  else
  {
    NSLog(@"Startup update check");
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(noUpdateAvailableOnStartup) 
                                                 name:SUUpdaterDidNotFindUpdateNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateAvailableOnStartup) 
                                                 name:SUUpdaterDidFindValidUpdateNotification 
                                               object:nil];
    [self performSelector:@selector(startupUpdateCheckTimedOut)
               withObject:nil 
               afterDelay:_startup_update_check_timeout];
    [[SUUpdater sharedUpdater] checkForUpdatesInBackground];
  }
#endif
}

- (void)startMainController
{
  static dispatch_once_t _controller_token = 0;
  dispatch_once(&_controller_token, ^
  {
    [NSApp setServicesProvider:self];
    NSString* download_dir =
      [InfinitDownloadDestinationManager sharedInstance].download_destination;
    [InfinitStateManager startStateWithDownloadDir:download_dir];
    [InfinitFeatureManager sharedInstance];

    self.controller = [[IAMainController alloc] initWithDelegate:self];
    if (self.infinit_url != nil) // Infinit was launched with a link
      [self.controller handleInfinitLink:self.infinit_url];
    else if (self.contextual_send_files != nil) // Infinit was launched to send files
      [self.controller handleContextualSendFiles:self.contextual_send_files];

    if (self.fingerprint.length)
      [[InfinitStateManager sharedInstance] addFingerprint:self.fingerprint];
  });
}

#pragma mark - URL Handling

- (void)getURL:(NSAppleEventDescriptor*)event
withReplyEvent:(NSAppleEventDescriptor*)reply_event
{
  NSURL* infinit_url =
    [NSURL URLWithString:[event paramDescriptorForKeyword:keyDirectObject].stringValue];
  NSString* invite_code = [InfinitURLParser getGhostCodeFromURL:infinit_url];
  if (invite_code.length)
  {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(500 * NSEC_PER_MSEC)),
                   dispatch_get_main_queue(), ^
    {
      [[InfinitGhostCodeManager sharedInstance] setCode:invite_code 
                                                wasLink:YES 
                                        completionBlock:nil];
    });
    return;
  }
  if (self.controller == nil) // We haven't created a controller yet as we're being launched by a link
    self.infinit_url = infinit_url;
  else
    [self.controller handleInfinitLink:infinit_url];
}

#pragma mark - Contextual Menu Handling

- (void)contextMenuSendFile:(NSPasteboard*)paste_board
                   userData:(NSString*)user_data
                      error:(NSString**)error
{
  NSArray* files = [paste_board propertyListForType:NSFilenamesPboardType];
  if (files.count == 0)
    return;
  if (self.controller == nil)
    self.contextual_send_files = files;
  else
    [self.controller handleContextualSendFiles:files];
}

- (void)contextMenuCreateLink:(NSPasteboard*)paste_board
                     userData:(NSString*)user_data
                        error:(NSString**)error
{
  NSArray* files = [paste_board propertyListForType:NSFilenamesPboardType];
  if (files.count == 0)
    return;
  if (self.controller == nil)
    self.contextual_link_files = files;
  else
    [self.controller handleContextualCreateLink:files];
}

#pragma mark - Quit Handling

- (void)handleQuitEvent:(NSAppleEventDescriptor*)event
         withReplyEvent:(NSAppleEventDescriptor*)reply_event
{
  NSLog(@"Handle quit event");
  [self.controller handleQuit];
}

- (IBAction)cleanQuit:(id)sender
{
  [self.controller handleQuit];
  // If there's a problem quiting after 15 sec, terminate
  [self performSelector:@selector(delayedTerminate)
             withObject:nil
             afterDelay:15.0f];
}

- (void)delayedTerminate
{
  NSLog(@"Cleaning up took to long, killing application");
  [NSApp performSelector:@selector(terminate:) withObject:nil afterDelay:0.0f];
}

#pragma mark - Settings

- (IBAction)openPreferences:(id)sender
{
  [self.controller openPreferences];
}

#pragma mark - IAMainControllerProtocol

- (void)terminateApplication:(IAMainController*)sender
{
  if (self.updating)
  {
    NSLog(@"Invoking update: %@", self.update_invocation);
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self.update_invocation invoke];
    NSLog(@"Update invoked");
  }
  else
  {
    NSLog(@"Terminating application");
    [NSApp performSelector:@selector(terminate:) withObject:nil afterDelay:0.0f];
  }
}

- (void)mainControllerWantsCheckForUpdate:(IAMainController*)sender
{
  NSLog(@"Checking for update verbosely");
  [[SUUpdater sharedUpdater] checkForUpdates:self];
}

- (void)mainControllerWantsBackgroundUpdateChecks:(IAMainController*)sender
{
#if !DEBUG
  [[SUUpdater sharedUpdater] checkForUpdatesInBackground];
#endif
}

- (BOOL)applicationUpdating
{
  return self.updating;
}

#pragma mark - Sparkle Updater

- (void)setupUpdater
{
#if DEBUG
  [[SUUpdater sharedUpdater] setAutomaticallyDownloadsUpdates:NO];
  [[SUUpdater sharedUpdater] setAutomaticallyChecksForUpdates:NO];
  NSLog(@"Not checking for updates");
#else
  [[SUUpdater sharedUpdater] setAutomaticallyDownloadsUpdates:YES];
  [[SUUpdater sharedUpdater] setAutomaticallyChecksForUpdates:YES];
  [[SUUpdater sharedUpdater] setUpdateCheckInterval:_auto_update_check_interval];
  NSLog(@"Will check for updates");
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
  self.updating = YES;
  self.update_invocation = invocation;
  if (self.controller != nil)
    [self.controller handleQuit];
  else
    [self terminateApplication:nil];
  return YES;
}

- (void)updaterWillRelaunchApplication:(SUUpdater*)updater
{
  NSLog(@"Will relaunch");
  [NSObject cancelPreviousPerformRequestsWithTarget:self
                                           selector:@selector(startupUpdateInstallTimedOut)
                                             object:nil];
  [[IAUserPrefs sharedInstance] setPrefNow:@"1" forKey:@"updated"];
}

- (void)delayedTryUpdate:(NSInvocation*)invocation
{
  if (!self.controller || [self.controller canUpdate])
  {
    self.updating = YES;
    [invocation invoke];
  }
  else
  {
    [self performSelector:@selector(delayedTryUpdate:)
               withObject:invocation 
               afterDelay:_update_install_retry_cooldown];
  }
}

- (void)updater:(SUUpdater*)updater
willInstallUpdateOnQuit:(SUAppcastItem*)update
immediateInstallationInvocation:(NSInvocation*)invocation
{
  if (!self.controller || [self.controller canUpdate])
  {
    self.updating = YES;
    [invocation invoke];
  }
  else
  {
    [self performSelector:@selector(delayedTryUpdate:)
               withObject:invocation
               afterDelay:_update_install_retry_cooldown];
  }
}

- (void)gotStartupUpdateReply
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self 
                                           selector:@selector(startupUpdateCheckTimedOut)
                                             object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:SUUpdaterDidFindValidUpdateNotification
                                                object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:SUUpdaterDidNotFindUpdateNotification
                                                object:nil];
}

- (void)startupUpdateInstallTimedOut
{
  NSLog(@"Startup update install timedout");
  dispatch_async(dispatch_get_main_queue(), ^
  {
    [self startMainController];
  });
}

- (void)updateAvailableOnStartup
{
  [self gotStartupUpdateReply];
  NSLog(@"Update available on startup");
  [self performSelector:@selector(startupUpdateInstallTimedOut)
             withObject:nil
             afterDelay:_startup_install_timeout];
}

- (void)noUpdateAvailableOnStartup
{
  [self gotStartupUpdateReply];
  NSLog(@"No update available on startup");
  dispatch_async(dispatch_get_main_queue(), ^
  {
    [self startMainController];
  });
}

- (void)startupUpdateCheckTimedOut
{
  [self gotStartupUpdateReply];
  NSLog(@"Startup check for updates timed out");
  dispatch_async(dispatch_get_main_queue(), ^
  {
    [self startMainController];
  });
}

#pragma mark - Helpers

- (BOOL)readonly_volume
{
  struct statfs statfs_info;
  statfs([NSBundle mainBundle].bundlePath.fileSystemRepresentation, &statfs_info);
  return (statfs_info.f_flags & MNT_RDONLY);
}

@end
