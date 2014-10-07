//
//  InfinitSettingsGeneralView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 25/08/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitSettingsGeneralView.h"

#import <Gap/IAGapState.h>

#import "InfinitDownloadDestinationManager.h"

@interface InfinitSettingsGeneralView ()

@end

@implementation InfinitSettingsGeneralView
{
@private
  __unsafe_unretained id<InfinitSettingsGeneralProtocol> _delegate;

  BOOL _auto_launch;
  BOOL _auto_upload_screenshots;
  BOOL _auto_stay_awake;
  NSString* _download_dir_str;
}

//- Initialization ---------------------------------------------------------------------------------

- (id)initWithDelegate:(id<InfinitSettingsGeneralProtocol>)delegate
{
  if (self = [super initWithNibName:self.className bundle:nil])
  {
    _delegate = delegate;
  }
  return self;
}

- (void)loadData
{
  _auto_launch = [_delegate infinitInLoginItems:self];
  _auto_upload_screenshots = [_delegate uploadsScreenshots:self];
  _auto_stay_awake = [_delegate stayAwake:self];
  _download_dir_str = [[InfinitDownloadDestinationManager sharedInstance] download_destination];
  if (_auto_launch)
    self.launch_at_startup.state = NSOnState;
  else
    self.launch_at_startup.state = NSOffState;

  if (_auto_upload_screenshots)
    self.upload_screenshots.state = NSOnState;
  else
    self.upload_screenshots.state = NSOffState;

  if (_auto_stay_awake)
    self.stay_awake.state = NSOnState;
  else
    self.stay_awake.state = NSOffState;

  self.download_dir.stringValue = _download_dir_str;
}

- (void)loadView
{
  [super loadView];
  [self loadData];
}

//- General Functions ------------------------------------------------------------------------------

- (NSSize)startSize
{
  return NSMakeSize(480.0, 220.0);
}

//- Toggle Handling --------------------------------------------------------------------------------

- (IBAction)toggleLaunchAtStartup:(NSButton*)sender
{
  if (self.launch_at_startup.state == NSOnState)
    _auto_launch = YES;
  else
    _auto_launch = NO;
  [_delegate setInfinitInLoginItems:self to:_auto_launch];
}

- (IBAction)toggleUploadScreenshots:(NSButton*)sender
{
  if (self.upload_screenshots.state == NSOnState)
    _auto_upload_screenshots = YES;
  else
    _auto_upload_screenshots = NO;
  [_delegate setUploadsScreenshots:self to:_auto_upload_screenshots];
}

- (IBAction)toggleStayAwake:(NSButton*)sender
{
  if (self.stay_awake.state == NSOnState)
    _auto_stay_awake = YES;
  else
    _auto_stay_awake = NO;
  [_delegate setStayAwake:self to:_auto_stay_awake];
}

//- Other Button Handling --------------------------------------------------------------------------

- (BOOL)panel:(id)sender
shouldEnableURL:(NSURL*)url
{
  return [[NSFileManager defaultManager] isWritableFileAtPath:url.path];
}

- (IBAction)changeDownloadDir:(NSButton*)sender
{
  NSOpenPanel* dir_selector = [NSOpenPanel openPanel];
  dir_selector.delegate = self;
  dir_selector.canChooseFiles = NO;
  dir_selector.canChooseDirectories = YES;
  dir_selector.allowsMultipleSelection = NO;
  [dir_selector beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result)
  {
    if (result == NSFileHandlingPanelOKButton)
    {
      NSString* download_dir = [dir_selector.URLs[0] path];
      _download_dir_str = download_dir;
      self.download_dir.stringValue = download_dir;
      [[InfinitDownloadDestinationManager sharedInstance] setDownloadDestination:download_dir];
    }
  }];
}

- (IBAction)checkForUpdates:(NSButton*)sender
{
  [_delegate checkForUpdate:self];
}

@end
