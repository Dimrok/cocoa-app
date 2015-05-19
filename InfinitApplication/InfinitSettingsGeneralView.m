//
//  InfinitSettingsGeneralView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 25/08/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitSettingsGeneralView.h"

#import "InfinitDownloadDestinationManager.h"
#import "InfinitScreenshotManager.h"

#import <Gap/InfinitDeviceManager.h>

@interface InfinitSettingsGeneralView () <NSOpenSavePanelDelegate,
                                          NSTextFieldDelegate>

@property (nonatomic, weak) IBOutlet NSTextField* device_name_field;
@property (nonatomic, weak) IBOutlet NSButton* launch_at_startup;
@property (nonatomic, weak) IBOutlet NSButton* stay_awake;
@property (nonatomic, weak) IBOutlet NSButton* upload_screenshots;
@property (nonatomic, weak) IBOutlet NSTextField* download_dir;

@property (nonatomic, readonly) BOOL auto_launch;
@property (nonatomic, readonly) BOOL auto_upload_screenshots;
@property (nonatomic, readonly) BOOL auto_stay_awake;
@property (nonatomic, unsafe_unretained) id<InfinitSettingsGeneralProtocol> delegate;
@property (nonatomic, readonly) NSString* download_dir_str;

@end

@implementation InfinitSettingsGeneralView

#pragma mark - InfinitSettingsViewController

- (NSSize)startSize
{
  return NSMakeSize(480.0, 280.0);
}

#pragma mark - Init

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
  _auto_launch = [self.delegate infinitInLoginItems:self];
  _auto_upload_screenshots = [InfinitScreenshotManager sharedInstance].watch;
  _auto_stay_awake = [self.delegate stayAwake:self];
  _download_dir_str = [InfinitDownloadDestinationManager sharedInstance].download_destination;
  if (self.auto_launch)
    self.launch_at_startup.state = NSOnState;
  else
    self.launch_at_startup.state = NSOffState;

  if (self.auto_upload_screenshots)
    self.upload_screenshots.state = NSOnState;
  else
    self.upload_screenshots.state = NSOffState;

  if (self.auto_stay_awake)
    self.stay_awake.state = NSOnState;
  else
    self.stay_awake.state = NSOffState;

  self.download_dir.stringValue = _download_dir_str;
  [[InfinitDeviceManager sharedInstance] updateDevices];
  self.device_name_field.stringValue = [InfinitDeviceManager sharedInstance].this_device.name;
}

- (void)loadView
{
  [super loadView];
  [self loadData];
}

#pragma mark - Toggle Handling

- (IBAction)toggleLaunchAtStartup:(NSButton*)sender
{
  if (self.launch_at_startup.state == NSOnState)
    _auto_launch = YES;
  else
    _auto_launch = NO;
  [_delegate setInfinitInLoginItems:self to:self.auto_launch];
}

- (IBAction)toggleUploadScreenshots:(NSButton*)sender
{
  if (self.upload_screenshots.state == NSOnState)
    _auto_upload_screenshots = YES;
  else
    _auto_upload_screenshots = NO;
  [InfinitScreenshotManager sharedInstance].watch = self.auto_upload_screenshots;
}

- (IBAction)toggleStayAwake:(NSButton*)sender
{
  if (self.stay_awake.state == NSOnState)
    _auto_stay_awake = YES;
  else
    _auto_stay_awake = NO;
  [_delegate setStayAwake:self to:self.auto_stay_awake];
}

#pragma mark - Button Handling

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
  [self.delegate checkForUpdate:self];
}

#pragma mark - NSTextFieldDelegate

- (BOOL)control:(NSControl*)control
textShouldEndEditing:(NSText*)fieldEditor
{
  NSString* new_name = self.device_name_field.stringValue;
  if (new_name.length &&
      ![[InfinitDeviceManager sharedInstance].this_device.name isEqualToString:new_name])
  {
    [[InfinitDeviceManager sharedInstance] setThisDeviceName:new_name];
  }
  return YES;
}

@end
