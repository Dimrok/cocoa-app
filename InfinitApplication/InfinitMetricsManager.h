//
//  InfinitMetricsManager.h
//  InfinitApplication
//
//  Created by Christopher Crone on 03/02/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum __InfinitMetricType
{
    INFINIT_METRIC_OPEN_PANEL = 0,
    INFINIT_METRIC_DROP_STATUS_BAR_ICON,
    INFINIT_METRIC_ADD_FILES,
    INFINIT_METRIC_MAIN_ACCEPT,
    INFINIT_METRIC_MAIN_REJECT,
    INFINIT_METRIC_MAIN_SEND,
    INFINIT_METRIC_CONVERSATION_ACCEPT,
    INFINIT_METRIC_CONVERSATION_REJECT,
    INFINIT_METRIC_CONVERSATION_CANCEL,
    INFINIT_METRIC_CONVERSATION_SEND,
    INFINIT_METRIC_CONVERSATION_NOTE,
    INFINIT_METRIC_DESKTOP_NOTIFICATION,
    INFINIT_METRIC_SEND_TRASH,
    INFINIT_METRIC_HAVE_ADDRESSBOOK_ACCESS,
    INFINIT_METRIC_NO_ADRESSBOOK_ACCESS,
}
InfinitMetricType;

@interface InfinitMetricsManager : NSObject <NSURLConnectionDelegate>

+ (void)sendMetric:(InfinitMetricType)metric;

@end
