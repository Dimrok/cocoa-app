//
//  InfinitNetworkManager.m
//  InfinitApplication
//
//  Created by Christopher Crone on 22/09/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitNetworkManager.h"

#import "IAUserPrefs.h"
#import "InfinitKeychain.h"

#import <Gap/InfinitConnectionManager.h>
#import <Gap/InfinitStateManager.h>

#import <SystemConfiguration/SystemConfiguration.h>

#undef check
#import <elle/log.hh>
#import <surface/gap/enums.hh>

ELLE_LOG_COMPONENT("OSX.NetworkManager");

@interface InfinitProxy : NSObject

@property (nonatomic, readwrite) NSString* host;
@property (nonatomic, readwrite) NSUInteger port;
@property (nonatomic, readwrite) NSString* username;
@property (nonatomic, readwrite) NSString* password;

@end

@implementation InfinitProxy

- (id)init
{
  if (self = [super init])
  {
    self.host = @"";
    self.port = 0;
    self.username = @"";
    self.password = @"";
  }
  return self;
}

- (NSString*)description
{
  NSMutableDictionary* res = [[NSMutableDictionary alloc] init];
  res[@"description"] = [NSString stringWithFormat:@"<InfinitProxy %p>", self];
  res[@"host:port"] = [NSString stringWithFormat:@"%@:%lu", self.host, self.port];
  if (self.username)
    res[@"username"] = self.username;
  return res.description;
}

@end

static InfinitNetworkManager* _instance = nil;

@implementation InfinitNetworkManager
{
  // Proxies
  InfinitProxy* _http_proxy;
  InfinitProxy* _https_proxy;
  InfinitProxy* _socks_proxy;

  // Modal Info
  NSString* _modal_host;
  NSNumber* _modal_port;
  NSString* _modal_username;
  NSString* _modal_password;

  BOOL _checking_for_proxy;
}

#pragma mark - Init

- (id)init
{
  NSCAssert(_instance == nil, @"Use sharedInstance");
  if (self = [super init])
  {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(connectionChanged:) 
                                                 name:INFINIT_CONNECTION_TYPE_CHANGE
                                               object:nil];
    _checking_for_proxy = NO;
    [self checkProxySettings];
  }
  return self;
}

