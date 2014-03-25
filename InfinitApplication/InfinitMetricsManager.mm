//
//  InfinitMetricsManager.m
//  InfinitApplication
//
//  Created by Christopher Crone on 03/02/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitMetricsManager.h"

#import <Gap/version.h>

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("OSX.MetricsManager");

static InfinitMetricsManager* _shared_instance = nil;

@implementation InfinitMetricsManager
{
@private
    NSURL* _metrics_url;
    NSDictionary* _http_headers;
    BOOL _send_metrics;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)init
{
    if (self = [super init])
    {
        @try
        {
            NSString* metrics_host = [[NSString alloc] initWithUTF8String:getenv("INFINIT_METRICS_HOST")];
            NSString* metrics_port = [[NSString alloc] initWithUTF8String:getenv("INFINIT_METRICS_PORT")];
            if (metrics_host.length > 0 && metrics_port.length > 0)
            {
                _send_metrics = YES;
                NSString* metrics_url =
                [[NSString alloc] initWithFormat:@"http://%@:%@/ui", metrics_host, metrics_port];
                _metrics_url = [[NSURL alloc] initWithString:metrics_url];
                NSString* user_agent = [[NSString alloc] initWithFormat:@"Infinit/%s (OS X)", INFINIT_VERSION];
                _http_headers = @{@"User-Agent": user_agent,
                                  @"Content-Type": @"application/json"};
            }
            else
            {
                _send_metrics = NO;
            }
        }
        @catch (NSException *exception)
        {
            _send_metrics = NO;
        }
    }
    return self;
}

- (void)dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

//- Instance Management ----------------------------------------------------------------------------

+ (InfinitMetricsManager*)sharedInstance
{
    if (_shared_instance == nil)
    {
        _shared_instance = [[InfinitMetricsManager alloc] init];
    }
    return _shared_instance;
}

//- General Functions ------------------------------------------------------------------------------

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
        case INFINIT_METRIC_CONVERSATION_NOTE:
            return @"note";
        case INFINIT_METRIC_CONVERSATION_REJECT:
            return @"reject";
        case INFINIT_METRIC_CONVERSATION_SEND:
            return @"send";
        case INFINIT_METRIC_DESKTOP_NOTIFICATION:
            return @"desktop notification";
        case INFINIT_METRIC_DROP_STATUS_BAR_ICON:
            return @"add files";
        case INFINIT_METRIC_HAVE_ADDRESSBOOK_ACCESS:
            return @"addressbook";
        case INFINIT_METRIC_MAIN_ACCEPT:
            return @"accept";
        case INFINIT_METRIC_MAIN_REJECT:
            return @"reject";
        case INFINIT_METRIC_MAIN_SEND:
            return @"send";
        case INFINIT_METRIC_NO_ADRESSBOOK_ACCESS:
            return @"addressbook";
        case INFINIT_METRIC_OPEN_PANEL:
            return @"open infinit";
        case INFINIT_METRIC_SEND_TRASH:
            return @"cancel";

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
        case INFINIT_METRIC_CONVERSATION_NOTE:
            return @"conversation view";
        case INFINIT_METRIC_CONVERSATION_REJECT:
            return @"conversation view";
        case INFINIT_METRIC_CONVERSATION_SEND:
            return @"conversation view";
        case INFINIT_METRIC_DESKTOP_NOTIFICATION:
            return @"click";
        case INFINIT_METRIC_DROP_STATUS_BAR_ICON:
            return @"status icon drop";
        case INFINIT_METRIC_HAVE_ADDRESSBOOK_ACCESS:
            return @"accessible";
        case INFINIT_METRIC_MAIN_ACCEPT:
            return @"main view";
        case INFINIT_METRIC_MAIN_REJECT:
            return @"main view";
        case INFINIT_METRIC_MAIN_SEND:
            return @"main view";
        case INFINIT_METRIC_NO_ADRESSBOOK_ACCESS:
            return @"inaccessible";
        case INFINIT_METRIC_OPEN_PANEL:
            return @"status bar icon";
        case INFINIT_METRIC_SEND_TRASH:
            return @"send view";
            
        default:
            return @"unknown";
    }
}

- (NSString*)_userId
{
    if (![[IAGapState instance] logged_in])
      return nil;
    return [IAGapState instance].self_user.real_id;
}

//- Send Metric ------------------------------------------------------------------------------------

- (void)_sendMetric:(InfinitMetricType)metric
{
    if (!_send_metrics)
        return;
    
    ELLE_DEBUG("%s: send metric of type: %d", self.description.UTF8String, metric);

    NSDate* now = [NSDate date];
    NSNumber* timestamp = [NSNumber numberWithDouble:now.timeIntervalSince1970];
    NSMutableDictionary* metric_dict =
    [NSMutableDictionary dictionaryWithDictionary:@{@"event": [self _eventName:metric],
                                                    @"method": [self _eventMethod:metric],
                                                    @"timestamp": timestamp}];
    if ([self _userId] != nil)
        [metric_dict setObject:[self _userId] forKey:@"user"];
    else
        [metric_dict setObject:@"unknown" forKey:@"user"];
    NSData* json_data = [NSJSONSerialization dataWithJSONObject:metric_dict options:0 error:nil];
    NSMutableURLRequest* request =
        [[NSMutableURLRequest alloc] initWithURL:_metrics_url
                                     cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                 timeoutInterval:10.0];
    request.HTTPMethod = @"POST";
    request.HTTPBody = json_data;
    request.HTTPShouldUsePipelining = YES;
    [request setAllHTTPHeaderFields:_http_headers];
    NSURLConnection* connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [connection start];
}

+ (void)sendMetric:(InfinitMetricType)metric
{
    [[InfinitMetricsManager sharedInstance] _sendMetric:metric];
}

//- NSURLConnectionDelegate ------------------------------------------------------------------------

- (void)connection:(NSURLConnection*)connection
  didFailWithError:(NSError*)error
{
    ELLE_WARN("%s: unable to sent metric: %s", self.description.UTF8String,
              error.description.UTF8String);
    // Do nothing
}

- (void)connection:(NSURLConnection*)connection
didReceiveResponse:(NSURLResponse*)response
{
    // Do nothing
}

@end
