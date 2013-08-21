//
//  IAGap.m
//  InfinitApplication
//
//  Created by infinit on 3/6/13.
//  Copyright (c) 2013 infinit. All rights reserved.
//

#import "IAGap.h"
#import "IAGapMetrics.h"
#import <Gap/IAGapProtocol.h>
#import <Gap/gap.h>
#import <Gap/IAGapState.h>

//#define BUILD_PRODUCTION 1

//- Callbacks for notifications -----------------------------------------------------

static
void on_user_status(uint32_t const user_id, gap_UserStatus status);

static
void on_transaction(uint32_t const transaction_id, TransferState status);

static
void on_error_callback(gap_Status errcode, char const* reason, uint32_t const transaction_id);


@interface NotificationForwarder : NSObject

- (id)init:(NSString*)msg withInfo:(NSDictionary*)info;
- (void)fire;

@end

@implementation NotificationForwarder
{
    NSString* _msg;
    NSDictionary* _info;
}

- (id)init:(NSString*)msg withInfo:(NSDictionary *)info
{
    if (self = [super init])
    {
        _msg = msg;
        _info = info;
    }
    return self;
}

- (void)fire
{
    [self performSelectorOnMainThread:@selector(_fire)
                           withObject:nil
                        waitUntilDone:NO];
}

- (void)_fire
{
    IALog(@"Forwarding %@: %@", _msg, _info);
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:_msg object:nil userInfo:_info];
    
    NSDistributedNotificationCenter* dc = [NSDistributedNotificationCenter defaultCenter];
    [dc postNotificationName:_msg object:nil userInfo:_info deliverImmediately:YES];
}

@end


@implementation IAGap
{
@private
    gap_State* _state;
    id<IAGapMetricsProtocol> _metrics_protocol;
}

- (gap_State*)state
{
    return _state;
}

+ (void)sendNotif:(NSString*)msg
         withInfo:(NSMutableDictionary*)info
{
    if (info == nil)
        info = [NSMutableDictionary dictionary];
    
    [info setObject:[IAGapState instance].self_id
             forKey:@"self_id"];
    [info setObject:[NSNumber numberWithInteger:(NSInteger)getpid()]
             forKey:@"pid"];
    
    [[[NotificationForwarder alloc] init:msg withInfo:info] fire];
}

- (NSString*)logPath
{
    return [NSHomeDirectory() stringByAppendingPathComponent:@".infinit"];
}

- (NSString*)logFile
{
    NSString* log_filename = [[NSString alloc] initWithFormat:@"state_%0.0f.log", [[NSDate date] timeIntervalSince1970]];
    NSString* log_file = [[self logPath] stringByAppendingPathComponent:log_filename];
    return log_file;
}

- (NSTimeInterval)numberFromString:(NSString*)str
{
    NSString* num_str;
    NSScanner* scanner = [NSScanner scannerWithString:str];
    NSCharacterSet* numbers = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
    [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
    [scanner scanCharactersFromSet:numbers intoString:&num_str];
    return [num_str doubleValue];
}

- (void)removeOldLogs
{
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval cut_off = now - (7 * 24 * 60 *60); // One week ago
    NSArray* dir_files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self logPath] error:nil];
    NSArray* log_files = [dir_files filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self ENDSWITH '.log'"]];
    for (NSString* file in log_files)
    {
        if ([file hasPrefix:@"state"] && [self numberFromString:file] < cut_off)
        {
            [[NSFileManager defaultManager] removeItemAtPath:[[self logPath] stringByAppendingPathComponent:file] error:nil];
        }
    }
}

