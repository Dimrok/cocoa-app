//
//  InfinitScreenshotManager.m
//  InfinitApplication
//
//  Created by Christopher Crone on 25/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitScreenshotManager.h"

#import "IAUserPrefs.h"
#import "InfinitFirstScreenshotModal.h"
#import "InfinitMetricsManager.h"

#import <Gap/InfinitLinkTransactionManager.h>
#import <Gap/InfinitThreadSafeDictionary.h>

#undef check
#import <elle/log.hh>

#import <Carbon/Carbon.h>

ELLE_LOG_COMPONENT("OSX.ScreenshotManager");

static
OSStatus
_hot_key_handler(EventHandlerCallRef next_handler, EventRef event, void* user_data);

typedef NS_ENUM(UInt32, InfinitHotKeyId)
{
  InfinitHotKeyAppleAreaGrab = 0,
  InfinitHotKeyAppleFullscreenGrab,
  InfinitHotKeyInfinitAreaGrab,
};

@interface InfinitScreenshotManager ()

@property (nonatomic, unsafe_unretained) EventHotKeyRef apple_area_ref;
@property (nonatomic, unsafe_unretained) EventHotKeyRef apple_fullscreen_ref;
@property (nonatomic, unsafe_unretained) EventHotKeyRef infinit_area_ref;

@property (nonatomic, readonly) NSDate* last_capture_time;
@property (nonatomic, readonly) InfinitThreadSafeDictionary* link_map;
@property (nonatomic, readonly) BOOL first_screenshot;
@property (nonatomic, readonly) NSString* temporary_dir;
@property (nonatomic, readonly) NSMetadataQuery* query;
@property (nonatomic, readonly) NSTask* screencapture_task;

@end

static InfinitScreenshotManager* _instance = nil;
static dispatch_once_t _instance_token = 0;
static NSDateFormatter* _date_formatter = nil;

@implementation InfinitScreenshotManager

#pragma mark - Init

+ (instancetype)sharedInstance
{
  dispatch_once(&_instance_token, ^
  {
    _instance = [[InfinitScreenshotManager alloc] init];
  });
  return _instance;
}

- (id)init
{
  if (self = [super init])
  {
    [[NSFileManager defaultManager] removeItemAtPath:self.temporary_dir error:nil];
    _link_map = [InfinitThreadSafeDictionary initWithName:@"ScreenShotLinkMap"];
    _query = [[NSMetadataQuery alloc] init];
    if ([[[IAUserPrefs sharedInstance] prefsForKey:@"upload_screenshots"] isEqualToString:@"0"])
    {
      ELLE_LOG("%s: not watching for screenshots", self.description.UTF8String);
      _watch = NO;
      _first_screenshot = NO;
    }
    else
    {
      ELLE_LOG("%s: watching for screenshots", self.description.UTF8String);
      _watch = YES;
      if ([[[IAUserPrefs sharedInstance] prefsForKey:@"upload_screenshots"] isEqualToString:@"1"])
        _first_screenshot = NO;
      else
        _first_screenshot = YES;
    }

    _last_capture_time = [NSDate date];

    self.query.delegate = self;
    self.query.predicate = [NSPredicate predicateWithFormat:@"kMDItemIsScreenCapture = 1"];
    self.query.notificationBatchingInterval = 0.1;
    self.query.searchScopes = @[[self screenCaptureLocation]];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(gotScreenShot:)
                                                 name:NSMetadataQueryDidUpdateNotification
                                               object:self.query];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(linkUpdated:)
                                                 name:INFINIT_LINK_TRANSACTION_STATUS_NOTIFICATION
                                               object:nil];
    if (self.watch)
      [self.query startQuery];
    [self registerHotKeys];
    if (_date_formatter == nil)
    {
      _date_formatter = [[NSDateFormatter alloc] init];
      _date_formatter.dateFormat = @"YYYY-MM-dd 'at' HH.mm.ss";
    }
  }
  return self;
}

