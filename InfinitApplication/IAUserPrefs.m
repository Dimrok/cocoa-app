// IAUserPrefs.m

#import "IAUserPrefs.h"

@implementation IAUserPrefs

+ (NSString*)appSupportPath
{
	static NSString* result = nil;
	if (result == nil)
	{
		NSArray* paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,
                                                             NSUserDomainMask,
                                                             YES);
		NSString* path = [paths.count == 1? paths.lastObject :
                                            nil stringByAppendingPathComponent:@"Infinit"];
		result = path;
	}
	BOOL is_dir = NO;
	if ([[NSFileManager defaultManager] fileExistsAtPath:result isDirectory:&is_dir] == YES)
		return is_dir == YES ? result : nil;
	if ([[NSFileManager defaultManager] createDirectoryAtPath:result
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:NULL] == YES)
    {
		return result;
    }
	return nil;
}

+ (IAUserPrefs*)sharedInstance
{
	static IAUserPrefs* userPrefs = nil;
	if (userPrefs == nil)
		userPrefs = [[IAUserPrefs alloc] init];
	return userPrefs;
}

- (id)init
{
	if (self = [super init])
	{
		NSString* path = [[IAUserPrefs appSupportPath]
                          stringByAppendingPathComponent:@"preferences.plist"];
		NSDictionary* values = [NSDictionary dictionaryWithContentsOfFile:path];
		_values = [NSMutableDictionary dictionaryWithDictionary:values];
	}
	return self;
}

- (id)getPrefForKey:(NSString*)key
{
	return _values[key];
}

- (void)setPref:(NSString*)prefs forKey:(NSString*)key
{
	_values[key]=prefs;
	[NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(synchronizeDelayed)
                                               object:nil];
	[self performSelector:@selector(synchronizeDelayed)
               withObject:nil
               afterDelay:0.25];
}

- (BOOL)synchronizeDelayed
{
	NSString* path = [[IAUserPrefs appSupportPath]
                      stringByAppendingPathComponent:@"preferences.plist"];
	return [_values writeToFile:path
                     atomically:YES];
}

@end
