//
//  IAFWAutoStartup.h
//  FinderWindow
//
//  Created by Christopher Crone on 3/22/13.
//  Copyright (c) 2013 infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IAAutoStartup : NSObject
{
    
}

+ (IAAutoStartup*)sharedInstance;

- (void)addAppAsLoginItem;

- (BOOL)appInLoginItemList;

- (void)deleteAppFromLoginItem;

@end
