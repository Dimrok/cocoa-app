//
//  IAGap.m
//  InfinitApplication
//
//  Created by infinit on 3/6/13.
//  Copyright (c) 2013 infinit. All rights reserved.
//

#include <surface/gap/gap.hh>

#import "IAGap.h"

#import <Gap/IAGapProtocol.h>
#import <Gap/IAGapState.h>

#import "IALogFileManager.h"

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("OSX.Gap");

//- Callbacks for notifications -----------------------------------------------------

static BOOL _callbacks_set = NO;

static
void clear_model();

static
void on_user_status(uint32_t const user_id, gap_UserStatus status);

static
void on_transaction(uint32_t const transaction_id, gap_TransactionStatus status);

static
void on_error_callback(gap_Status errcode, char const* reason, uint32_t const transaction_id);

static
void on_kicked_out();

static
void on_connection_status(gap_UserStatus status);

static
void on_received_avatar(uint32_t const user_id);

static
void on_critical_event(char const* str)
{
  exit(1);
}

static
void on_trophonius_unavailable();

@interface NotificationForwarder : NSObject

- (id)init:(NSString*)msg withInfo:(NSDictionary*)info;
- (void)fire;

@end

@implementation NotificationForwarder
{
  NSString* _msg;
  NSDictionary* _info;
}

- (id)init:(NSString*)msg withInfo:(NSDictionary*)info
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
  ELLE_DEBUG("%s: fire %s: %s", self.description.UTF8String, _msg.description.UTF8String,
             _info.description.UTF8String);
  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
  [nc postNotificationName:_msg object:nil userInfo:_info];
}

@end


@implementation IAGap
{
@private
  gap_State* _state;
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
  
  [[[NotificationForwarder alloc] init:msg
                              withInfo:info] fire];
}

- (id)init
{
  if (self = [super init])
  {
    NSArray* exe_path = NSBundle.mainBundle.executablePath.pathComponents;
    NSString* binary_dir = [NSString pathWithComponents:[exe_path subarrayWithRange:NSMakeRange(0, [exe_path count] - 1)]];
    setenv("INFINIT_BINARY_DIR", binary_dir.UTF8String, 1);
    setenv("ELLE_LOG_LEVEL",
           "*trophonius*:TRACE,"
           "*meta*:TRACE,"
           "surface.gap*:DEBUG,"
           "reactor.fsm:DEBUG,"
           "frete.Frete:DEBUG,"
           "OSX*:DUMP"
           , 0);
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
    setenv("ELLE_LOG_FILE", [[[IALogFileManager sharedInstance] currentLogFilePath] UTF8String], 1);
    [[IALogFileManager sharedInstance] removeOldLogFile];
    
    bool production = false;
    
#ifdef BUILD_PRODUCTION
    production = true;
    
    setenv("INFINIT_META_PROTOCOL", "https", 1);
    setenv("INFINIT_META_HOST", "meta.8.0.api.production.infinit.io", 1);
    setenv("INFINIT_META_PORT", "443", 1);
    
    setenv("INFINIT_TROPHONIUS_HOST", "trophonius.8.0.api.production.infinit.io", 1);
    setenv("INFINIT_TROPHONIUS_PORT", "443", 1);
    
    setenv("INFINIT_CRASH_DEST", "crash@infinit.io", 1);
    
    //        setenv("INFINIT_METRICS_INFINIT_HOST", "v3.metrics.api.production.infinit.io", 1);
    //        setenv("INFINIT_METRICS_INFINIT_PORT", "80", 1);
#else
    production = false;
    
    setenv("INFINIT_CLOUD_BUFFERING", "1", 1);
    
    setenv("ELLE_REAL_ASSERT", "1", 1);
    
    setenv("INFINIT_META_PROTOCOL", "https", 1);
    setenv("INFINIT_META_HOST", "development.infinit.io", 1);
    setenv("INFINIT_META_PORT", "443", 1);
    //        setenv("INFINIT_META_PROTOCOL", "http", 1);
    //        setenv("INFINIT_META_HOST", "127.0.0.1", 1);
    //        setenv("INFINIT_META_PORT", "8080", 1);
    
    setenv("INFINIT_TROPHONIUS_HOST", "development.infinit.io", 1);
    setenv("INFINIT_TROPHONIUS_PORT", "444", 1);
    //        setenv("INFINIT_TROPHONIUS_HOST", "127.0.0.1", 1);
    //        setenv("INFINIT_TROPHONIUS_PORT", "8181", 1);
    
    //        setenv("INFINIT_METRICS_HOST", "v3.metrics.api.development.infinit.io", 1);
    //        setenv("INFINIT_METRICS_PORT", "80", 1);
    //        setenv("INFINIT_METRICS_INFINIT", "1", 1);
    //        setenv("INFINIT_METRICS_INFINIT_HOST", "127.0.0.1", 1);
    //        setenv("INFINIT_METRICS_INFINIT_PORT", "8282", 1);
    
    setenv("INFINIT_CRASH_DEST", "chris@infinit.io", 1);
#endif
    
    _state = gap_new(production);
    
    
    if (_state == NULL)
      return nil;
  }
  return self;
}