- (id)init
{
    if (self = [super init])
    {
        NSArray* exe_path = NSBundle.mainBundle.executablePath.pathComponents;
        NSString* binary_dir = [NSString pathWithComponents:[exe_path subarrayWithRange:NSMakeRange(0, [exe_path count] - 1)]];
        setenv("INFINIT_BINARY_DIR", binary_dir.UTF8String, 1);
        setenv("ELLE_LOG_LEVEL",
               "TRACE,"
               "infinit.crypto*:LOG,"
               "infinit.protocol*:LOG,"
               "infinit.surface*:DEBUG,"
               "elle.*:LOG,"
               "reactor*:LOG,"
               "elle.metrics.*:LOG,"
               "infinit.surface.gap.User:NONE",
               0);
        setenv("ELLE_LOG_PID", "1", 0);
        setenv("ELLE_LOG_TID", "1", 0);
        setenv("ELLE_LOG_TIME", "1", 0);
        setenv("ELLE_LOG_DISPLAY_TYPE", "1", 0);
        if (![[NSFileManager defaultManager] fileExistsAtPath:[NSHomeDirectory() stringByAppendingPathComponent:@".infinit"] isDirectory:nil])
        {
            [[NSFileManager defaultManager] createDirectoryAtPath:[NSHomeDirectory() stringByAppendingPathComponent:@".infinit"]
                                      withIntermediateDirectories:NO
                                                       attributes:nil
                                                            error:nil];
        }
//        setenv("ELLE_LOG_FILE", [[self logFile] UTF8String], 0);
        setenv("ELLE_LOG_FILE", "/Users/chris/.infinit/state.log", 0);
        [self removeOldLogs];

#ifdef BUILD_PRODUCTION
        setenv("INFINIT_APERTUS_HOST", "apertus.api.production.infinit.io", 0);
        setenv("INFINIT_APERTUS_PORT", "9899", 0);
        
        setenv("INFINIT_META_HOST", "v1.meta.api.production.infinit.io", 0);
        setenv("INFINIT_META_PORT", "12345", 0);

        setenv("INFINIT_TROPHONIUS_HOST", "v1.trophonius.api.production.infinit.io", 0);
        setenv("INFINIT_TROPHONIUS_PORT", "23456", 0);

        setenv("INFINIT_CRASH_DEST", "crash@infinit.io", 0);

        setenv("INFINIT_METRICS_GOOGLE_TID", "UA-31957100-4", 0);
        setenv("INFINIT_METRICS_INVESTORS_GOOGLE_TID", "UA-31957100-2", 0);

        setenv("INFINIT_METRICS_KISSMETRICS_TID", "eb9c8d61d0cded222fd85cbfa0dbcd3884c6d034", 0);
        setenv("INFINIT_METRICS_KISSMETRICS_USER_TID", "852a52e101e7c25ef806cd7ae8ce706a9c238498", 0);
        setenv("INFINIT_METRICS_KISSMETRICS_NETWORK_TID", "88e0663996d002fb7a6c5e547cac5cb815c640f0", 0);
        setenv("INFINIT_METRICS_KISSMETRICS_TRANSACTION_TID", "a36c426570d8f1dc404891a284f033d003bbe9c2", 0);
#else
//        setenv("INFINIT_APERTUS_HOST", "apertus.api.development.infinit.io", 0);
        setenv("INFINIT_APERTUS_HOST", "127.0.0.1", 0);
//        setenv("INFINIT_APERTUS_HOST", "192.168.110.107", 0);
        setenv("INFINIT_APERTUS_PORT", "9899", 0);

//        setenv("INFINIT_META_HOST", "v1.meta.api.development.infinit.io", 0);
        setenv("INFINIT_META_HOST", "127.0.0.1", 0);
//        setenv("INFINIT_META_HOST", "192.168.110.107", 0);
        setenv("INFINIT_META_PORT", "12345", 0);

//        setenv("INFINIT_TROPHONIUS_HOST", "v1.trophonius.api.development.infinit.io", 0);
        setenv("INFINIT_TROPHONIUS_HOST", "127.0.0.1", 0);
//        setenv("INFINIT_TROPHONIUS_HOST", "192.168.110.107", 0);
        setenv("INFINIT_TROPHONIUS_PORT", "23456", 0);

        setenv("INFINIT_CRASH_DEST", "chris@infinit.io", 0);
#endif
        
        _state = gap_new();

        NSLog(@"METAURL= %s", gap_meta_url(_state));
        
        if (_state == NULL)
            return nil;
    }
    return self;
}

