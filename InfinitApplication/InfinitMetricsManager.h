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
  INFINIT_METRIC_OPEN_PANEL,
  INFINIT_METRIC_DROP_STATUS_BAR_ICON,
  INFINIT_METRIC_ADD_FILES,
  INFINIT_METRIC_MAIN_SEND,
  INFINIT_METRIC_MAIN_PEOPLE,
  INFINIT_METRIC_MAIN_LINKS,
  INFINIT_METRIC_MAIN_COPY_LINK,
  INFINIT_METRIC_MAIN_OPEN_LINK,
  INFINIT_METRIC_MAIN_DELETE_LINK,
  INFINIT_METRIC_CONVERSATION_ACCEPT,
  INFINIT_METRIC_CONVERSATION_REJECT,
  INFINIT_METRIC_CONVERSATION_CANCEL,
  INFINIT_METRIC_CONVERSATION_SEND,
  INFINIT_METRIC_DESKTOP_NOTIFICATION,
  INFINIT_METRIC_SEND_TRASH,
  INFINIT_METRIC_HAVE_ADDRESSBOOK_ACCESS,
  INFINIT_METRIC_NO_ADRESSBOOK_ACCESS,
  INFINIT_METRIC_UPLOAD_SCREENSHOT,
  INFINIT_METRIC_FAVOURITES_LINK_DROP,
  INFINIT_METRIC_STATUS_ICON_LINK_DROP,
  INFINIT_METRIC_CONTEXTUAL_SEND,
  INFINIT_METRIC_CONTEXTUAL_LINK,
}
InfinitMetricType;

@interface InfinitMetricsManager : NSObject <NSURLConnectionDelegate>

+ (void)sendMetric:(InfinitMetricType)metric;

@end
