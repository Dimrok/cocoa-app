//
//  InfinitDownloadDestinationManager.m
//  InfinitApplication
//
//  Created by Christopher Crone on 07/10/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitDownloadDestinationManager.h"

#import "IAUserPrefs.h"

#import <Gap/InfinitDirectoryManager.h>
#import <Gap/InfinitStateManager.h>

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("OSX.DownloadDestinationManager");

static InfinitDownloadDestinationManager* _instance = nil;
static dispatch_once_t _instance_token = 0;

@implementation InfinitDownloadDestinationManager

//- Initialisation ---------------------------------------------------------------------------------

- (id)init
{
  if (self = [super init])
  {
    _download_destination = [[IAUserPrefs sharedInstance] prefsForKey:@"download_directory"];
    if (!self.download_destination.length)
      _download_destination = [InfinitDirectoryManager sharedInstance].download_directory;
  }
  return self;
}

+ (instancetype)sharedInstance
{
  dispatch_once(&_instance_token, ^
  {
    _instance = [[InfinitDownloadDestinationManager alloc] init];
  });
  return _instance;
}

//- Set Download Destination -----------------------------------------------------------------------

- (void)setDownloadDestination:(NSString*)download_destination
                   forFallback:(BOOL)fallback
{
  [[IAUserPrefs sharedInstance] setPref:download_destination forKey:@"download_directory"];
  [[InfinitStateManager sharedInstance] setDownloadDirectory:download_destination fallback:fallback];
  _download_destination = download_destination;
  [InfinitDirectoryManager sharedInstance].download_directory = self.download_destination;
}

- (void)setDownloadDestination:(NSString*)download_destination
{
  [self setDownloadDestination:download_destination forFallback:NO];
}

//- Ensure Download Destination --------------------------------------------------------------------

- (void)ensureDownloadDestination
{
  BOOL is_dir;
  BOOL exists =
    [[NSFileManager defaultManager] fileExistsAtPath:self.download_destination isDirectory:&is_dir];
  BOOL writable = [[NSFileManager defaultManager] isWritableFileAtPath:self.download_destination];
  if (exists && is_dir && writable)
    return;

  NSString* download_dir =
    [NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES) firstObject];

  if (!exists)
  {
    ELLE_WARN("%s: destination directory doesn't exist, falling back to download folder: %s",
              self.description.UTF8String, download_dir);
  }
  else if (!is_dir)
  {
    ELLE_WARN("%s: destination isn't directory, falling back to download folder: %s",
              self.description.UTF8String, download_dir);
  }
  else if (!writable)
  {
    ELLE_WARN("%s: destination isn't writable, falling back to download folder: %s",
              self.description.UTF8String, download_dir);
  }
  [self setDownloadDestination:download_dir forFallback:YES];
}

@end
