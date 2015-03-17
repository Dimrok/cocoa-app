//
//  InfinitSettingsAccountView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 21/08/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitSettingsAccountView.h"

#import "InfinitKeychain.h"

#import <Gap/InfinitConnectionManager.h>
#import <Gap/InfinitStateManager.h>
#import <Gap/InfinitStateResult.h>
#import <Gap/InfinitUserManager.h>
#import <Gap/NSString+email.h>

#undef check
#import <elle/log.hh>

#define INFINIT_PROFILE_LINK @"https://infinit.io/account?utm_source=app&utm_medium=mac"

ELLE_LOG_COMPONENT("OSX.AccountSettings")

@interface InfinitSettingsAccountView ()

@property (atomic, readonly) BOOL online;

@end

@implementation InfinitSettingsAccountView
{
@private
  __unsafe_unretained id<InfinitSettingsAccountProtocol> _delegate;

  NSImage* _start_avatar_image;
  NSString* _start_name;
  NSString* _start_handle;
  NSString* _start_email;

  unsigned long long _avatar_size_limit;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithDelegate:(id<InfinitSettingsAccountProtocol>)delegate
{
  if (self = [super initWithNibName:self.className bundle:nil])
  {
    _delegate = delegate;
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(gotAvatar:)
                                               name:INFINIT_USER_AVATAR_NOTIFICATION
                                             object:nil];
    _avatar_size_limit = 2 * 1024 * 1024;
  }
  return self;
}

- (void)dealloc
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)gotAvatar:(NSNotification*)notification
{
  NSNumber* id_ = notification.userInfo[kInfinitUserId];
  InfinitUserManager* manager = [InfinitUserManager sharedInstance];
  InfinitUser* user = [manager userWithId:id_];
  if ([user isEqualTo:manager.me])
    self.avatar.image = user.avatar;
}

- (void)loadData
{
  InfinitUser* me = [InfinitUserManager sharedInstance].me;
  _start_avatar_image = me.avatar;

  _start_name = me.fullname;
  _start_handle = me.handle;

  self.avatar.delegate = self;
  self.avatar.image = _start_avatar_image;
  self.name.stringValue = _start_name;
  self.handle.stringValue = _start_handle;
  self.email.stringValue = [[InfinitStateManager sharedInstance] selfEmail];
  self.fullname_check.hidden = YES;
  self.handle_check.hidden = YES;
  self.avatar_error.hidden = YES;
  self.handle_error.hidden = YES;
}

- (void)loadView
{
  [super loadView];
  [self loadData];
}

- (void)awakeFromNib
{
  NSDictionary* attrs = [IAFunctions textStyleWithFont:[NSFont systemFontOfSize:13.0]
                                        paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                                colour:IA_RGB_COLOUR(0, 146, 207)
                                                shadow:nil];
  self.web_profile_link.normal_attrs = attrs;
  self.web_profile_link.hover_attrs = attrs;
  self.web_profile_link.hand_cursor = YES;
}

- (void)controlTextDidChange:(NSNotification*)notification
{
  if ([notification.object isKindOfClass:NSTextField.class])
  {
    NSTextField* field = (NSTextField*)notification.object;
    if (field == self.name)
    {
      self.fullname_check.hidden = YES;
      if (![self.name.stringValue isEqualToString:_start_name] &&
          self.name.stringValue.length > 2 &&
          self.name.stringValue.length < 51)
      {
        self.save_fullname.hidden = NO;
      }
      else
      {
        self.save_fullname.hidden = YES;
      }
    }
    else if (field == self.handle)
    {
      self.handle_check.hidden = YES;
      self.handle_error.hidden = YES;
      if (![self.handle.stringValue isEqualToString:_start_handle] &&
          self.name.stringValue.length > 2 &&
          self.name.stringValue.length < 31)
      {
        self.save_handle.hidden = NO;
      }
      else
      {
        self.save_handle.hidden = YES;
      }
    }
  }
}

//- General Functions ------------------------------------------------------------------------------

- (NSSize)startSize
{
  return NSMakeSize(480.0, 320.0);
}

