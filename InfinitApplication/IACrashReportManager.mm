//
//  IACrashReportManager.m
//  InfinitApplication
//
//  Created by Christopher Crone on 9/2/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#undef check
#import <elle/log.hh>

#import <surface/gap/gap.hh>

#import "IACrashReportManager.h"

#import <CrashReporter/CrashReporter.h>

#import "IALogFileManager.h"
#import "IAUserPrefs.h"

ELLE_LOG_COMPONENT("OSX.CrashReportManager");

@implementation IACrashReportManager

+ (IACrashReportManager*)sharedInstance
{
  static IACrashReportManager* instance = nil;
  if (instance == nil)
  {
    instance = [[IACrashReportManager alloc] init];
  }
  return instance;
}


- (void)setupCrashReporter
{
  NSLog(@"%@ Starting crash reporter", self);
  PLCrashReporter* crash_reporter = [PLCrashReporter sharedReporter];
  NSError* error;
  
  //    [self removeOldCrashReports];
  
  // Enable the Crash Reporter
  if (![crash_reporter enableCrashReporterAndReturnError:&error])
    NSLog(@"%@ WARNING: Could not enable crash reporter: %@", self, error);
}

- (void)sendExistingCrashReports
{
  PLCrashReporter* crash_reporter = [PLCrashReporter sharedReporter];
  
  // Check if we previously crashed
  if ([crash_reporter hasPendingCrashReport])
    [self handleCrashReport];
}

- (void)removeOldCrashReports
{
  NSArray* dir_files = [[NSFileManager defaultManager]
                        contentsOfDirectoryAtPath:[[IALogFileManager sharedInstance] logPath]
                        error:nil];
  NSArray* crash_files = [dir_files filteredArrayUsingPredicate:
                          [NSPredicate predicateWithFormat:@"self ENDSWITH '.crash'"]];
  for (NSString* file in crash_files)
  {
    NSString* file_path = [[[IALogFileManager sharedInstance] logPath]
                           stringByAppendingPathComponent:file];
    [NSFileManager.defaultManager removeItemAtPath:file_path
                                             error:nil];
  }
}

// XXX Fetch Apple crash report until we are able to symbolicate our crash reports
- (NSString*)getAppleCrashReport
{
  NSString* dir = [NSHomeDirectory() stringByAppendingPathComponent:
                   @"Library/Logs/DiagnosticReports"];
  NSArray* dir_files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dir
                                                                           error:nil];
  NSMutableArray* infinit_crashes = [NSMutableArray arrayWithArray:
                                     [dir_files filteredArrayUsingPredicate:
                                      [NSPredicate
                                       predicateWithFormat:@"self BEGINSWITH 'InfinitApplication'"]]];
  [infinit_crashes sortUsingSelector:@selector(compare:)];
  if (infinit_crashes.count > 0)
    return [dir stringByAppendingPathComponent:infinit_crashes[infinit_crashes.count - 1]];
  
  return nil;
}

// XXX For now we just use this to find out when we crashed and fetch the Apple crash report. Plan
// is to use our own when we can properly symbolicate the reports.
- (void)handleCrashReport
{
  PLCrashReporter* crash_reporter = [PLCrashReporter sharedReporter];
  //    NSData* crash_data;
  //    NSError* error;
  //
  //    // Try loading the crash report
  //    crash_data = [crash_reporter loadPendingCrashReportDataAndReturnError:&error];
  //    if (crash_data == nil)
  //    {
  //        NSLog(@"%@ WARNING: Could not load crash report: %@", self, error);
  //        [crash_reporter purgePendingCrashReport];
  //        return;
  //    }
  //
  //    PLCrashReport* report = [[PLCrashReport alloc] initWithData:crash_data
  //                                                          error:&error];
  //    if (report == nil)
  //    {
  //        NSLog(@"%@ WARNING: Could not parse crash report %@", self, error);
  //        [crash_reporter purgePendingCrashReport];
  //        return;
  //    }
  //
  //    NSString* text_report = [PLCrashReportTextFormatter
  //                             stringValueForCrashReport:report
  //                                        withTextFormat:PLCrashReportTextFormatiOS];
  //
  //    NSString* filename = @"crash_log.crash";
  //    NSString* crash_file_path = [[[IALogFileManager sharedInstance] logPath]
  //                                 stringByAppendingPathComponent:filename];
  //
  //    [text_report writeToFile:crash_file_path atomically:YES
  //                    encoding:NSUTF8StringEncoding
  //                       error:&error];
  //    if (error.code != 0)
  //        NSLog(@"%@ WARNING: Writing crash report failed", self);
  
  ELLE_LOG("%s: sending existing crash report", self.description.UTF8String);
  
  NSString* last_state_log = [[IALogFileManager sharedInstance] lastLogFilePath];
  NSString* crash_file_path = [self getAppleCrashReport];
  
  NSString* os_description = [NSString stringWithFormat:@"OS X %@", [IAFunctions osVersionString]];
  
  NSString* user_name = [[IAUserPrefs sharedInstance] prefsForKey:@"user:email"];
  NSString* additional_info = @"None";
  
  if (last_state_log != nil && crash_file_path != nil && user_name != nil)
  {
    [[IAGapState instance] sendLastCrashLogsForUser:user_name
                                      crashFilePath:crash_file_path
                                       lastStateLog:last_state_log
                                      osDescription:os_description
                                     additionalInfo:additional_info
                                    performSelector:@selector(crashReportSent:)
                                           onObject:self];
  }
  [crash_reporter purgePendingCrashReport];
}

- (void)crashReportSent:(IAGapOperationResult*)result
{
  if (result.success)
    ELLE_LOG("%s: exisiting crash report sent", self.description.UTF8String);
  else
    ELLE_WARN("%s: unable to send exisiting crash report", self.description.UTF8String);
}

- (void)sendUserReportWithMessage:(NSString*)message
                          andFile:(NSString*)file_path
{
  NSString* user_name = [[IAUserPrefs sharedInstance] prefsForKey:@"user:email"];
  NSString* os_description = [NSString stringWithFormat:@"OS X %@", [IAFunctions osVersionString]];
  
  [[IAGapState instance] sendUserReportForUser:user_name
                                       message:message
                                      filePath:file_path
                                 osDescription:os_description
                               performSelector:@selector(userReportSent:)
                                      onObject:self];
}

- (void)userReportSent:(IAGapOperationResult*)result
{
  if (result.success)
    ELLE_LOG("%s: user report sent", self.description.UTF8String);
  else
    ELLE_WARN("%s: unable to send user report", self.description.UTF8String);
}

@end
