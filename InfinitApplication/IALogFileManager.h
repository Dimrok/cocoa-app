//
//  IALogFileManager.h
//  InfinitApplication
//
//  Created by Christopher Crone on 9/2/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//
// This manager is used to manage rolling of logs so that we have only the previous log file and the
// current one. It has the ability to return the names of the current and last log files and to
// remove old log files.

#import <Foundation/Foundation.h>

@interface IALogFileManager : NSObject

+ (IALogFileManager*)sharedInstance;

- (NSString*)currentLogFilePath;

- (NSString*)lastLogFilePath;

- (void)removeOldLogFile;

- (NSString*)logPath;

@end