//- Button Handling --------------------------------------------------------------------------------

- (IBAction)changeAvatar:(NSButton*)sender
{
  if (!self.online)
    return;
  NSOpenPanel* file_dialog = [NSOpenPanel openPanel];
  file_dialog.canChooseFiles = YES;
  file_dialog.canChooseDirectories = NO;
  file_dialog.allowsMultipleSelection = NO;
  file_dialog.allowedFileTypes = @[(NSString*)kUTTypeImage];
  [file_dialog beginSheetModalForWindow:[_delegate getWindow:self]
                      completionHandler:^(NSInteger result)
  {
    if (result == NSOKButton)
    {
      NSURL* file = [file_dialog URLs][0];

      NSDictionary* file_properties =
        [[NSFileManager defaultManager] attributesOfItemAtPath:file.path error:NULL];
      if (file_properties.fileSize <= _avatar_size_limit)
      {
        self.avatar_error.hidden = YES;
        self.avatar.image = [[NSImage alloc] initWithContentsOfURL:file];
        self.save_avatar.enabled = YES;
        self.save_avatar.hidden = NO;
      }
      else
      {
        self.avatar_error.stringValue =
          NSLocalizedString(@"Please choose an image smaller than 2 MB", nil);
        self.avatar_error.hidden = NO;
      }
    }
  }];
}

- (IBAction)saveAvatar:(NSButton*)sender
{
  if (!self.online)
    return;
  self.change_avatar.enabled = NO;
  self.change_avatar.hidden = YES;
  self.save_avatar.enabled = NO;
  self.save_avatar.hidden = YES;
  self.avatar.uploading = YES;
  self.avatar_progress.hidden = NO;
  [self.avatar_progress startAnimation:nil];
  [[InfinitStateManager sharedInstance] setSelfAvatar:self.avatar.image
                                      performSelector:@selector(changeAvatarCallback:)
                                             onObject:self];
}

- (void)changeAvatarCallback:(InfinitStateResult*)result
{
  self.change_avatar.enabled = YES;
  self.change_avatar.hidden = NO;
  self.avatar.uploading = NO;
  self.avatar_progress.hidden = YES;
  [self.avatar_progress stopAnimation:nil];
  if (result.success)
  {
    ELLE_LOG("%s: changed avatar", self.description.UTF8String);
  }
  else
  {
    ELLE_WARN("%s: unable to change avatar, error: %s", self.description.UTF8String, result.status);
  }
}

- (IBAction)saveFullname:(NSButton*)sender
{
  if (!self.online)
    return;
  self.save_fullname.enabled = NO;
  self.name.enabled = NO;
  self.save_fullname.hidden = YES;
  self.fullname_progress.hidden = NO;
  [self.fullname_progress startAnimation:nil];
  [[InfinitStateManager sharedInstance] setSelfFullname:self.name.stringValue
                                        performSelector:@selector(saveFullnameCallback:)
                                               onObject:self];
}

- (void)saveFullnameCallback:(InfinitStateResult*)result
{
  self.name.enabled = YES;
  [self.fullname_progress stopAnimation:nil];
  self.fullname_progress.hidden = YES;
  self.save_fullname.enabled = YES;

  if (result.success)
  {
    ELLE_LOG("%s: changed name from %s to %s",
             self.description.UTF8String,
             _start_name.UTF8String,
             self.name.stringValue.UTF8String);
    _start_name = self.name.stringValue;
    self.fullname_check.image = [IAFunctions imageNamed:@"settings-icon-check"];
    self.fullname_check.hidden = NO;
  }
  else
  {
    ELLE_WARN("%s: unable to change fullname with status: %s",
              self.description.UTF8String, result.status);
    self.name.stringValue = _start_name;
    self.fullname_check.image = [IAFunctions imageNamed:@"icon-error"];
    self.fullname_check.hidden = NO;
    switch (result.status)
    {
      default:
        break;
    }
  }
}