- (id<IAGapMetricsProtocol>)getMetricsProxy
{
    if (_metrics_protocol == nil)
    {
        _metrics_protocol = [[IAGapMetrics alloc] initWithState:_state];
    }
    return _metrics_protocol;
}

- (gap_Status)login:(NSString*)email
           password:(NSString*)hash_password;
{
    gap_Status res = gap_login(_state, email.UTF8String, hash_password.UTF8String);
    if (res == gap_ok)
    {
        [IAGap sendNotif:IA_GAP_EVENT_LOGIN_OPERATION withInfo:nil];
        if ((gap_user_status_callback(_state, &on_user_status) != gap_ok) ||
            (gap_transaction_callback(_state, &on_transaction) != gap_ok))
            // XXX add error callback
            //            (gap_on_error_callback(_state, &on_error_callback) != gap_ok))
        {
            IALog(@"WARNING: Cannot set callbacks");
        }
    }
    return res;
}

- (NSString*)hash_password:(NSString*)email
                  password:(NSString*)password
{
    char* hash = gap_hash_password(_state, email.UTF8String, password.UTF8String);
    if (hash == NULL)
        return nil;
    NSString* hash_pass = [NSString stringWithUTF8String:hash];
    gap_hash_free(hash);
    return hash_pass;
}

- (gap_Status)logout
{
    return gap_logout(_state);
}

- (BOOL)logged_in
{
    BOOL logged_in =  gap_logged_in(_state);
    return logged_in;
}

- (gap_Status)register_:(NSString*)fullname
                  email:(NSString*)email
               password:(NSString*)hash_password
            device_name:(NSString*)device_name
        activation_code:(NSString*)activation_code
{
    gap_Status res =  gap_register(_state, fullname.UTF8String,
                                   email.UTF8String,
                                   hash_password.UTF8String,
                                   device_name.UTF8String,
                                   activation_code.UTF8String);
    if (res == gap_ok)
    {
        return [self login:email password:hash_password];
    }
    return res;
}

- (NSString*)meta_url
{
    return [NSString stringWithUTF8String:gap_meta_url(_state)];
}

- (gap_Status)pull_notifications:(int)count
                          offset:(int)offset
{
    gap_Status ret = gap_pull_notifications(_state, count, offset);
    return ret;
}

- (gap_Status)notifications_read
{
    return gap_notifications_read(_state);
}

#define RETURN_CSTRING(expr) \
do { \
char const* str = expr; \
if (str == NULL) return nil; \
return [NSString stringWithUTF8String:str]; \
} while (false) \
/**/

- (NSNumber*)transaction_sender_id:(NSNumber*)transaction_id
{
    return [NSNumber numberWithUnsignedInt:(gap_transaction_sender_id(_state,
                                            transaction_id.unsignedIntValue))];
}

- (NSString*)transaction_sender_fullname:(NSNumber*)transaction_id
{
    RETURN_CSTRING(gap_transaction_sender_fullname(_state, transaction_id.unsignedIntValue));
}

- (NSString*)transaction_sender_device_id:(NSNumber*)transaction_id
{
    RETURN_CSTRING(gap_transaction_sender_device_id(_state, transaction_id.unsignedIntValue));
}

- (NSNumber*)transaction_recipient_id:(NSNumber*)transaction_id
{
    return [NSNumber numberWithUnsignedInt:(gap_transaction_recipient_id(_state,
                                                                transaction_id.unsignedIntValue))];
}

- (NSString*)transaction_recipient_fullname:(NSNumber*)transaction_id
{
    RETURN_CSTRING(gap_transaction_recipient_fullname(_state, transaction_id.unsignedIntValue));
}

- (NSString*)transaction_recipient_device_id:(NSNumber*)transaction_id
{
    RETURN_CSTRING(gap_transaction_recipient_device_id(_state, transaction_id.unsignedIntValue));
}

- (NSString*)transaction_network_id:(NSNumber*)transaction_id
{
    RETURN_CSTRING(gap_transaction_network_id(_state, transaction_id.unsignedIntValue));
}

