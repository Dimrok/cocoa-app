//
//  IALogFileManager.m
//  InfinitApplication
//
//  Created by Christopher Crone on 9/2/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IALogFileManager.h"

@implementation IALogFileManager
{
@private
    NSInteger _last_log_number;
    NSInteger _current_log_number;
}

static IALogFileManager* _instance = nil;

//- Initialisation ---------------------------------------------------------------------------------

- (id)init
{
    if (self = [super init])
    {
        _last_log_number = [self lastLogNumber];
        switch (_last_log_number)
        {
            case 0:
                _current_log_number = 1;
                break;
                
            case 1:
                _current_log_number = 2;
                break;
                
            case 2:
                _current_log_number = 0;
                break;
                
            default:
                break;
        }
    }
    return self;
}

//- General Functions ------------------------------------------------------------------------------

+ (IALogFileManager*)sharedInstance
{
    if (_instance == nil)
        _instance = [[IALogFileManager alloc] init];
    
    return _instance;
}

//- Log Handling -----------------------------------------------------------------------------------

// Log rolling system:
// There will only ever be two log files at any given time, i.e.: the last log file and the current
// one. This is achieved by using the suffix 0, 1 or 2 for the log files. The current log file's
// suffix is the last last +1, looping from 2 to 0. The third number is used as a marker so that the
// application knows which log to overwrite on launch.

- (NSString*)logPath
{
    return [NSHomeDirectory() stringByAppendingPathComponent:@".infinit"];
}

- (NSTimeInterval)numberFromString:(NSString*)str
{
    NSString* num_str;
    NSScanner* scanner = [NSScanner scannerWithString:str];
    NSCharacterSet* numbers = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
    [scanner scanUpToCharactersFromSet:numbers
                            intoString:NULL];
    [scanner scanCharactersFromSet:numbers
                        intoString:&num_str];
    return num_str.doubleValue;
}

- (NSInteger)lastLogNumber
{
    NSArray* dir_files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self logPath]
                                                                           error:nil];
    NSArray* log_files = [dir_files filteredArrayUsingPredicate:
                          [NSPredicate predicateWithFormat:@"self ENDSWITH '.log'"]];
    
    BOOL zero = NO;
    BOOL one = NO;
    BOOL two = NO;
    NSUInteger new_logs_count = 0;
    for (NSString* file in log_files)
    {
        NSInteger num = [self numberFromString:file];
        if (num < 3)
        {
            new_logs_count++;
            switch (num)
            {
                case 0:
                    zero = YES;
                    break;
                    
                case 1:
                    one = YES;
                    break;
                    
                case 2:
                    two = YES;
                    
                default:
                    break;
            }
        }
    }
    if ((new_logs_count == 1 && zero) || (zero && two))
        return 0;
    else if (one && zero)
        return 1;
    else if (two && one)
        return 2;
    else // Something weird. A log may have been deleted so remove all and start again.
    {
        if (zero)
            [self removeLogFileWithNumber:0];
        if (one)
            [self removeLogFileWithNumber:1];
        if (two)
            [self removeLogFileWithNumber:2];
    }
    
    // Handle case that there are no logfiles
    return -1;
}

- (NSString*)currentLogFilePath
{
    NSString* log_filename = [[NSString alloc] initWithFormat:@"state_%ld.log", _current_log_number];
    NSString* log_file = [[self logPath] stringByAppendingPathComponent:log_filename];
    return log_file;
}

- (NSString*)lastLogFilePath
{
    NSString* last_log_path = [[self logPath] stringByAppendingPathComponent:
                                                    [NSString stringWithFormat:@"state_%ld.log",
                                                                               _last_log_number]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:last_log_path])
        return last_log_path;
    
    return nil;
}

- (void)removeLegacyLogFiles
{
    NSArray* dir_files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self logPath]
                                                                             error:nil];
    NSArray* log_files = [dir_files filteredArrayUsingPredicate:
                          [NSPredicate predicateWithFormat:@"self ENDSWITH '.log'"]];
    for (NSString* file in log_files)
    {
        NSString* file_path = [[self logPath] stringByAppendingPathComponent:file];
        if ([file hasPrefix:@"state"] && [self numberFromString:file] > 3)
        {
            [[NSFileManager defaultManager] removeItemAtPath:file_path
                                                       error:nil];
        }
    }
}

- (void)removeLogFileWithNumber:(NSInteger)num
{
    NSLog(@"xxx deleting log with number %d", num);
    if (num == -1)
        return;
    
    NSString* file_path = [[self logPath] stringByAppendingPathComponent:
                           [NSString stringWithFormat:@"state_%ld.log", num]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:file_path])
    {
        [[NSFileManager defaultManager] removeItemAtPath:file_path
                                                   error:nil];
    }
}

- (void)removeOldLogFile
{
    switch (_current_log_number)
    {
        case -1:
            break;
            
        case 0:
            [self removeLogFileWithNumber:1];
            break;
            
        case 1:
            [self removeLogFileWithNumber:2];
            break;
            
        case 2:
            [self removeLogFileWithNumber:0];
            break;
            
        default:
            break;
    }
    [self removeLegacyLogFiles];
}

@end