- (IBAction)saveHandle:(NSButton*)sender
{
  if (!self.online)
    return;
  self.save_handle.enabled = NO;
  self.handle.enabled = NO;
  self.save_handle.hidden = YES;
  self.handle_progress.hidden = NO;
  [self.handle_progress startAnimation:nil];
  [[InfinitStateManager sharedInstance] setSelfHandle:self.handle.stringValue
                                      performSelector:@selector(saveHandleCallback:)
                                             onObject:self];
}

- (void)saveHandleCallback:(InfinitStateResult*)result
{
  self.handle.enabled = YES;
  [self.handle_progress stopAnimation:nil];
  self.handle_progress.hidden = YES;
  self.save_handle.enabled = YES;

  if (result.success)
  {
    ELLE_LOG("%s: changed handle from %s to %s",
             self.description.UTF8String,
             _start_handle.UTF8String,
             self.handle.stringValue.UTF8String);
    _start_handle = self.handle.stringValue;
    self.handle_check.image = [IAFunctions imageNamed:@"settings-icon-check"];
    self.handle_check.hidden = NO;
  }
  else
  {
    ELLE_WARN("%s: unable to change handle with status: %s",
              self.description.UTF8String, result.status);
    self.handle_check.image = [IAFunctions imageNamed:@"icon-error"];
    self.handle_check.hidden = NO;
    switch (result.status)
    {
      case gap_handle_already_registered:
        self.handle_error.stringValue = NSLocalizedString(@"Handle already taken...", nil);
        self.handle_error.hidden = NO;
        break;
      default:
        break;
    }
  }
}

- (IBAction)changeEmail:(NSButton*)sender
{
  if (!self.online)
    return;
  self.change_email_error.hidden = YES;
  self.change_email_field.stringValue = @"";
  self.change_email_password.stringValue = @"";
  [NSApp beginSheet:self.change_email_panel
     modalForWindow:[_delegate getWindow:self]
      modalDelegate:self
     didEndSelector:nil
        contextInfo:nil];
}

- (IBAction)changePassword:(NSButton*)sender
{
  if (!self.online)
    return;
  self.password_error.hidden = YES;
  self.change_password_field.stringValue = @"";
  self.old_password_field.stringValue = @"";
  [NSApp beginSheet:self.change_password_panel
     modalForWindow:[_delegate getWindow:self]
      modalDelegate:self
     didEndSelector:nil
        contextInfo:nil];
}

- (IBAction)webProfile:(NSButton*)sender
{
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:INFINIT_PROFILE_LINK]];
}

//- Change Email Panel -----------------------------------------------------------------------------

- (IBAction)confirmChangeEmail:(NSButton*)sender
{
  if (!self.online)
    return;
  if (self.change_email_field.stringValue.isEmail)
  {
    if (self.change_email_password.stringValue.length > 2)
    {
      self.change_email_error.hidden = YES;
      self.confirm_change_email.enabled = NO;
      [self.change_email_progress startAnimation:nil];
      self.change_email_progress.hidden = NO;
      self.change_email_field.enabled = NO;
      self.change_email_password.enabled = NO;
      [[InfinitStateManager sharedInstance] setSelfEmail:self.change_email_field.stringValue
                                                password:self.change_email_password.stringValue
                                         performSelector:@selector(changeEmailCallback:)
                                                onObject:self];
    }
    else
    {
      self.change_email_error.stringValue = NSLocalizedString(@"Please enter your password", nil);
      self.change_email_error.hidden = NO;
    }
  }
  else
  {
    self.change_email_error.stringValue =
      NSLocalizedString(@"Enter a valid email address", nil);
    self.change_email_error.hidden = NO;
  }
}

