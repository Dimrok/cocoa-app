//
//  IACrashReportManager.h
//  InfinitApplication
//
//  Created by Christopher Crone on 9/2/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//
// This manager handles setting up the crash reporter and sending log and crash files if a crash has
// occurred.

#import <Foundation/Foundation.h>

@interface IACrashReportManager : NSObject

+ (IACrashReportManager*)sharedInstance;

- (void)setupCrashReporter;

- (void)sendExistingCrashReports;

- (void)sendUserReportWithMessage:(NSString*)message
                          andFile:(NSString*)file_path;

@end