- (NSString*)transaction_first_filename:(NSNumber*)transaction_id
{
    RETURN_CSTRING(gap_transaction_first_filename(_state, transaction_id.unsignedIntValue));
}

- (int)transaction_files_count:(NSNumber*)transaction_id
{
    return gap_transaction_files_count(_state, transaction_id.unsignedIntValue);
}

- (uint64_t)transaction_total_size:(NSNumber*)transaction_id
{
    return gap_transaction_total_size(_state, transaction_id.unsignedIntValue);
}

- (NSTimeInterval)transaction_timestamp:(NSNumber*)transaction_id
{
    return gap_transaction_timestamp(_state, transaction_id.unsignedIntValue);
}

- (int)transaction_is_directory:(NSNumber*)transaction_id
{
    return gap_transaction_is_directory(_state, transaction_id.unsignedIntValue);
}

- (gap_TransactionStatus)transaction_status:(NSNumber*)transaction_id
{
    return gap_transaction_status(_state, transaction_id.unsignedIntValue);
}

- (float)transaction_progress:(NSNumber*)transaction_id
{
    return gap_transaction_progress(_state, transaction_id.unsignedIntValue);
}

- (gap_Status)poll
{
    return gap_poll(_state);
}

- (void)gapFree
{
    gap_free(_state);
}

- (gap_Status)device_status
{
    return gap_device_status(_state);
}

- (gap_Status)set_device_name:(NSString*)name
{
    return gap_set_device_name(_state, name.UTF8String);
}

- (NSString*)self_token
{
    RETURN_CSTRING(gap_user_token(_state));
}

- (NSString*)self_email
{
    RETURN_CSTRING(gap_self_email(_state));
}

- (NSNumber*)self_id
{
    return [NSNumber numberWithUnsignedInt:(gap_self_id(_state))];
}

- (NSString*)user_fullname:(NSNumber*)user_id
{
    RETURN_CSTRING(gap_user_fullname(_state, user_id.unsignedIntValue));
}

- (NSString*)user_handle:(NSNumber*)user_id
{
    RETURN_CSTRING(gap_user_handle(_state, user_id.unsignedIntValue));
}

- (NSString*)user_realid:(NSNumber*)user_id
{
    RETURN_CSTRING(gap_user_realid(_state, user_id.unsignedIntValue));
}

- (gap_UserStatus)user_status:(NSNumber*)user_id
{
    return gap_user_status(_state, user_id.unsignedIntValue);
}

- (NSNumber*)user_by_email:(NSString*)email
{
    return [NSNumber numberWithUnsignedInt:(gap_user_by_email(_state, email.UTF8String))];
}
- (NSArray*)search_users:(NSString*)text
{
    UInt32* results = gap_search_users(_state, text.UTF8String);
    if (results == NULL)
        return nil;
    NSMutableArray* array = [NSMutableArray array];
    for (UInt32* ptr = results; *ptr != 0; ++ptr)
        [array addObject:[NSNumber numberWithUnsignedInt:*ptr]];
    gap_search_users_free(results);
    return array;
}

- (NSArray*)favourites
{
    UInt32* results = gap_swaggers(_state);
    if (results == NULL)
        return nil;
    NSMutableArray* array = [NSMutableArray array];
    for (UInt32* ptr = results; *ptr != 0; ++ptr)
        [array addObject:[NSNumber numberWithUnsignedInt:*ptr]];
    gap_swaggers_free(results);
    return array;
}

- (NSArray*)transactions
{
    UInt32* results = gap_transactions(_state);
    if (results == NULL)
        return nil;
    NSMutableArray* array = [NSMutableArray array];
    for (UInt32* ptr = results; *ptr != 0; ++ptr)
        [array addObject:[NSNumber numberWithUnsignedInt:*ptr]];
    gap_transactions_free(results);
    return array;
}