- (void)registerHotKeys
{
  EventHotKeyID apple_fullscreen_grab_id = [self hotKeyIdFor:InfinitHotKeyAppleFullscreenGrab];
  EventHotKeyID apple_area_grab_id = [self hotKeyIdFor:InfinitHotKeyAppleAreaGrab];
  EventHotKeyID infinit_area_grab_id = [self hotKeyIdFor:InfinitHotKeyInfinitAreaGrab];
  EventTypeSpec event_type = {kEventClassKeyboard, kEventHotKeyPressed};
  InstallApplicationEventHandler(&_hot_key_handler, 1, &event_type, NULL, NULL);
  [self registerEventRef:self.apple_fullscreen_ref withId:apple_fullscreen_grab_id forHotKey:kVK_ANSI_3];
  [self registerEventRef:self.apple_area_ref withId:apple_area_grab_id forHotKey:kVK_ANSI_4];
  [self registerEventRef:self.infinit_area_ref withId:infinit_area_grab_id forHotKey:kVK_ANSI_5];
}

- (EventHotKeyID)hotKeyIdFor:(InfinitHotKeyId)id_
{
  std::string signature_str = elle::sprint("inf%s", id_);
  OSType signature(*reinterpret_cast<const OSType*>(signature_str.data()));
  EventHotKeyID res = {signature, id_};
  return res;
}

- (void)registerEventRef:(EventHotKeyRef)ref
                  withId:(EventHotKeyID)id_
               forHotKey:(UInt32)key
{
  RegisterEventHotKey(key, cmdKey + shiftKey, id_, GetApplicationEventTarget(), 0, &ref);
}

