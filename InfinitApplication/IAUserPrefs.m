// IAUserPrefs.m

#import "IAUserPrefs.h"

@interface IAUserPrefs ()

@property (nonatomic, readonly) NSString* dict_path;
@property (nonatomic, readonly) NSMutableDictionary* values;
@property (nonatomic, readonly) dispatch_queue_t queue;

@end

static NSString* _dict_path = nil;
static dispatch_once_t _dict_path_token = 0;
static IAUserPrefs* _instance = nil;
static dispatch_once_t _instance_token = 0;

@implementation IAUserPrefs

#pragma mark - Init

- (id)init
{
  NSCAssert(_instance == nil, @"Use sharedInstance.");
  if (self = [super init])
  {
    _queue = dispatch_queue_create("io.Infinit.UserPrefs", DISPATCH_QUEUE_SERIAL);
    _values = [NSMutableDictionary dictionaryWithContentsOfFile:self.dict_path];
    if (_values == nil)
      _values = [NSMutableDictionary dictionary];
  }
  return self;
}

+ (IAUserPrefs*)sharedInstance
{
  dispatch_once(&_instance_token, ^
  {
    _instance = [[IAUserPrefs alloc] init];
  });
	return _instance;
}

- (void)dealloc
{
  dispatch_sync(self.queue, ^{ /* Wait for writes */ });
}

- (id)prefsForKey:(NSString*)key
{
  __block id res = nil;
  dispatch_sync(self.queue, ^
  {
    res = self.values[key];
  });
  return res;
}

- (void)setPref:(id<NSCoding>)prefs
         forKey:(NSString*)key
{
  dispatch_async(self.queue, ^
  {
    [self.values setValue:prefs forKey:key];
    [self.values writeToFile:self.dict_path atomically:NO];
  });
}

- (void)setPrefNow:(id<NSCoding>)prefs
            forKey:(NSString*)key
{
  [self.values setValue:prefs forKey:key];
  [self.values writeToFile:self.dict_path atomically:NO];
}

#pragma mark - Helpers

- (NSString*)dict_path
{
  dispatch_once(&_dict_path_token, ^
  {
    NSString* app_support_path =
      NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,
                                          NSUserDomainMask,
                                          YES).lastObject;
    NSString* infinit_path = [app_support_path stringByAppendingPathComponent:@"Infinit"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:infinit_path])
    {
      [[NSFileManager defaultManager] createDirectoryAtPath:infinit_path
                                withIntermediateDirectories:YES
                                                 attributes:nil
                                                      error:nil];
    }
    _dict_path = [infinit_path stringByAppendingPathComponent:@"preferences.plist"];
  });
  return _dict_path;
}

@end