- (uint32_t)send_files_to_user:(NSNumber*)recipient_id
                          files:(NSArray*)files
{

    char const** cfiles = (char const**)calloc([files count] + 1, sizeof(char*));
    if (cfiles == NULL)
        return gap_null();
    int i = 0;
    for (id file in files)
    {
        cfiles[i++] = [file UTF8String];
        IALog(@"Sending %@ to %@", file, recipient_id);
    }
    uint32_t ret = gap_send_files(_state, recipient_id.unsignedIntValue, cfiles);
    free(cfiles);
    return ret;
}

- (uint32_t)send_files_by_email:(NSString*)recipient_email
                           files:(NSArray*)files
{
    
    char const** cfiles = (char const**)calloc([files count] + 1, sizeof(char*));
    if (cfiles == NULL)
        return gap_null();
    int i = 0;
    for (id file in files)
    {
        cfiles[i++] = [file UTF8String];
        IALog(@"Sending %@ to %@", file, recipient_email);
    }
    uint32_t ret = gap_send_files_by_email(_state, recipient_email.UTF8String, cfiles);
    free(cfiles);
    return ret;
}

- (gap_Status)accept_transaction:(NSNumber*)transaction_id
{
    return gap_accept_transaction(_state, transaction_id.unsignedIntValue);
}

- (gap_Status)cancel_transaction:(NSNumber*)transaction_id
{
    return gap_cancel_transaction(_state, transaction_id.unsignedIntValue);
}

- (gap_Status)set_output_dir:(NSString*)output_path
{
    return gap_set_output_dir(_state, output_path.UTF8String);
}

- (NSString*)get_output_dir
{
    RETURN_CSTRING(gap_get_output_dir(_state));
}


- (void)log:(NSString*)str
{
    NSLog(@"%@", str);
}

- (NSString*)getApplicationPath
{
    return [[NSBundle mainBundle] bundlePath];
}


- (NSInteger)remaining_invitations
{
    return gap_self_remaining_invitations(_state);
}

@end


//- notif callback implementation -----------------------------------------------------------
static void on_user_status(uint32_t const user_id,
                           gap_UserStatus status)
{
    assert(user_id != 0);
    IALog(@">>> on user status notif !");
    @try
    {
        NSMutableDictionary* info = [NSMutableDictionary dictionary];
        [info setObject:[NSNumber numberWithUnsignedInt:user_id]
                 forKey:@"user_id"];
        [info setObject:[NSNumber numberWithInt:status]
                 forKey:@"user_status"];
        [IAGap sendNotif:IA_GAP_EVENT_USER_STATUS_NOTIFICATION
                withInfo:info];
    }
    @catch (NSException* exception)
    {
        IALog(@"WARNING: on user status exception: %@", exception);
    }
}

static void on_transaction(uint32_t const transaction_id, TransferState status)
{
    assert(transaction_id != 0);
    IALog(@">>> On transaction notif: %d", transaction_id);
    @try
    {
        NSMutableDictionary* msg = [NSMutableDictionary dictionary];
        [msg setValue:[NSNumber numberWithUnsignedInt:transaction_id]
               forKey:@"transaction_id"];
        [msg setValue:[NSNumber numberWithInt:status]
               forKey:@"status"];
        [IAGap sendNotif:IA_GAP_EVENT_TRANSACTION_NOTIFICATION withInfo:msg];
    }
    @catch (NSException* exception)
    {
        IALog(@"WARNING: on_transaction exception: %@", exception.reason);
    }
}

static void on_error_callback(gap_Status errcode, char const* reason, uint32_t const transaction_id)
{
    IALog(@">>> On transaction error callback: %d", transaction_id);
    @try
    {
        NSMutableDictionary* msg = [[NSMutableDictionary alloc] init];
        if (transaction_id != 0)
            [msg setValue:[NSNumber numberWithUnsignedInt:transaction_id]
                   forKey:@"transaction_id"];
        [msg setObject:[NSString stringWithUTF8String:reason]
                forKey:@"reason"];
        
        [msg setObject:[NSNumber numberWithInt:errcode]
                forKey:@"error_code"];
        [IAGap sendNotif:IA_GAP_EVENT_ERROR withInfo:msg];
    }
    @catch (NSException* exception)
    {
        IALog(@"WARNING: on_transaction_status exception: %@", exception.reason);
    }
}

