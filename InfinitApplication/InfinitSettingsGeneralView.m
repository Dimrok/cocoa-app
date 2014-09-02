//
//  InfinitSettingsGeneralView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 25/08/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitSettingsGeneralView.h"

@interface InfinitSettingsGeneralView ()

@end

@implementation InfinitSettingsGeneralView
{
@private
  __unsafe_unretained id<InfinitSettingsGeneralProtocol> _delegate;

  BOOL _auto_launch;
  BOOL _auto_upload_screenshots;
  BOOL _auto_stay_awake;
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

- (void)loadView
{
  _auto_launch = [_delegate infinitInLoginItems:self];
  _auto_upload_screenshots = [_delegate uploadsScreenshots:self];
  _auto_stay_awake = [_delegate stayAwake:self];
  [super loadView];
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
}

//- General Functions ------------------------------------------------------------------------------

- (NSSize)startSize
{
  return NSMakeSize(480.0, 170.0);
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

- (IBAction)checkForUpdates:(NSButton*)sender
{
  [_delegate checkForUpdate:self];
}

@end
