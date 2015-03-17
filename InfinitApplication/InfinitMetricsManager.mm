//
//  InfinitMetricsManager.m
//  InfinitApplication
//
//  Created by Christopher Crone on 03/02/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitMetricsManager.h"

#import "InfinitFeatureManager.h"

#import <version.hh>

#undef check
#import <elle/log.hh>

#import <Gap/InfinitStateManager.h>
#import <Gap/InfinitUserManager.h>

ELLE_LOG_COMPONENT("OSX.MetricsManager");

static InfinitMetricsManager* _instance = nil;

@implementation InfinitMetricsManager
{
@private
  NSURL* _metrics_url;
  NSDictionary* _http_headers;
  BOOL _send_metrics;
}

#pragma mark - Init

- (id)init
{
  NSCAssert(_instance == nil, @"Use sharedInstance");
  if (self = [super init])
  {
  }
  return self;
}

- (void)dealloc
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

+ (instancetype)sharedInstance
{
  if (_instance == nil)
    _instance = [[InfinitMetricsManager alloc] init];
  return _instance;
}

#pragma mark - Public

+ (void)sendMetric:(InfinitMetricType)metric
{
  [[InfinitMetricsManager sharedInstance] _sendMetric:metric withDictioary:nil];
}

+ (void)sendMetric:(InfinitMetricType)metric
    withDictionary:(NSDictionary*)dict
{
  [[InfinitMetricsManager sharedInstance] _sendMetric:metric withDictioary:dict];
}

#pragma mark - Helpers

- (void)_sendMetric:(InfinitMetricType)metric
      withDictioary:(NSDictionary*)dict
{
  [[InfinitStateManager sharedInstance] sendMetricEvent:[self _eventName:metric]
                                             withMethod:[self _eventMethod:metric]
                                      andAdditionalData:dict];
}

- (NSString*)_eventName:(InfinitMetricType)metric_type
{
  switch (metric_type)
  {
    case INFINIT_METRIC_ADD_FILES:
      return @"add files";
    case INFINIT_METRIC_CONVERSATION_ACCEPT:
      return @"accept";
    case INFINIT_METRIC_CONVERSATION_CANCEL:
      return @"cancel";
    case INFINIT_METRIC_CONVERSATION_REJECT:
      return @"reject";
    case INFINIT_METRIC_CONVERSATION_SEND:
      return @"send";
    case INFINIT_METRIC_DESKTOP_NOTIFICATION:
      return @"desktop notification";
    case INFINIT_METRIC_DESKTOP_NOTIFICATION_ACCEPT:
      return @"accept";
    case INFINIT_METRIC_DROP_STATUS_BAR_ICON:
      return @"add files";
    case INFINIT_METRIC_HAVE_ADDRESSBOOK_ACCESS:
      return @"addressbook";
    case INFINIT_METRIC_MAIN_SEND:
      return @"send";
    case INFINIT_METRIC_MAIN_PEOPLE:
      return @"people";
    case INFINIT_METRIC_MAIN_LINKS:
      return @"links";
    case INFINIT_METRIC_MAIN_COPY_LINK:
      return @"copy link";
    case INFINIT_METRIC_MAIN_OPEN_LINK:
      return @"open link";
    case INFINIT_METRIC_MAIN_DELETE_LINK:
      return @"delete link";
    case INFINIT_METRIC_NO_ADRESSBOOK_ACCESS:
      return @"addressbook";
    case INFINIT_METRIC_OPEN_PANEL:
      return @"open infinit";
    case INFINIT_METRIC_SEND_TRASH:
      return @"cancel";
    case INFINIT_METRIC_SEND_CREATE_TRANSACTION:
      return @"create transaction";
    case INFINIT_METRIC_SEND_CREATE_LINK:
      return @"create link";
    case INFINIT_METRIC_SEND_INPUT:
      return @"search input";
    case INFINIT_METRIC_SEND_QUICK_SELECT:
      return @"quick select";
    case INFINIT_METRIC_UPLOAD_SCREENSHOT:
      return @"upload screenshot";
    case INFINIT_METRIC_SCREENSHOT_MODAL_NO:
      return @"upload screenshots";
    case INFINIT_METRIC_SCREENSHOT_MODAL_YES:
      return @"upload screenshots";
    case INFINIT_METRIC_FAVOURITES_LINK_DROP:
      return @"create link";
    case INFINIT_METRIC_FAVOURITES_PERSON_DROP:
      return @"create transaction";
    case INFINIT_METRIC_STATUS_ICON_LINK_DROP:
      return @"create link";
    case INFINIT_METRIC_CONTEXTUAL_SEND:
      return @"send";
    case INFINIT_METRIC_CONTEXTUAL_LINK:
      return @"create link";
    case INFINIT_METRIC_PREFERENCES:
      return @"open preferences";
    case INFINIT_METRIC_LOGIN_TO_REGISTER:
      return @"toggle register";
    case INFINIT_METRIC_REGISTER_TO_LOGIN:
      return @"toggle login";

    default:
      return @"unknown";
  }
}

