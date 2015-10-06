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

#import "GetBSDProcessList.h"

#import <Gap/InfinitLinkTransactionManager.h>
#import <Gap/InfinitThreadSafeDictionary.h>

#undef check
#import <elle/log.hh>

#import <Carbon/Carbon.h>
#import <libproc.h>

ELLE_LOG_COMPONENT("OSX.ScreenshotManager");

static
OSStatus
_hot_key_handler(EventHandlerCallRef next_handler, EventRef event, void* user_data);

static
void NoteExitKQueueCallback(CFFileDescriptorRef f,
                            CFOptionFlags callBackTypes,
                            void* info);

typedef NS_ENUM(UInt32, InfinitHotKeyId)
{
  InfinitHotKeyAppleAreaGrab = 0,
  InfinitHotKeyAppleFullscreenGrab,
  InfinitHotKeyInfinitAreaGrab,
  InfinitHotKeyInfinitFullscreenGrab,
};

@interface MASShortcut (Dictionary)

@property (nonatomic, readonly) NSDictionary* dictionary;

+ (instancetype)shortcutWithDictionary:(NSDictionary*)dict;

@end

static NSString* kInfinitShortcutKey = @"shortcut_key";
static NSString* kInfinitShortcutModifiers = @"modifiers";

@implementation MASShortcut (Dictionary)

+ (instancetype)shortcutWithDictionary:(NSDictionary*)dict
{
  NSUInteger key_code = [dict[kInfinitShortcutKey] unsignedIntegerValue];
  NSUInteger modifiers = [dict[kInfinitShortcutModifiers] unsignedIntegerValue];
  if (key_code == 0)
    return nil;
  return [[MASShortcut alloc] initWithKeyCode:key_code modifierFlags:modifiers];
}

- (NSDictionary*)dictionary
{
  return @{kInfinitShortcutKey: @(self.keyCode),
           kInfinitShortcutModifiers: @(self.modifierFlags)};
}

@end

@interface InfinitScreenshotManager ()

@property (nonatomic) EventHotKeyRef apple_area_ref;
@property (nonatomic) EventHotKeyRef apple_fullscreen_ref;
@property (nonatomic) EventHotKeyRef infinit_area_ref;
@property (nonatomic) EventHotKeyRef infinit_fullscreen_ref;

@property (atomic, readonly) NSDate* last_capture_time;
@property (nonatomic, readonly) InfinitThreadSafeDictionary* link_map;
@property (nonatomic, readonly) BOOL first_screenshot;
@property (nonatomic, readonly) NSString* temporary_dir;
@property (atomic, readonly) NSTask* screencapture_task;
@property (nonatomic, readonly) NSString* screenshot_location;

@end

static InfinitScreenshotManager* _instance = nil;
static dispatch_once_t _instance_token = 0;
static NSDateFormatter* _date_formatter = nil;