+ (instancetype)sharedInstance
{
  if (_instance == nil)
    _instance = [[InfinitNetworkManager alloc] init];
  return _instance;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

//- Connection Changed Callback --------------------------------------------------------------------

- (void)connectionChanged:(NSNotification*)notification
{
  InfinitNetworkStatuses connection_type =
    (InfinitNetworkStatuses)[notification.userInfo[@"connection_type"] unsignedIntegerValue];
  if (connection_type == InfinitNetworkStatusNotReachable)
  {
    ELLE_TRACE("%s: lost internet connection", self.description.UTF8String);
  }
  else if (connection_type == InfinitNetworkStatusReachableViaLAN)
  {
    ELLE_TRACE("%s: got internet connection", self.description.UTF8String);
    [self checkProxySettings];
  }
}

- (NSString*)proxy:(NSString*)proxy_type withStr:(NSString*)str
{
  return [NSString stringWithFormat:@"%@%@", proxy_type, str];
}

- (void)checkProxySettings
{
  if (_checking_for_proxy)
    return;
  _checking_for_proxy = YES;
  _http_proxy = nil;
  _https_proxy = nil;
  _socks_proxy = nil;
  @autoreleasepool
  {
    CFDictionaryRef proxies = SCDynamicStoreCopyProxies(NULL);
    NSDictionary* proxy_configs = (__bridge NSDictionary*)proxies;
    NSArray* proxy_types = @[@"HTTP", @"HTTPS", @"SOCKS"];
    for (NSString* proxy_type in proxy_types)
    {
      InfinitProxy* proxy = [[InfinitProxy alloc] init];
      BOOL enabled = false;
      if ([proxy_configs valueForKey:[self proxy:proxy_type withStr:@"Enable"]])
      {
        enabled = [[proxy_configs valueForKey:[self proxy:proxy_type withStr:@"Enable"]] boolValue];
      }
      if (enabled)
      {
        proxy.host = [proxy_configs valueForKey:[self proxy:proxy_type withStr:@"Proxy"]];
        proxy.port =
          [[proxy_configs valueForKey:[self proxy:proxy_type withStr:@"Port"]] unsignedIntegerValue];
        if ([proxy_configs valueForKey:[self proxy:proxy_type withStr:@"User"]])
        {
          proxy.username = [proxy_configs valueForKey:[self proxy:proxy_type withStr:@"User"]];
          if (![[[IAUserPrefs sharedInstance] prefsForKey:@"asked_proxy_permission"] isEqualToString:@"1"])
          {
            NSAlert* permission_popup = [[NSAlert alloc] init];
            permission_popup.icon = [NSImage imageNamed:@"icon"];
            [permission_popup addButtonWithTitle:@"OK"];
            permission_popup.messageText = NSLocalizedString(@"Proxy Permission", nil);
            permission_popup.informativeText =
              NSLocalizedString(@"Please click \"Always Allow\" to ensure Infinit can automatically fetch your proxy settings.", nil);
            [permission_popup runModal];
            [[IAUserPrefs sharedInstance] setPref:@"1" forKey:@"asked_proxy_permission"];
          }

          NSString* password =
            [[InfinitKeychain sharedInstance] passwordForProxyAccount:proxy.username
                                                             protocol:proxy_type
                                                                 host:proxy.host
                                                                 port:proxy.port];
          if (password != nil)
          {
            proxy.password = password;
          }
          else
          {
            @autoreleasepool
            {
              _modal_host = nil;
              _modal_port = nil;
              _modal_username = nil;
              _modal_password = nil;
              InfinitProxyWindow* proxy_window = [[InfinitProxyWindow alloc] initWithDelegate:self];
              [proxy_window setProxy:proxy.host
                                port:[NSNumber numberWithUnsignedInteger:proxy.port]
                                type:proxy_type
                            username:proxy.username];
              [NSApp runModalForWindow:proxy_window.window];
            }
            if (_modal_host != nil)
            {
              proxy.host = _modal_host;
              proxy.port = _modal_port.unsignedIntegerValue;
              proxy.username = _modal_username;
              proxy.password = _modal_password;
            }
            else
            {
              proxy.host = @"";
            }
          }
        }
      }
      gap_ProxyType gap_proxy_type = gap_proxy_http;
      if ([proxy_type isEqualToString:@"HTTP"])
      {
        gap_proxy_type = gap_proxy_http;
        _http_proxy = proxy;
      }
      else if ([proxy_type isEqualToString:@"HTTPS"])
      {
        gap_proxy_type = gap_proxy_https;
        _https_proxy = proxy;
      }
      else if ([proxy_type isEqualToString:@"SOCKS"])
      {
        gap_proxy_type = gap_proxy_socks;
        _socks_proxy = proxy;
      }
      if (proxy.host.length > 0 && proxy.port > 0)
      {
        [[InfinitStateManager sharedInstance] setProxy:gap_proxy_type
                                                  host:proxy.host
                                                  port:proxy.port
                                              username:proxy.username
                                              password:proxy.password];
      }
      else
      {
        [[InfinitStateManager sharedInstance] unsetProxy:gap_proxy_type];
      }
    }
    CFRelease(proxies);
  }
  _checking_for_proxy = NO;
}

//- Proxy Modal Protocol ---------------------------------------------------------------------------

- (void)proxyWindow:(InfinitProxyWindow*)sender
            gotHost:(NSString*)host
               port:(NSNumber*)port
           username:(NSString*)username
           password:(NSString*)password
{
  _modal_host = [host copy];
  _modal_port = [port copy];
  _modal_username = [username copy];
  _modal_password = [password copy];
  [NSApp stopModal];
}

- (void)proxyWindowGotCancel:(InfinitProxyWindow*)sender
{
  _modal_host = nil;
  [NSApp stopModal];
}

@end
