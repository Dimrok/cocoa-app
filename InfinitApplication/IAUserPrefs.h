// IAUserPrefs.h

#import <Foundation/Foundation.h>

@interface IAUserPrefs : NSObject

+ (IAUserPrefs*)sharedInstance;

- (id)prefsForKey:(NSString*)key;
- (void)setPref:(id<NSCoding>)prefs
         forKey:(NSString*)key;
- (void)setPrefNow:(id<NSCoding>)prefs
            forKey:(NSString*)key;

@end
