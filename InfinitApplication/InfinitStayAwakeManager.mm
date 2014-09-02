//
//  InfinitStayAwakeManager.m
//  InfinitApplication
//
//  Created by Christopher Crone on 18/12/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//
// https://developer.apple.com/library/mac/qa/qa1340/_index.html

#import "InfinitStayAwakeManager.h"
#import "IAUserPrefs.h"

#import <ctype.h>
#import <stdlib.h>
#import <stdio.h>

#import <mach/mach_port.h>
#import <mach/mach_interface.h>
#import <mach/mach_init.h>

#import <IOKit/ps/IOPowerSources.h>
#import <IOKit/pwr_mgt/IOPMLib.h>
#import <IOKit/IOMessage.h>

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("OSX.StayAwakeManager");

// WORKAROUND: kIOPMACPowerKey is referenced in the public headers but it's not defined
#ifndef kIOPMACPowerKey
# define kIOPMACPowerKey "AC Power"
#endif

static InfinitStayAwakeManager* _instance = nil;

static io_connect_t _root_port;
static IONotificationPortRef _notify_port_ref;
static io_object_t _notifier_object;
static void* _ref_con;

@implementation InfinitStayAwakeManager
{
@private
  __weak id<InfinitStayAwakeProtocol> _delegate;
  BOOL _stay_awake;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithDelegate:(id<InfinitStayAwakeProtocol>)delegate
{
  if (self = [super init])
  {
    _ref_con = NULL;
    _delegate = delegate;
    [self registerForPowerEvents];

    if ([[IAUserPrefs sharedInstance] prefsForKey:@"stay_awake"] == nil)
    {
      [[IAUserPrefs sharedInstance] setPref:@"1" forKey:@"stay_awake"];
      _stay_awake = YES;
    }
    else if ([[[IAUserPrefs sharedInstance] prefsForKey:@"stay_awake"] isEqualToString:@"1"])
    {
      _stay_awake = YES;
    }
    else
    {
      _stay_awake = NO;
    }
  }
  return self;
}

+ (InfinitStayAwakeManager*)setUpInstanceWithDelegate:(id<InfinitStayAwakeProtocol>)delegate
{
  if (_instance == nil)
  {
    _instance = [[InfinitStayAwakeManager alloc] initWithDelegate:delegate];
  }
  return _instance;
}

+ (InfinitStayAwakeManager*)instance
{
  return _instance;
}

- (BOOL)_stayAwake
{
  return _stay_awake;
}

+ (BOOL)stayAwake
{
  return [[InfinitStayAwakeManager instance] _stayAwake];
}

- (void)_setStayAwake:(BOOL)stay_awake
{
  _stay_awake = stay_awake;
  NSString* value = [NSString stringWithFormat:@"%d", _stay_awake];
  [[IAUserPrefs sharedInstance] setPref:value forKey:@"stay_awake"];
}

+ (void)setStayAwake:(BOOL)stay_awake
{
  [[InfinitStayAwakeManager instance] _setStayAwake:stay_awake];
}

- (BOOL)_preventSleep
{
  if (!_stay_awake)
    return NO;

  BOOL running_transfers = [_delegate stayAwakeManagerWantsActiveTransactions:self];

  if (!running_transfers)
    return NO;

  CFStringRef power_source = IOPSGetProvidingPowerSourceType(NULL);
  if (CFStringCompare(power_source, CFSTR(kIOPMACPowerKey), 0) == 0)
    return YES;

  return NO;
}

+ (BOOL)preventSleep
{
  return [_instance _preventSleep];
}

static
void
c_sleep_callback(void* ref_con,
                 io_service_t service,
                 natural_t message_type,
                 void* message_argument)
{
  switch (message_type)
  {
    case kIOMessageCanSystemSleep:
      // Idle sleep about to kick in
      if ([InfinitStayAwakeManager preventSleep])
      {
        ELLE_LOG("preventing computer sleep");
        IOCancelPowerChange(_root_port, (long)message_argument);
      }
      else
      {
        ELLE_LOG("allowing computer sleep");
        IOAllowPowerChange(_root_port, (long)message_argument);
      }
      break;

    case kIOMessageSystemWillSleep:
      // System will go to sleep
      IOAllowPowerChange(_root_port, (long)message_argument);
      break;

    case kIOMessageSystemWillPowerOn:
      // System has started the wake up process
      break;

    case kIOMessageSystemHasPoweredOn:
      // System has finished waking up
      break;

    default:
      break;
  }
}

- (void)registerForPowerEvents
{
  _root_port = IORegisterForSystemPower(_ref_con,
                                        &_notify_port_ref,
                                        c_sleep_callback,
                                        &_notifier_object);
  if (_root_port == 0)
  {
    ELLE_WARN("%s: IORegisterForSystemPower failed", self.description.UTF8String);
  }

  CFRunLoopAddSource(CFRunLoopGetCurrent(),
                     IONotificationPortGetRunLoopSource(_notify_port_ref),
                     kCFRunLoopCommonModes);
}

- (void)unregisterForPowerEvents
{
  CFRunLoopRemoveSource(CFRunLoopGetCurrent(),
                        IONotificationPortGetRunLoopSource(_notify_port_ref),
                        kCFRunLoopCommonModes);
  IODeregisterForSystemPower(&_notifier_object);
  IOServiceClose(_root_port);
  IONotificationPortDestroy(_notify_port_ref);
}

- (void)dealloc
{
  [self unregisterForPowerEvents];
}

@end
