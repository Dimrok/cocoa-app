// IAUserPrefs.h

#import <Foundation/Foundation.h>

@interface IAUserPrefs : NSObject
{
	NSMutableDictionary* _values;
}

+ (IAUserPrefs*)sharedInstance;

- (id)prefsForKey:(NSString*)key;
- (void)setPref:(NSString*)prefs
         forKey:(NSString*)key;
- (void)setPrefNow:(NSString*)prefs
            forKey:(NSString*)key;

@end