- (void)setCallbacks
{
  if ((gap_user_status_callback(_state, &on_user_status) != gap_ok) ||
      (gap_transaction_callback(_state, &on_transaction) != gap_ok) ||
      (gap_connection_callback(_state, &on_connection_status) != gap_ok) ||
      (gap_critical_callback(_state, &on_critical_event) != gap_ok) ||
      (gap_kicked_out_callback(_state, &on_kicked_out) != gap_ok) ||
      (gap_avatar_available_callback(_state, &on_received_avatar) != gap_ok) ||
      (gap_trophonius_unavailable_callback(_state, &on_trophonius_unavailable) != gap_ok))
    // XXX add error callback
    //            (gap_on_error_callback(_state, &on_error_callback) != gap_ok))
  {
    ELLE_WARN("%s: cannot set callbacks", self.description.UTF8String);
  }
  else
  {
    _callbacks_set = YES;
  }
}

- (gap_Status)login:(NSString*)email
           password:(NSString*)hash_password;
{
  if (_callbacks_set == NO)
    [self setCallbacks];
  gap_Status res = gap_login(_state, email.UTF8String, hash_password.UTF8String);
  if (res == gap_ok)
  {
    ELLE_DEBUG("%s: login successful", self.description.UTF8String);
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
  clear_model();
  return gap_logout(_state);
}

- (BOOL)logged_in
{
  return gap_logged_in(_state);
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
  return [NSNumber numberWithUnsignedInt:gap_transaction_sender_id(_state,
                                                                   transaction_id.unsignedIntValue)];
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

- (NSArray*)transaction_files:(NSNumber*)transaction_id
{
  char** files = gap_transaction_files(_state, transaction_id.unsignedIntValue);
  if (files == NULL)
    return nil;
  NSMutableArray* res = [NSMutableArray array];
  for (char** ptr = files; *ptr != NULL; ++ptr)
    [res addObject:[NSString stringWithUTF8String:*ptr]];
  free(files);
  return res;
}

- (NSNumber*)transaction_files_count:(NSNumber*)transaction_id
{
  return [NSNumber numberWithLongLong:gap_transaction_files_count(_state, transaction_id.unsignedIntValue)];
}

- (NSNumber*)transaction_total_size:(NSNumber*)transaction_id
{
  return [NSNumber numberWithLongLong:gap_transaction_total_size(_state, transaction_id.unsignedIntValue)];
}

- (NSTimeInterval)transaction_ctime:(NSNumber*)transaction_id
{
  return gap_transaction_ctime(_state, transaction_id.unsignedIntValue);
}

- (NSTimeInterval)transaction_mtime:(NSNumber*)transaction_id
{
  return gap_transaction_mtime(_state, transaction_id.unsignedIntValue);
}

- (int)transaction_is_directory:(NSNumber*)transaction_id
{
  return gap_transaction_is_directory(_state, transaction_id.unsignedIntValue);
}

- (NSString*)transaction_message:(NSNumber*)transaction_id
{
  RETURN_CSTRING(gap_transaction_message(_state, transaction_id.unsignedIntValue));
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

- (NSString*)self_email
{
  RETURN_CSTRING(gap_self_email(_state));
}

- (NSNumber*)self_id
{
  return [NSNumber numberWithUnsignedInt:(gap_self_id(_state))];
}

- (void)set_avatar:(NSImage*)avatar
{
  
  [avatar lockFocus];
  NSBitmapImageRep* bitmapImageRep = [[NSBitmapImageRep alloc]
                                      initWithFocusedViewRect:
                                      NSMakeRect(0, 0, avatar.size.width, avatar.size.height)];
  [avatar unlockFocus];
  
  NSData* image_data = [bitmapImageRep representationUsingType:NSPNGFileType properties:nil];
  
  gap_update_avatar(_state, image_data.bytes, image_data.length);
}

- (NSImage*)get_avatar:(NSNumber*)user_id
{
  void* c_data;
  size_t size;
  gap_Status status = gap_avatar(_state, user_id.unsignedIntValue, &c_data, &size);
  if (status == gap_ok)
  {
    NSData* avatar_data = [[NSData alloc] initWithBytes:c_data length:size];
    NSImage* avatar = [[NSImage alloc] initWithData:avatar_data];
    return avatar;
  }
  else
  {
    return nil;
  }
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

- (BOOL)user_is_favorite:(NSNumber*)user_id
{
  BOOL res = gap_is_favorite(_state, user_id.unsignedIntValue);
  return res;
}

- (gap_UserStatus)user_status:(NSNumber*)user_id
{
  return gap_user_status(_state, user_id.unsignedIntValue);
}

- (NSNumber*)user_by_email:(NSString*)email
{
  return [NSNumber numberWithUnsignedInt:(gap_user_by_email(_state, email.UTF8String))];
}

- (NSDictionary*)users_by_emails:(NSArray*)emails
{
  NSMutableDictionary* res = [NSMutableDictionary dictionary];
  if (emails.count == 0)
    return res;
  std::vector<std::string> emails_;
  for (NSString* email in emails)
  {
    std::string email_(email.UTF8String);
    emails_.push_back(email_);
  }
  std::unordered_map<std::string, uint32_t> user_map = gap_users_by_emails(_state, emails_);
  for (std::pair<std::string, uint32_t> pair: user_map)
  {
    [res setObject:[NSNumber numberWithUnsignedInt:pair.second]
            forKey:[NSString stringWithUTF8String:pair.first.c_str()]];
  }
  return res;
}

- (NSNumber*)user_by_handle:(NSString*)handle
{
  return [NSNumber numberWithUnsignedInt:(gap_user_by_handle(_state, handle.UTF8String))];
}

- (NSArray*)search_users:(NSString*)text
{
  NSMutableArray* res = [NSMutableArray array];
  if (text.length == 0)
    return res;
  
  std::vector<uint32_t> results = gap_users_search(_state, text.UTF8String);
  for (auto const& user_id: results)
    [res addObject:[NSNumber numberWithUnsignedInt:user_id]];
  
  return res;
}

- (NSArray*)swaggers
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

- (NSNumber*)get_onboarding_transaction_with_file_path:(NSString*)file_path
                                          and_run_time:(NSNumber*)seconds;
{
  UInt32 transaction_id =
  gap_onboarding_receive_transaction(_state, file_path.UTF8String, seconds.unsignedIntValue);
  return [NSNumber numberWithUnsignedInt:transaction_id];
}

- (gap_TransactionStatus)transaction_status:(NSNumber*)transaction_id
{
  return gap_transaction_status(_state, transaction_id.unsignedIntValue);
}

- (NSNumber*)send_files_to_user:(NSNumber*)recipient_id
                          files:(NSArray*)files
                        message:(NSString*)message
{
  
  char const** cfiles = (char const**)calloc([files count] + 1, sizeof(char*));
  if (cfiles == NULL)
    return [NSNumber numberWithUnsignedInt:gap_null()];
  int i = 0;
  for (id file in files)
  {
    cfiles[i++] = [file UTF8String];
    ELLE_DEBUG("%s: sending %s to %d", self.description.UTF8String, [file UTF8String],
               recipient_id.integerValue);
  }
  uint32_t ret = gap_send_files(_state,
                                recipient_id.unsignedIntValue,
                                cfiles,
                                message.UTF8String);
  free(cfiles);
  return [NSNumber numberWithUnsignedInt:ret];
}

- (NSNumber*)send_files_by_email:(NSString*)recipient_email
                           files:(NSArray*)files
                         message:(NSString*)message
{
  
  char const** cfiles = (char const**)calloc([files count] + 1, sizeof(char*));
  if (cfiles == NULL)
    return [NSNumber numberWithUnsignedInt:gap_null()];
  int i = 0;
  for (id file in files)
  {
    cfiles[i++] = [file UTF8String];
    ELLE_DEBUG("%s: sending %s to %s", self.description.UTF8String, [file UTF8String],
               recipient_email.UTF8String);
  }
  uint32_t ret = gap_send_files_by_email(_state,
                                         recipient_email.UTF8String,
                                         cfiles,
                                         message.UTF8String);
  free(cfiles);
  return [NSNumber numberWithUnsignedInt:ret];
}

- (NSNumber*)accept_transaction:(NSNumber*)transaction_id
{
  return [NSNumber numberWithUnsignedInt:gap_accept_transaction(_state,
                                                                transaction_id.unsignedIntValue)];
}

- (NSNumber*)cancel_transaction:(NSNumber*)transaction_id
{
  return [NSNumber numberWithUnsignedInt:gap_cancel_transaction(_state,
                                                                transaction_id.unsignedIntValue)];
}

- (NSNumber*)reject_transaction:(NSNumber*)transaction_id
{
  return [NSNumber numberWithUnsignedInt:gap_reject_transaction(_state,
                                                                transaction_id.unsignedIntValue)];
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

- (NSArray*)self_favorites
{
  UInt32* favourites = gap_self_favorites(_state);
  if (favourites == NULL)
    return nil;
  NSMutableArray* res = [NSMutableArray array];
  for (UInt32* ptr = favourites; *ptr != 0; ++ptr)
    [res addObject:[NSNumber numberWithUnsignedInt:*ptr]];
  free(favourites);
  return res;
}

- (gap_Status)favorite:(NSNumber*)user_id
{
  return gap_favorite(_state, user_id.unsignedIntValue);
}

- (gap_Status)unfavorite:(NSNumber*)user_id
{
  return gap_unfavorite(_state, user_id.unsignedIntValue);
}

@end


//- notif callback implementation -----------------------------------------------------------

static void clear_model()
{
  ELLE_DUMP("clearing Cocoa models");
  [[IAGapState instance] loggedOut];
  on_connection_status(gap_user_status_offline);
  [IAGap sendNotif:IA_GAP_EVENT_CLEAR_MODEL withInfo:nil];
}

static void on_user_status(uint32_t const user_id,
                           gap_UserStatus status)
{
  assert(user_id != 0);
  ELLE_DUMP("on_user_status");
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
    ELLE_WARN("on_user_status exception: %s", exception.reason.UTF8String);
  }
}

static void on_connection_status(gap_UserStatus status)
{
  ELLE_DUMP("on_connection_status: %d", status);
  @try
  {
    NSMutableDictionary* msg = [NSMutableDictionary dictionary];
    [msg setValue:[NSNumber numberWithInt:status]
           forKey:@"connection_status"];
    [IAGap sendNotif:IA_GAP_EVENT_CONNECTION_STATUS_NOTIFICATION withInfo:msg];
  }
  @catch (NSException* exception)
  {
    ELLE_WARN("on_connection_status exception: %s", exception.reason.UTF8String);
  }
}

static void on_transaction(uint32_t const transaction_id, gap_TransactionStatus status)
{
  assert(transaction_id != gap_null());
  ELLE_DUMP("on_transaction: %d", transaction_id);
  @try
  {
    NSMutableDictionary* msg = [NSMutableDictionary dictionary];
    [msg setValue:[NSNumber numberWithUnsignedInt:transaction_id]
           forKey:@"transaction_id"];
    [msg setValue:[NSNumber numberWithInt:status]
           forKey:@"transaction_status"];
    [IAGap sendNotif:IA_GAP_EVENT_TRANSACTION_NOTIFICATION withInfo:msg];
  }
  @catch (NSException* exception)
  {
    ELLE_WARN("on_transaction exception: %s", exception.reason.UTF8String);
  }
}

static void on_error_callback(gap_Status errcode, char const* reason, uint32_t const transaction_id)
{
  ELLE_TRACE("on_error_callback: %d", transaction_id);
  @try
  {
    NSMutableDictionary* msg = [[NSMutableDictionary alloc] init];
    if (transaction_id != 0)
    {
      [msg setValue:[NSNumber numberWithUnsignedInt:transaction_id]
             forKey:@"transaction_id"];
    }
    [msg setObject:[NSString stringWithUTF8String:reason]
            forKey:@"reason"];
    
    [msg setObject:[NSNumber numberWithInt:errcode]
            forKey:@"error_code"];
    [IAGap sendNotif:IA_GAP_EVENT_ERROR withInfo:msg];
  }
  @catch (NSException* exception)
  {
    ELLE_WARN("on_error_callback exception: %s", exception.reason.UTF8String);
  }
}

static void on_kicked_out()
{
  ELLE_TRACE("on_kicked_out");
  // Set not logged in and stop polling
  clear_model();
  [IAGap sendNotif:IA_GAP_EVENT_KICKED_OUT withInfo:nil];
}

static void on_trophonius_unavailable()
{
  // This is currently the same as a kick out
  ELLE_DEBUG("on_trophonius_unavailable");
  [IAGap sendNotif:IA_GAP_EVENT_TROPHONIUS_UNAVAILABLE withInfo:nil];
}

static void on_received_avatar(uint32_t const user_id)
{
  ELLE_DUMP("on_received_avatar: %d", user_id);
  @try
  {
    NSMutableDictionary* msg = [[NSMutableDictionary alloc] init];
    if (user_id != 0)
    {
      [msg setValue:[NSNumber numberWithUnsignedInt:user_id]
             forKey:@"user_id"];
    }
    [IAGap sendNotif:IA_GAP_EVENT_USER_AVATAR_NOTIFICATION withInfo:msg];
  }
  @catch (NSException* exception)
  {
    ELLE_WARN("on_received_avatar exception: %s", exception.reason.UTF8String);
  }
}