- (NSString*)_eventMethod:(InfinitMetricType)metric_type
{
  switch (metric_type)
  {
    case INFINIT_METRIC_ADD_FILES:
      return @"send view";
    case INFINIT_METRIC_CONVERSATION_ACCEPT:
      return @"conversation view";
    case INFINIT_METRIC_CONVERSATION_CANCEL:
      return @"conversation view";
    case INFINIT_METRIC_CONVERSATION_REJECT:
      return @"conversation view";
    case INFINIT_METRIC_CONVERSATION_SEND:
      return @"conversation view";
    case INFINIT_METRIC_DESKTOP_NOTIFICATION:
      return @"click";
    case INFINIT_METRIC_DESKTOP_NOTIFICATION_ACCEPT:
      return @"desktop notification";
    case INFINIT_METRIC_DROP_STATUS_BAR_ICON:
      return @"status icon drop";
    case INFINIT_METRIC_HAVE_ADDRESSBOOK_ACCESS:
      return @"accessible";
    case INFINIT_METRIC_MAIN_SEND:
      return @"main view";
    case INFINIT_METRIC_MAIN_PEOPLE:
      return @"main view";
    case INFINIT_METRIC_MAIN_LINKS:
      return @"main view";
    case INFINIT_METRIC_MAIN_COPY_LINK:
      return @"main view";
    case INFINIT_METRIC_MAIN_OPEN_LINK:
      return @"main view";
    case INFINIT_METRIC_MAIN_DELETE_LINK:
      return @"main view";
    case INFINIT_METRIC_NO_ADRESSBOOK_ACCESS:
      return @"inaccessible";
    case INFINIT_METRIC_OPEN_PANEL:
      return @"status bar icon";
    case INFINIT_METRIC_SEND_TRASH:
      return @"send view";
    case INFINIT_METRIC_SEND_CREATE_TRANSACTION:
      return @"send view";
    case INFINIT_METRIC_SEND_CREATE_LINK:
      return @"send view";
    case INFINIT_METRIC_SEND_INPUT:
      return @"send view";
    case INFINIT_METRIC_SEND_QUICK_SELECT:
      return @"send view";
    case INFINIT_METRIC_UPLOAD_SCREENSHOT:
      return @"automatic";
    case INFINIT_METRIC_SCREENSHOT_MODAL_NO:
      return @"no";
    case INFINIT_METRIC_SCREENSHOT_MODAL_YES:
      return @"yes";
    case INFINIT_METRIC_FAVOURITES_LINK_DROP:
      return @"favourites";
    case INFINIT_METRIC_FAVOURITES_PERSON_DROP:
      return @"favourites";
    case INFINIT_METRIC_STATUS_ICON_LINK_DROP:
      return @"status icon drop";
    case INFINIT_METRIC_CONTEXTUAL_SEND:
      return @"contextual";
    case INFINIT_METRIC_CONTEXTUAL_LINK:
      return @"contextual";
    case INFINIT_METRIC_PREFERENCES:
      return @"click";
    case INFINIT_METRIC_LOGIN_TO_REGISTER:
      return @"login view";
    case INFINIT_METRIC_REGISTER_TO_LOGIN:
      return @"login view";

    default:
      return @"unknown";
  }
}

@end
