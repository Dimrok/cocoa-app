//
//  InfinitSettingsScreenshotView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 23/05/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitSettingsScreenshotView.h"

#import "IAUserPrefs.h"
#import "InfinitScreenshotManager.h"

#import "MASShortcutView.h"
#import "MASShortcutValidator.h"

typedef void(^InfinitSettingsShortcutChanged)(MASShortcutView* sender);

@interface InfinitSettingsScreenshotView ()

@property (nonatomic, weak) IBOutlet NSButton* upload_screenshots_button;
@property (nonatomic, weak) IBOutlet MASShortcutView* desktop_keys;
@property (nonatomic, weak) IBOutlet MASShortcutView* area_keys;

@property (nonatomic, readonly) MASShortcut* area_shortcut;
@property (nonatomic, readonly) MASShortcut* desktop_shortcut;
@property (nonatomic, readonly) InfinitSettingsShortcutChanged shortcut_changed_block;
@property (nonatomic, readwrite) BOOL upload_screenshots;

@end

@implementation InfinitSettingsScreenshotView

- (NSSize)startSize
{
  return NSMakeSize(480.0, 280.0);
}

- (void)loadData
{
  self.upload_screenshots = [InfinitScreenshotManager sharedInstance].watch;
  _desktop_shortcut = [InfinitScreenshotManager sharedInstance].fullscreen_shortcut;
  self.desktop_keys.style = MASShortcutViewStyleRounded;
  self.desktop_keys.shortcutValue = self.desktop_shortcut;
  self.desktop_keys.shortcutValidator.allowAnyShortcutWithOptionModifier = YES;
  self.desktop_keys.shortcutValueChange = self.shortcut_changed_block;
  _area_shortcut = [InfinitScreenshotManager sharedInstance].area_shortcut;
  self.area_keys.style = MASShortcutViewStyleRounded;
  self.area_keys.shortcutValue = self.area_shortcut;
  self.area_keys.shortcutValidator.allowAnyShortcutWithOptionModifier = YES;
  self.area_keys.shortcutValueChange = self.shortcut_changed_block;
}

- (void)setUpload_screenshots:(BOOL)upload_screenshots
{
  @synchronized(self)
  {
    _upload_screenshots = upload_screenshots;
    if (self.upload_screenshots)
      self.upload_screenshots_button.state = NSOnState;
    else
      self.upload_screenshots_button.state = NSOffState;
    [InfinitScreenshotManager sharedInstance].watch = self.upload_screenshots;
  }
}

#pragma mark - Button Handling

- (IBAction)uploadClicked:(id)sender
{
  self.upload_screenshots = !self.upload_screenshots;
}

#pragma mark - Helpers

- (InfinitSettingsShortcutChanged)shortcut_changed_block
{
  __unsafe_unretained InfinitSettingsScreenshotView* weak_self = self;
  return ^void(MASShortcutView* sender)
  {
    if (!weak_self)
      return;
    InfinitSettingsScreenshotView* strong_self = weak_self;
    if (sender == strong_self.desktop_keys)
    {
      if ([sender.shortcutValue isEqual:strong_self.desktop_shortcut])
        return;
      if ([strong_self shortcutValid:sender.shortcutValue])
        [InfinitScreenshotManager sharedInstance].fullscreen_shortcut = sender.shortcutValue;
      else
        sender.shortcutValue = strong_self.desktop_shortcut;
      strong_self->_desktop_shortcut = sender.shortcutValue;
    }
    else if (sender == strong_self.area_keys)
    {
      if ([sender.shortcutValue isEqual:strong_self.area_shortcut])
        return;
      if ([strong_self shortcutValid:sender.shortcutValue])
        [InfinitScreenshotManager sharedInstance].area_shortcut = sender.shortcutValue;
      else
        sender.shortcutValue = strong_self.area_shortcut;
      strong_self->_area_shortcut = sender.shortcutValue;
    }
  };
}

- (BOOL)shortcutValid:(MASShortcut*)shortcut
{
  if ([shortcut isEqual:self.area_shortcut] || [shortcut isEqual:self.desktop_shortcut])
  {
    return NO;
  }
  return YES;
}

@end
