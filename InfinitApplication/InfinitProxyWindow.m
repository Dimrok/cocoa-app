//
//  InfinitProxyWindow.m
//  InfinitApplication
//
//  Created by Christopher Crone on 25/09/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitProxyWindow.h"

@interface InfinitProxyWindow ()

@end

@implementation InfinitProxyWindow
{
  __weak id<InfinitProxyWindowProtocol> _delegate;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithDelegate:(id<InfinitProxyWindowProtocol>)delegate
{
  if (self = [super initWithWindowNibName:self.className])
  {
    _delegate = delegate;
    self.window.level = NSFloatingWindowLevel;
  }
  return self;
}

- (void)windowDidLoad
{
  [super windowDidLoad];
}

//- Close ------------------------------------------------------------------------------------------

- (void)close
{
  if (self.window == nil)
    return;

  [self.window close];
}

//- General Functions ------------------------------------------------------------------------------

- (void)setProxy:(NSString*)host
            port:(NSNumber*)port
            type:(NSString*)type
        username:(NSString*)username
{
  self.host.stringValue = host;
  self.port.stringValue = port.stringValue;
  self.type.title = [NSString stringWithFormat:@"%@ Proxy", type];
  if (username != nil && username.length > 0)
  {
    self.requires_password.state = NSOnState;
    [self setPasswordRequired:YES];
    self.username.stringValue = username;
  }
  else
  {
    self.requires_password = NSOffState;
    self.username.stringValue = @"";
  }
}

//- Button Handling --------------------------------------------------------------------------------

- (void)setPasswordRequired:(BOOL)flag
{
  self.username.enabled = flag;
  self.username_text.enabled = flag;
  self.password.enabled = flag;
  self.password_text.enabled = flag;
}

- (IBAction)requiresPasswordToggle:(id)sender
{
  if (self.requires_password.state == NSOnState)
    [self setPasswordRequired:YES];
  else
    [self setPasswordRequired:NO];
}

- (BOOL)inputsValid
{
  if (self.username.stringValue.length == 0 || self.port.stringValue.length == 0)
    return NO;
  if (self.requires_password.state == NSOnState)
  {
    if (self.username.stringValue.length == 0 || self.password.stringValue.length == 0)
      return NO;
  }
  NSNumber* port = [self.port.formatter numberFromString:self.port.stringValue];
  if ([port isEqualToNumber:@0])
    return NO;

  return YES;
}

- (IBAction)okCliked:(id)sender
{
  if ([self inputsValid])
  {
    NSNumber* port = [self.port.formatter numberFromString:self.port.stringValue];
    [_delegate proxyWindow:self
                   gotHost:self.host.stringValue
                      port:port
                  username:self.username.stringValue
                  password:self.password.stringValue];
    [self close];
  }
}

- (IBAction)cancelClicked:(id)sender
{
  [self close];
  [_delegate proxyWindowGotCancel:self];
}

@end
