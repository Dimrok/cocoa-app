//
//  InfinitSettingsAccountView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 21/08/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitSettingsAccountView.h"

#import <Gap/IAGapState.h>
#import "IAAvatarManager.h"
#import "IAKeychainManager.h"

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("OSX.AccountSettings")

@interface InfinitSettingsAccountView ()

@end

@implementation InfinitSettingsAccountView
{
@private
  __unsafe_unretained id<InfinitSettingsAccountProtocol> _delegate;
  __weak IAGapState* _instance;

  NSImage* _start_avatar_image;
  NSString* _start_name;
  NSString* _start_handle;
  NSString* _start_email;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithDelegate:(id<InfinitSettingsAccountProtocol>)delegate
{
  if (self = [super initWithNibName:self.className bundle:nil])
  {
    _delegate = delegate;
    _instance = [IAGapState instance];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(gotAvatar:)
                                               name:IA_AVATAR_MANAGER_AVATAR_FETCHED
                                             object:nil];
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
  IAUser* user = notification.userInfo[@"user"];
  if ([user isEqualTo:_instance.self_user])
    self.avatar.image = [IAAvatarManager getAvatarForUser:_instance.self_user];
}

- (void)loadView
{
  _start_avatar_image = [IAAvatarManager getAvatarForUser:[_instance self_user]];
  if (_start_avatar_image == nil)
    _start_avatar_image = [IAFunctions makeAvatarFor:[_instance selfFullname]];

  _start_name = [_instance selfFullname];
  _start_handle = [_instance selfHandle];
  [super loadView];

  self.avatar.delegate = self;
  self.avatar.image = _start_avatar_image;
  self.name.stringValue = _start_name;
  self.handle.stringValue = _start_handle;
  self.email.stringValue = [_instance selfEmail];
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
  return NSMakeSize(480.0, 280.0);
}

//- Button Handling --------------------------------------------------------------------------------

- (IBAction)changeAvatar:(NSButton*)sender
{
  if (!_instance.logged_in)
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
      self.avatar.image = [[NSImage alloc] initWithContentsOfURL:file];
      self.save_avatar.enabled = YES;
      self.save_avatar.hidden = NO;
    }
  }];
}

- (IBAction)saveAvatar:(NSButton*)sender
{
  if (!_instance.logged_in)
    return;
  self.change_avatar.enabled = NO;
  self.change_avatar.hidden = YES;
  self.save_avatar.enabled = NO;
  self.save_avatar.hidden = YES;
  self.avatar.uploading = YES;
  self.avatar_progress.hidden = NO;
  [self.avatar_progress startAnimation:nil];
  [_instance setAvatar:self.avatar.image
       performSelector:@selector(changeAvatarCallback:)
              onObject:self];
}

- (void)changeAvatarCallback:(IAGapOperationResult*)result
{
  self.change_avatar.enabled = YES;
  self.change_avatar.hidden = NO;
  self.avatar.uploading = NO;
  self.avatar_progress.hidden = YES;
  [self.avatar_progress stopAnimation:nil];
  if (result.success)
  {
    ELLE_LOG("%s: changed avatar", self.description.UTF8String);
    [IAAvatarManager reloadAvatarForUser:_instance.self_user];
  }
  else
  {
    ELLE_WARN("%s: unable to change avatar, error: %s", self.description.UTF8String, result.status);
  }
}

- (IBAction)saveFullname:(NSButton*)sender
{
  if (!_instance.logged_in)
    return;
  self.save_fullname.enabled = NO;
  self.name.enabled = NO;
  self.save_fullname.hidden = YES;
  self.fullname_progress.hidden = NO;
  [self.fullname_progress startAnimation:nil];
  [_instance setSelfFullname:self.name.stringValue
             performSelector:@selector(saveFullnameCallback:)
                    onObject:self];
}

- (void)saveFullnameCallback:(IAGapOperationResult*)result
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
  if (!_instance.logged_in)
    return;
  self.save_handle.enabled = NO;
  self.handle.enabled = NO;
  self.save_handle.hidden = YES;
  self.handle_progress.hidden = NO;
  [self.handle_progress startAnimation:nil];
  [_instance setSelfHandle:self.handle.stringValue
           performSelector:@selector(saveHandleCallback:)
                  onObject:self];
}

- (void)saveHandleCallback:(IAGapOperationResult*)result
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
      case gap_handle_already_registred:
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
  if (!_instance.logged_in)
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
  if (!_instance.logged_in)
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

//- Change Email Panel -----------------------------------------------------------------------------

- (IBAction)confirmChangeEmail:(NSButton*)sender
{
  if (!_instance.logged_in)
    return;
  if ([IAFunctions stringIsValidEmail:self.change_email_field.stringValue])
  {
    if (self.change_email_password.stringValue.length > 2)
    {
      self.change_email_error.hidden = YES;
      self.confirm_change_email.enabled = NO;
      [self.change_email_progress startAnimation:nil];
      self.change_email_progress.hidden = NO;
      self.change_email_field.enabled = NO;
      self.change_email_password.enabled = NO;
      [_instance setSelfEmail:self.change_email_field.stringValue
                 withPassword:self.change_email_password.stringValue
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

- (void)changeEmailCallback:(IAGapOperationResult*)result
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
      case gap_email_already_registred:
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
  if (!_instance.logged_in)
    return;
  if (self.change_password_field.stringValue.length > 2)
  {
    self.password_error.hidden = YES;
    [self.change_password_progress startAnimation:nil];
    self.change_password_progress.hidden = NO;
    self.confirm_change_password.enabled = NO;
    [_instance changePassword:self.old_password_field.stringValue
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

- (void)changePasswordCallback:(IAGapOperationResult*)result
{
  self.password_error.hidden = YES;
  [self.change_password_progress stopAnimation:nil];
  self.change_password_progress.hidden = YES;
  self.confirm_change_password.enabled = YES;
  if (result.success)
  {
    ELLE_LOG("%s: changed password", self.description.UTF8String);
    self.password_error.hidden = YES;
    [[IAKeychainManager sharedInstance] changeUser:_start_email
                                          password:self.change_password_field.stringValue];
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
{
  self.save_avatar.enabled = YES;
  self.save_avatar.hidden = NO;
}

@end
