//
//  IAFWAutoStartup.m
//  FinderWindow
//
//  Created by Christopher Crone on 3/22/13.
//  Copyright (c) 2013 infinit. All rights reserved.
//

#import <Gap/IAGapState.h>
#import "IAAutoStartup.h"

@implementation IAAutoStartup
{
@private
    NSString* _application_name;
    NSString* _application_path;
}

//- Initialisation ---------------------------------------------------------------------------------

+ (IAAutoStartup*)sharedInstance
{
	static IAAutoStartup* auto_start = nil;
	if (auto_start == nil)
		auto_start = [[IAAutoStartup alloc] init];
    return auto_start;
}

- (id)init
{
	if (self = [super init])
    {
        _application_name = @"Infinit";
        _application_path = [IAGapState.instance.protocol getApplicationPath];
    }
	return self;
}

//- General Functions ------------------------------------------------------------------------------

// Add Infinit to login item list
- (void)addAppAsLoginItem
{
	CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:_application_path];
    
	LSSharedFileListRef login_items = LSSharedFileListCreate(NULL,
                                                             kLSSharedFileListSessionLoginItems,
                                                             NULL);
	if (login_items)
    {
		LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(login_items,
                                                                     kLSSharedFileListItemLast,
                                                                     NULL,
                                                                     NULL,
                                                                     url,
                                                                     NULL,
                                                                     NULL);
		if (item)
			CFRelease(item);
        
    CFRelease(login_items);
	}
}

// Check if application is in login item list
- (BOOL)appInLoginItemList
{
    BOOL in_list = NO;
    CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:_application_path];
    
	LSSharedFileListRef login_items = LSSharedFileListCreate(NULL,
                                                             kLSSharedFileListSessionLoginItems,
                                                             NULL);
    
	if (login_items)
    {
		UInt32 seed_value;
		NSArray* login_items_array = (__bridge_transfer NSArray*)LSSharedFileListCopySnapshot(login_items,
                                                                                              &seed_value);
		for(int i = 0; i < login_items_array.count; i++)
        {
			LSSharedFileListItemRef item_ref = (__bridge LSSharedFileListItemRef)login_items_array[i];
			if (LSSharedFileListItemResolve(item_ref, 0, (CFURLRef*)&url, NULL) == noErr)
            {
				NSString* url_path = [(__bridge NSURL*)url path];
				if ([url_path.lastPathComponent hasPrefix:_application_name])
                {
                    in_list = YES;
                }
			}
		}
	}
    else
        return YES; // In case something has gone wrong, don't want application added to list
    return in_list;
}

// Remove Infinit from login item list
- (void)deleteAppFromLoginItem
{
    CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:_application_path];
    
	LSSharedFileListRef login_items = LSSharedFileListCreate(NULL,
                                                             kLSSharedFileListSessionLoginItems,
                                                             NULL);
    
	if (login_items)
    {
		UInt32 seed_value;
		NSArray* login_items_array = (__bridge_transfer NSArray*)LSSharedFileListCopySnapshot(login_items,
                                                                                              &seed_value);
		for(int i = 0; i < login_items_array.count; i++)
        {
			LSSharedFileListItemRef item_ref = (__bridge LSSharedFileListItemRef)login_items_array[i];
			if (LSSharedFileListItemResolve(item_ref, 0, (CFURLRef*)&url, NULL) == noErr)
            {
				NSString* url_path = [(__bridge NSURL*)url path];
				if ([url_path compare:_application_path] == NSOrderedSame)
                {
					LSSharedFileListItemRemove(login_items, item_ref);
				}
			}
		}
	}
}

@end
