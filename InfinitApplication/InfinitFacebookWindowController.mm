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

@end

@implementation InfinitFacebookWindowController

#pragma mark - Init

- (instancetype)initWithDelegate:(id<InfinitFacebookWindowProtocol>)delegate
{
  if (self = [super initWithWindowNibName:NSStringFromClass(self.class) owner:self])
  {
    _delegate = delegate;
  }
  return self;
}

- (void)windowDidLoad
{
  [super windowDidLoad];
  self.web_view.hostWindow = self.window;
}

#pragma mark - Show

- (void)showWindow:(id)sender
{
  [super showWindow:sender];
  [self.web_view.mainFrame loadRequest:[self _facebookRequest]];
}

#pragma mark - Delegate

- (void)webView:(WebView*)sender
       resource:(id)identifier
didReceiveResponse:(NSURLResponse*)response
 fromDataSource:(WebDataSource*)dataSource
{
  NSDictionary* query_dict = [self _queryDictionaryFromResponse:response];
  if (query_dict[kInfinitFacebookErrorKey])
  {
    [_delegate facebookWindow:self gotError:query_dict[kInfinitFacebookErrorKey]];
    [self close];
  }
  else if (query_dict[kInfinitFacebookAccessKey])
  {
    [_delegate facebookWindow:self gotToken:query_dict[kInfinitFacebookAccessKey]];
    [self close];
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