- (NSURL*)screenCaptureLocation
{
  NSURL* res = nil;
	NSString* location =
    [[[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.apple.screencapture"] objectForKey:@"location"];
	if (location.length)
  {
		location = [location stringByExpandingTildeInPath];
		if (![location hasSuffix:@"/"])
    {
			location = [location stringByAppendingString:@"/"];
		}
    res = [NSURL fileURLWithPath:location];
	}
  else
  {
    res = [NSURL fileURLWithPath:NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES).firstObject];
  }
  return res;
}

- (void)dealloc
{
  self.query.delegate = nil;
  [self.query stopQuery];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  if (self.apple_area_ref)
    UnregisterEventHotKey(self.apple_area_ref);
  if (self.apple_fullscreen_ref)
    UnregisterEventHotKey(self.apple_fullscreen_ref);
  if (self.infinit_area_ref)
    UnregisterEventHotKey(self.infinit_area_ref);
}

//- Watching ---------------------------------------------------------------------------------------

- (void)setWatch:(BOOL)watch
{
  if (self.watch == watch)
    return;

  _last_capture_time = [NSDate date];
  _watch = watch;
  _first_screenshot = NO;
  NSString* value = [NSString stringWithFormat:@"%d", self.watch];
  [[IAUserPrefs sharedInstance] setPref:value forKey:@"upload_screenshots"];
  if (self.watch)
  {
    [self.query startQuery];
    ELLE_LOG("%s: start watching for screenshots", self.description.UTF8String);
  }
  else
  {
    [self.query stopQuery];
    ELLE_LOG("%s: stop watching for screenshots", self.description.UTF8String);
  }

}

//- Screenshot Handling ----------------------------------------------------------------------------

- (void)gotScreenShot:(NSNotification*)notification
{
  NSMetadataItem* data_item = [notification.userInfo[@"kMDQueryUpdateAddedItems"] lastObject];

  if (data_item == nil)
    return;

  NSDate* new_date = [data_item valueForAttribute:NSMetadataItemFSCreationDateKey];
  
  if ([new_date compare:_last_capture_time] == NSOrderedAscending)
    return;

  NSString* screenshot_path = [data_item valueForAttribute:NSMetadataItemPathKey];
  if (screenshot_path.length == 0)
    return;

  _last_capture_time = [NSDate date];

  if (_first_screenshot)
  {
    _first_screenshot = NO;
    InfinitFirstScreenshotModal* screenshot_modal = [[InfinitFirstScreenshotModal alloc] init];
    NSInteger res = [NSApp runModalForWindow:screenshot_modal.window];
    if (res == INFINIT_UPLOAD_SCREENSHOTS)
    {
      [InfinitMetricsManager sendMetric:INFINIT_METRIC_SCREENSHOT_MODAL_YES];
      [[IAUserPrefs sharedInstance] setPref:@"1" forKey:@"upload_screenshots"];
    }
    else if (res == INFINIT_NO_UPLOAD_SCREENSHOTS)
    {
      [InfinitMetricsManager sendMetric:INFINIT_METRIC_SCREENSHOT_MODAL_NO];
      [self setWatch:NO];
      return;
    }
    else
    {
      return;
    }
  }

  [InfinitMetricsManager sendMetric:INFINIT_METRIC_UPLOAD_SCREENSHOT];
  ELLE_LOG("%s: got screenshot with path: %s",
           self.description.UTF8String, screenshot_path.UTF8String);
  [[InfinitLinkTransactionManager sharedInstance] createScreenshotLink:screenshot_path];
}

- (void)launchScreenAreaGrab
{
  if (self.screencapture_task)
    return;
  NSString* now_str = [_date_formatter stringFromDate:[NSDate date]];
  NSString* screenshot_name =
    [NSString stringWithFormat:NSLocalizedString(@"Screen Shot %@.png", nil), now_str];
  NSString* output_path = [self.temporary_dir stringByAppendingPathComponent:screenshot_name];
  _screencapture_task = [[NSTask alloc] init];
  self.screencapture_task.launchPath = @"/usr/sbin/screencapture";
  self.screencapture_task.arguments = @[@"-i", output_path];
  __weak InfinitScreenshotManager* weak_self = self;
  self.screencapture_task.terminationHandler = ^(NSTask* task)
  {
    InfinitScreenshotManager* strong_self = weak_self;
    if (task.terminationReason != NSTaskTerminationReasonExit)
    {
      ELLE_ERR("%s: screen capture failed", strong_self.description.UTF8String);
      return;
    }
    NSNumber* id_ =
      [[InfinitLinkTransactionManager sharedInstance] createScreenshotLink:output_path];
    [strong_self.link_map setObject:output_path forKey:id_];
    strong_self->_screencapture_task = nil;
  };
  [self.screencapture_task launch];
}

- (void)linkUpdated:(NSNotification*)notification
{
  NSNumber* id_ = notification.userInfo[kInfinitTransactionId];
  InfinitLinkTransaction* link =
    [[InfinitLinkTransactionManager sharedInstance] transactionWithId:id_];
  if (link.done)
  {
    [[NSFileManager defaultManager] removeItemAtPath:self.link_map[id_] error:nil];
    [self.link_map removeObjectForKey:id_];
  }
}

- (NSString*)temporary_dir
{
  NSString* res = [NSTemporaryDirectory() stringByAppendingPathComponent:@"io.infinit.Infinit"];
  res = [res stringByAppendingPathComponent:@"Screen Shots"];
  if (![[NSFileManager defaultManager] fileExistsAtPath:res isDirectory:NULL])
  {
    [[NSFileManager defaultManager] createDirectoryAtPath:res
                              withIntermediateDirectories:YES
                                               attributes:nil 
                                                    error:nil];
  }
  return res;
}

@end

static
OSStatus
_hot_key_handler(EventHandlerCallRef next_handler, EventRef event, void* user_data)
{
  EventHotKeyID hot_key_ref;
  GetEventParameter(event,
                    kEventParamDirectObject,
                    typeEventHotKeyID,
                    NULL,
                    sizeof(hot_key_ref),
                    NULL,
                    &hot_key_ref);
  switch (hot_key_ref.id)
  {
    case InfinitHotKeyAppleAreaGrab:
      break;
    case InfinitHotKeyAppleFullscreenGrab:
      break;
    case InfinitHotKeyInfinitAreaGrab:
      [[InfinitScreenshotManager sharedInstance] launchScreenAreaGrab];
      break;

    default:
      break;
  }
  return noErr;
}