- (void)changeEmailCallback:(InfinitStateResult*)result
{
  self.confirm_change_email.enabled = YES;
  [self.change_email_progress stopAnimation:nil];
  self.change_email_progress.hidden = YES;
  self.change_email_field.enabled = YES;
  self.change_email_password.enabled = YES;
  if (result.success)
  {
    ELLE_LOG("%s: changed email address", self.description.UTF8String);
    self.change_email_error.hidden = YES;
    [NSApp endSheet:self.change_email_panel];
    [self.change_email_panel orderOut:nil];
    [NSApp beginSheet:self.changed_email_panel
       modalForWindow:[_delegate getWindow:self]
        modalDelegate:self
       didEndSelector:nil
          contextInfo:nil];
    self.change_email_field.stringValue = @"";
    self.change_email_password.stringValue = @"";
  }
  else
  {
    switch (result.status)
    {
      case gap_email_already_registered:
        self.change_email_error.stringValue =
        NSLocalizedString(@"This email is already taken", nil);
        break;

      case gap_email_password_dont_match:
        self.change_email_error.stringValue = NSLocalizedString(@"Password incorrect", nil);
        break;

      default:
        self.change_email_error.stringValue = NSLocalizedString(@"Unknown error", nil);
        break;
    }
    self.change_email_error.hidden = NO;
  }
}

- (IBAction)cancelChangeEmail:(NSButton*)sender
{
  [NSApp endSheet:self.change_email_panel];
  [self.change_email_panel orderOut:sender];
}

- (IBAction)changedEmailConfirm:(NSButton*)sender
{
  [NSApp endSheet:self.changed_email_panel];
  [self.changed_email_panel orderOut:sender];
}

//- Change Password Panel --------------------------------------------------------------------------

- (IBAction)cancelChangePassword:(NSButton*)sender
{
  [NSApp endSheet:self.change_password_panel];
  [self.change_password_panel orderOut:sender];
}

- (IBAction)confirmChangePassword:(NSButton*)sender
{
  if (!self.online)
    return;
  if (self.change_password_field.stringValue.length > 2)
  {
    self.password_error.hidden = YES;
    [self.change_password_progress startAnimation:nil];
    self.change_password_progress.hidden = NO;
    self.confirm_change_password.enabled = NO;
    [[InfinitStateManager sharedInstance] changeFromPassword:self.old_password_field.stringValue
                                                  toPassword:self.change_password_field.stringValue
                                             performSelector:@selector(changePasswordCallback:)
                                                    onObject:self];
  }
  else
  {
    self.password_error.stringValue = NSLocalizedString(@"Enter a longer password", nil);
    self.password_error.hidden = NO;
  }
}

- (void)changePasswordCallback:(InfinitStateResult*)result
{
  self.password_error.hidden = YES;
  [self.change_password_progress stopAnimation:nil];
  self.change_password_progress.hidden = YES;
  self.confirm_change_password.enabled = YES;
  if (result.success)
  {
    ELLE_LOG("%s: changed password", self.description.UTF8String);
    [_delegate closeSettingsWindow:self];
    self.password_error.hidden = YES;
    [[InfinitKeychain sharedInstance] updatePassword:self.change_password_field.stringValue
                                          forAccount:_start_email];
    [NSApp endSheet:self.change_password_panel];
    [self.change_password_panel orderOut:nil];
    self.old_password_field.stringValue = @"";
    self.change_password_field.stringValue = @"";
  }
  else
  {
    ELLE_WARN("%s: unable to change password, got status: %s",
              self.description.UTF8String, result.status);
    switch (result.status)
    {
      case gap_email_password_dont_match:
        self.password_error.stringValue = NSLocalizedString(@"Incorrect password", nil);
        break;

      default:
        self.password_error.stringValue = NSLocalizedString(@"Unknown error", nil);
        break;
    }
    self.change_email_error.hidden = NO;
  }
}

//- Settings Avatar Protocol -----------------------------------------------------------------------

- (void)settingsAvatarGotImage:(NSImage*)image
                        ofSize:(unsigned long long)size
{
  if (size <= _avatar_size_limit)
  {
    self.save_avatar.enabled = YES;
    self.save_avatar.hidden = NO;
    self.avatar_error.hidden = YES;
  }
  else
  {
    self.avatar_error.stringValue =
      NSLocalizedString(@"Please choose an image smaller than 2 MB", nil);
    self.avatar_error.hidden = NO;
  }
}

- (unsigned long long)maxAvatarSize
{
  return _avatar_size_limit;
}

#pragma mark - Helpers

- (BOOL)online
{
  return [InfinitConnectionManager sharedInstance].connected;
}

@end
