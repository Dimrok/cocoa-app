//
//  InfinitFacebookWidowController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 19/03/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitFacebookWindowController.h"

#import <WebKit/WebKit.h>

#import <Gap/InfinitStateManager.h>

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("OSX.FacebookWindowController");

@interface InfinitFacebookWindowController ()

@property (nonatomic, unsafe_unretained) id<InfinitFacebookWindowProtocol> delegate;
@property (nonatomic, weak) IBOutlet WebView* web_view;
@property (atomic, readwrite) BOOL window_floating;

@end

@implementation InfinitFacebookWindowController

#pragma mark - Init

- (instancetype)initWithDelegate:(id<InfinitFacebookWindowProtocol>)delegate
{
  if (self = [super initWithWindowNibName:NSStringFromClass(self.class) owner:self])
  {
    self.delegate = delegate;
  }
  return self;
}

- (void)dealloc
{
  [self.web_view close];
  self.delegate = nil;
}

- (void)windowDidLoad
{
  [super windowDidLoad];
  self.web_view.hostWindow = self.window;
}

#pragma mark - Show

- (void)showWindow:(id)sender
{
  ELLE_TRACE("%s: open window", self.description.UTF8String);
  self.window_floating = NO;
  self.window.hidesOnDeactivate = YES;
  self.window.level = NSNormalWindowLevel;
  [super showWindow:sender];
  [self.window orderOut:self];
  [self.window resignKeyWindow];
  [self.web_view.mainFrame loadRequest:[self _facebookRequest]];
}

#pragma mark - Delegate

- (void)webView:(WebView*)sender
       resource:(id)identifier
didReceiveResponse:(NSURLResponse*)response
 fromDataSource:(WebDataSource*)dataSource
{
  NSDictionary* query_dict = [self _queryDictionaryFromResponse:response];
  if (!query_dict.count && !self.window_floating)
  {
    ELLE_TRACE("%s: empty reply, show window", self.description.UTF8String);
    self.window_floating = YES;
    self.window.hidesOnDeactivate = NO;
    dispatch_async(dispatch_get_main_queue(), ^
    {
      self.window.level = NSFloatingWindowLevel;
      [self.window makeKeyAndOrderFront:self];
    });
  }
  if (query_dict[kInfinitFacebookErrorKey])
  {
    ELLE_WARN("%s: got Facebook error: %s",
              self.description.UTF8String, query_dict.description.UTF8String);
    [self.delegate facebookWindow:self gotError:query_dict[kInfinitFacebookErrorKey]];
    [self close];
  }
  else if (query_dict[kInfinitFacebookAccessKey])
  {
    ELLE_TRACE("%s: got Facebook token", self.description.UTF8String);
    [self.delegate facebookWindow:self gotToken:query_dict[kInfinitFacebookAccessKey]];
    [self close];
  }
  else
  {
    ELLE_WARN("%s: unknown reply: %s",
              self.description.UTF8String, query_dict.description.UTF8String);
  }
}

#pragma mark - Helpers

+ (NSString*)_redirectURI
{
  return @"https://www.facebook.com/connect/login_success.html";
}

- (NSURLRequest*)_facebookRequest
{
  NSURL* url =
    [NSURL URLWithString:[NSString stringWithFormat:
     @"https://www.facebook.com/dialog/oauth?"
     "client_id=%@"
     "&redirect_uri=%@"
     "&response_type=token"
     "&scope=email,public_profile,user_friends"
     "&display=popup",
     [InfinitStateManager sharedInstance].facebookApplicationId,
     [InfinitFacebookWindowController _redirectURI]]];
  NSURLRequest* res = [NSURLRequest requestWithURL:url
                                       cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                   timeoutInterval:0.0f];
  return res;
}

- (NSDictionary*)_queryDictionaryFromResponse:(NSURLResponse*)response
{
  NSString* url_str = response.URL.absoluteString;
  NSMutableDictionary* query_dict = [NSMutableDictionary dictionary];
  if ([url_str rangeOfString:[InfinitFacebookWindowController _redirectURI]].location == 0)
  {
    url_str = [url_str stringByReplacingOccurrencesOfString:@"#" withString:@"?"];
    NSInteger query_start = [url_str rangeOfString:@"?"].location;
    if (query_start != NSNotFound)
    {
      query_start += 1;
      url_str = [url_str substringFromIndex:query_start];
      NSArray* components = [url_str componentsSeparatedByString:@"&"];
      for (NSString* component in components)
      {
        NSArray* key_value = [component componentsSeparatedByString:@"="];
        if (key_value.count == 2)
          query_dict[key_value[0]] = key_value[1];
      }
    }
  }
  return query_dict;
}

@end