static NSString* kInfinitAreaShortcutKey = @"area_screenshot_shortcut";
static NSString* kInfinitFullscreenShortcutKey = @"fullscreen_screenshot_shortcut";

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
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(linkUpdated:)
                                                 name:INFINIT_LINK_TRANSACTION_STATUS_NOTIFICATION
                                               object:nil];
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
  EventTypeSpec event_type = {kEventClassKeyboard, kEventHotKeyPressed};
  InstallApplicationEventHandler(&_hot_key_handler, 1, &event_type, NULL, NULL);
  if (![[IAUserPrefs prefsForKey:kInfinitAreaShortcutKey] isEqual:@NO])
  {
    _area_shortcut =
      [MASShortcut shortcutWithDictionary:[IAUserPrefs prefsForKey:kInfinitAreaShortcutKey]];
    if (!self.area_shortcut)
    {
      self.area_shortcut = [MASShortcut shortcutWithKeyCode:kVK_ANSI_4
                                              modifierFlags:(NSAlternateKeyMask + NSShiftKeyMask)];
    }
    else
    {
      [self registerEventRef:&self->_infinit_area_ref
                      withId:[self hotKeyIdFor:InfinitHotKeyInfinitAreaGrab]
                   forHotKey:self.area_shortcut.carbonKeyCode
               withModifiers:self.area_shortcut.carbonFlags];
    }
  }
  if (![[IAUserPrefs prefsForKey:kInfinitFullscreenShortcutKey] isEqual:@NO])
  {
    _fullscreen_shortcut =
      [MASShortcut shortcutWithDictionary:[IAUserPrefs prefsForKey:kInfinitFullscreenShortcutKey]];
    if (!self.fullscreen_shortcut)
    {
      self.fullscreen_shortcut =
        [MASShortcut shortcutWithKeyCode:kVK_ANSI_3
                           modifierFlags:(NSAlternateKeyMask + NSShiftKeyMask)];
    }
    else
    {
      [self registerEventRef:&self->_infinit_fullscreen_ref
                      withId:[self hotKeyIdFor:InfinitHotKeyInfinitFullscreenGrab]
                   forHotKey:self.fullscreen_shortcut.carbonKeyCode
               withModifiers:self.fullscreen_shortcut.carbonFlags];
    }
  }

  [self registerEventRef:&self->_apple_fullscreen_ref
                  withId:[self hotKeyIdFor:InfinitHotKeyAppleFullscreenGrab]
               forHotKey:kVK_ANSI_3
           withModifiers:cmdKey + shiftKey];
  [self registerEventRef:&self->_apple_area_ref
                  withId:[self hotKeyIdFor:InfinitHotKeyAppleAreaGrab]
               forHotKey:kVK_ANSI_4
           withModifiers:cmdKey + shiftKey];
}

- (EventHotKeyID)hotKeyIdFor:(InfinitHotKeyId)id_
{
  std::string signature_str = elle::sprint("inf%s", id_);
  OSType signature(*reinterpret_cast<const OSType*>(signature_str.data()));
  EventHotKeyID res = {signature, id_};
  return res;
}

- (void)registerEventRef:(EventHotKeyRef*)ref
                  withId:(EventHotKeyID)id_
               forHotKey:(UInt32)key
           withModifiers:(UInt32)modifiers
{
  RegisterEventHotKey(key, modifiers, id_, GetApplicationEventTarget(), 0, ref);
}

- (NSURL*)screenCaptureLocation
{
  NSURL* res = nil;
	NSString* location =
    [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.apple.screencapture"][@"location"];
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
    res = [NSURL fileURLWithPath:NSSearchPathForDirectoriesInDomains(NSDesktopDirectory,
                                                                     NSUserDomainMask,
                                                                     YES).firstObject];
  }
  return res;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  // Do not need to unregister hotkeys on exit. System does this for us.
}

#pragma mark - Watch

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
    ELLE_LOG("%s: start watching for screenshots", self.description.UTF8String);
  else
    ELLE_LOG("%s: stop watching for screenshots", self.description.UTF8String);
}

#pragma mark - Change Hotkey

- (void)setArea_shortcut:(MASShortcut*)area_shortcut
{
  if ([area_shortcut isEqual:self.area_shortcut])
    return;
  _area_shortcut = area_shortcut;
  UnregisterEventHotKey(self.infinit_area_ref);
  if (self.area_shortcut)
  {
    ELLE_LOG("%s: change area shortcut to: %s", self.description.UTF8String,
             self.area_shortcut.description.UTF8String)
    [IAUserPrefs setPref:self.area_shortcut.dictionary forKey:kInfinitAreaShortcutKey];
    [self registerEventRef:&self->_infinit_area_ref
                    withId:[self hotKeyIdFor:InfinitHotKeyInfinitAreaGrab]
                 forHotKey:self.area_shortcut.carbonKeyCode
             withModifiers:self.area_shortcut.carbonFlags];
  }
  else
  {
    ELLE_LOG("%s: remove area shortcut", self.description.UTF8String);
    [IAUserPrefs setPref:@NO forKey:kInfinitAreaShortcutKey];
  }
}

