//
//  InfinitScreenshotManager.m
//  InfinitApplication
//
//  Created by Christopher Crone on 25/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitScreenshotManager.h"

#import "IAUserPrefs.h"

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("OSX.ScreenshotManager");

@implementation InfinitScreenshotManager
{
@private
  id<InfinitScreenshotManagerProtocol> _delegate;
  NSMetadataQuery* _query;

  BOOL _watch;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithDelegate:(id<InfinitScreenshotManagerProtocol>)delegate
{
  if (self = [super init])
  {
    _query = [[NSMetadataQuery alloc] init];
    _delegate = delegate;
    if ([[[IAUserPrefs sharedInstance] prefsForKey:@"upload_screenshots"] isEqualToString:@"1"])
      _watch = YES;
    else
      _watch = NO;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(gotScreenShot:)
                                                 name:NSMetadataQueryDidUpdateNotification
                                               object:_query];
    _query.delegate = self;
    _query.predicate = [NSPredicate predicateWithFormat:@"kMDItemIsScreenCapture = 1"];

    if (_watch)
      [_query startQuery];
  }
  return self;
}

- (void)dealloc
{
  _query.delegate = nil;
  [_query stopQuery];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

//- Watching ----------------------------------------------------------------------------

- (void)setWatch:(BOOL)watch
{
  _watch = watch;
  if (_watch)
  {
    [_query startQuery];
    [[IAUserPrefs sharedInstance] setPref:@"1" forKey:@"upload_screenshots"];
    ELLE_LOG("%s: start watching for screenshots", self.description.UTF8String);
  }
  else
  {
    [_query stopQuery];
    [[IAUserPrefs sharedInstance] setPref:@"0" forKey:@"upload_screenshots"];
    ELLE_LOG("%s: stop watching for screenshots", self.description.UTF8String);
  }

}

//- Screenshot Handling ----------------------------------------------------------------------------

- (void)gotScreenShot:(NSNotification*)notification
{
  NSMetadataItem* data_item = [notification.userInfo[@"kMDQueryUpdateAddedItems"] lastObject];
  if (data_item == nil)
    return;
  NSString* screenshot_path = [data_item valueForAttribute:NSMetadataItemPathKey];
  if (screenshot_path.length == 0)
    return;
  ELLE_LOG("%s: got screenshot with path: %s",
           self.description.UTF8String, screenshot_path.UTF8String);
  [_delegate screenshotManager:self gotScreenshot:screenshot_path];
}

@end