- (void)setFullscreen_shortcut:(MASShortcut*)fullscreen_shortcut
{
  if ([fullscreen_shortcut isEqual:self.fullscreen_shortcut])
    return;
  _fullscreen_shortcut = fullscreen_shortcut;
  UnregisterEventHotKey(self.infinit_fullscreen_ref);
  if (self.fullscreen_shortcut)
  {
    ELLE_LOG("%s: change fullscreen shortcut to: %s", self.description.UTF8String,
             self.fullscreen_shortcut.description.UTF8String)
    [IAUserPrefs setPref:self.fullscreen_shortcut.dictionary forKey:kInfinitFullscreenShortcutKey];
    [self registerEventRef:&self->_infinit_fullscreen_ref
                    withId:[self hotKeyIdFor:InfinitHotKeyInfinitFullscreenGrab]
                 forHotKey:self.fullscreen_shortcut.carbonKeyCode
             withModifiers:self.fullscreen_shortcut.carbonFlags];
  }
  else
  {
    ELLE_LOG("%s: remove fullscreen shortcut", self.description.UTF8String);
    [IAUserPrefs setPref:@NO forKey:kInfinitFullscreenShortcutKey];
  }
}

#pragma mark - Infinit Screen Shot Handling

- (void(^)(NSTask*))screenshotBlockForPath:(NSString*)output_path
{
  __weak InfinitScreenshotManager* weak_self = self;
  return ^(NSTask* task)
  {
    InfinitScreenshotManager* strong_self = weak_self;
    strong_self->_screencapture_task = nil;
    if (task.terminationReason != NSTaskTerminationReasonExit)
    {
      ELLE_ERR("%s: screen area capture failed", strong_self.description.UTF8String);
      return;
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:output_path isDirectory:NULL])
    {
      NSNumber* id_ =
        [[InfinitLinkTransactionManager sharedInstance] createScreenshotLink:output_path];
      [strong_self.link_map setObject:output_path forKey:id_];
    }
  };
}

- (void)launchScreenAreaGrab
{
  if (self.screencapture_task)
  {
    ELLE_WARN("%s: screencapture process already running", self.description.UTF8String);
    return;
  }
  @synchronized(self)
  {
    NSString* now_str = [_date_formatter stringFromDate:[NSDate date]];
    NSString* screenshot_name =
      [NSString stringWithFormat:NSLocalizedString(@"Screen Shot %@.png", nil), now_str];
    NSString* output_path = [self.temporary_dir stringByAppendingPathComponent:screenshot_name];
    _screencapture_task = [[NSTask alloc] init];
    self.screencapture_task.launchPath = @"/usr/sbin/screencapture";
    self.screencapture_task.arguments = @[@"-i", output_path];
    self.screencapture_task.terminationHandler = [self screenshotBlockForPath:output_path];
    [self.screencapture_task launch];
  }
}

- (void)launchFullScreenGrab
{
  if (self.screencapture_task)
  {
    ELLE_WARN("%s: screencapture process already running", self.description.UTF8String);
    return;
  }
  @synchronized(self)
  {
    NSString* now_str = [_date_formatter stringFromDate:[NSDate date]];
    NSString* screenshot_name =
      [NSString stringWithFormat:NSLocalizedString(@"Screen Shot %@.png", nil), now_str];
    NSString* output_path = [self.temporary_dir stringByAppendingPathComponent:screenshot_name];
    _screencapture_task = [[NSTask alloc] init];
    self.screencapture_task.launchPath = @"/usr/sbin/screencapture";
    NSMutableArray* args = [NSMutableArray array];
    if ([NSScreen screens].count > 1)
    {
      NSRect zero_frame = NSZeroRect;
      for (NSScreen* screen in [NSScreen screens])
      {
        if (NSEqualPoints(screen.frame.origin, NSZeroPoint))
        {
          zero_frame = screen.frame;
          break;
        }
      }
      NSRect frame = [NSScreen mainScreen].frame;
      if (NSEqualRects(zero_frame, frame))
      {
        [args addObject:@"-m"];
      }
      else
      {
        [args addObject:@"-R"];
        NSString* frame_str = [NSString stringWithFormat:@"'%ld,%ld,%ld,%ld'",
                               lround(frame.origin.x),
                               lround(-(frame.origin.y + frame.size.height - zero_frame.size.height)),
                               lround(frame.size.width),
                               lround(frame.size.height)];
        [args addObject:frame_str];
      }
    }
    [args addObject:output_path];
    self.screencapture_task.arguments = args;
    self.screencapture_task.terminationHandler = [self screenshotBlockForPath:output_path];
    [self.screencapture_task launch];
  }
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

#pragma mark - Apple Screen Shot Handling

- (pid_t)screencapturePID
{
  kinfo_proc* proc_list = nullptr;
  size_t proc_count = 0;
  GetBSDProcessList(&proc_list, &proc_count);
  pid_t res = 0;
  for (int i = 0; i < proc_count; i++)
  {
    kinfo_proc* proc = NULL;
    proc = &proc_list[i];
    if (proc == NULL)
      continue;
    char name_buf[PROC_SELFSET_THREADNAME_SIZE];
    proc_name(proc->kp_proc.p_pid, name_buf, sizeof(name_buf));
    if (!name_buf)
      continue;
    std::string proc_name(name_buf);
    if (proc_name == "screencapture")
    {
      res = proc->kp_proc.p_pid;
      break;
    }
  }
  free(proc_list);
  return res;
}

- (void)watchScreencaptureExit:(pid_t)pid
{
  CFFileDescriptorRef noteExitKQueueRef;
  int kq;
  struct kevent changes;
  CFFileDescriptorContext context = { 0, (__bridge void*)self, NULL, NULL, NULL };
  CFRunLoopSourceRef rls;

  // Create the kqueue and set it up to watch for SIGCHLD. Use the
  // new-in-10.5 EV_RECEIPT flag to ensure that we get what we expect.

  kq = kqueue();

  EV_SET(&changes, pid, EVFILT_PROC, EV_ADD | EV_RECEIPT, NOTE_EXIT, 0, NULL);
  (void) kevent(kq, &changes, 1, &changes, 1, NULL);

  // Wrap the kqueue in a CFFileDescriptor (new in Mac OS X 10.5!). Then
  // create a run-loop source from the CFFileDescriptor and add that to the
  // runloop.

  noteExitKQueueRef = CFFileDescriptorCreate(NULL, kq, true, NoteExitKQueueCallback, &context);
  rls = CFFileDescriptorCreateRunLoopSource(NULL, noteExitKQueueRef, 0);
  CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode);
  CFRelease(rls);

  CFFileDescriptorEnableCallBacks(noteExitKQueueRef, kCFFileDescriptorReadCallBack);

  // Execution continues in NoteExitKQueueCallback, below.
}

- (NSString*)screenshot_location
{
  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
  NSString* location =
    [[defaults persistentDomainForName:@"com.apple.screencapture"] objectForKey:@"location"];
  if (location.length)
  {
    location = [location stringByExpandingTildeInPath];
    if (![location hasSuffix:@"/"])
    {
      location = [location stringByAppendingString:@"/"];
    }
  }
  else
  {
    location =
      NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES).firstObject;
  }
  return location;
}

- (void)checkForScreenshot
{
  NSFileManager* manager = [NSFileManager defaultManager];
  NSArray* contents = [manager contentsOfDirectoryAtPath:self.screenshot_location error:nil];
  for (NSString* filename in contents)
  {
    NSString* path = [self.screenshot_location stringByAppendingPathComponent:filename];
    NSDictionary* attrs = [manager attributesOfItemAtPath:path error:nil];
    if (attrs[@"NSFileExtendedAttributes"])
    {
      if (attrs[@"NSFileExtendedAttributes"][@"com.apple.metadata:kMDItemIsScreenCapture"])
      {
        NSString* output_path = [self.temporary_dir stringByAppendingPathComponent:filename];
        ELLE_TRACE("%s: copy screenshot at path: %s -> %s",
                   self.description.UTF8String, path.UTF8String, output_path.UTF8String);
        NSError* error = nil;
        [[NSFileManager defaultManager] copyItemAtPath:path toPath:output_path error:&error];
        NSDate* c_date = attrs[NSFileCreationDate];
        if ([c_date compare:self.last_capture_time] == NSOrderedAscending ||
            [c_date compare:self.last_capture_time] == NSOrderedSame)
        {
          continue;
        }
        _last_capture_time = c_date;
        if (_first_screenshot)
        {
          _first_screenshot = NO;
          InfinitFirstScreenshotModal* screenshot_modal =
            [[InfinitFirstScreenshotModal alloc] init];
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
            [[NSFileManager defaultManager] removeItemAtPath:output_path error:nil];
            return;
          }
          else
          {
            [[NSFileManager defaultManager] removeItemAtPath:output_path error:nil];
            return;
          }
        }
        [InfinitMetricsManager sendMetric:INFINIT_METRIC_UPLOAD_SCREENSHOT];
        if (!error)
        {
          NSNumber* id_ =
            [[InfinitLinkTransactionManager sharedInstance] createScreenshotLink:output_path];
          [self.link_map setObject:output_path forKey:id_];
        }
        else
        {
          ELLE_ERR("%s: unable to copy screenshot: %s",
                   self.description.UTF8String, error.description);
        }
      }
    }
  }
}

@end

#pragma mark - Nasty C Functions

typedef void(^AppleScreenShotBlock)();
static
AppleScreenShotBlock
_apple_screen_shot_block()
{
  return ^
  {
    pid_t pid = [[InfinitScreenshotManager sharedInstance] screencapturePID];
    if (pid != 0)
      [[InfinitScreenshotManager sharedInstance] watchScreencaptureExit:pid];
  };
}

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
      ELLE_LOG("%s: Apple area screen shot hotkeys",
               [InfinitScreenshotManager sharedInstance].description.UTF8String);
      if (![InfinitScreenshotManager sharedInstance].watch)
        break;
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(100 * NSEC_PER_MSEC)),
                     dispatch_get_main_queue(), _apple_screen_shot_block());
      break;
    case InfinitHotKeyAppleFullscreenGrab:
      ELLE_LOG("%s: Apple fullscreen screen shot hotkeys",
               [InfinitScreenshotManager sharedInstance].description.UTF8String);
      if (![InfinitScreenshotManager sharedInstance].watch)
        break;
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(100 * NSEC_PER_MSEC)),
                     dispatch_get_main_queue(), _apple_screen_shot_block());
      break;
    case InfinitHotKeyInfinitAreaGrab:
      ELLE_LOG("%s: Infinit area screen shot hotkeys",
               [InfinitScreenshotManager sharedInstance].description.UTF8String);
      [[InfinitScreenshotManager sharedInstance] launchScreenAreaGrab];
      break;
    case InfinitHotKeyInfinitFullscreenGrab:
      ELLE_LOG("%s: Infinit fullscreen screen shot hotkeys",
               [InfinitScreenshotManager sharedInstance].description.UTF8String);
      [[InfinitScreenshotManager sharedInstance] launchFullScreenGrab];
      break;

    default:
      break;
  }
  return noErr;
}

static
void NoteExitKQueueCallback(CFFileDescriptorRef f, CFOptionFlags callBackTypes, void* info)
{
  struct kevent event;
  (void) kevent( CFFileDescriptorGetNativeDescriptor(f), NULL, 0, &event, 1, NULL);
  [[InfinitScreenshotManager sharedInstance] checkForScreenshot];
}
