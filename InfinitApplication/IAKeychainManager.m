//
//  IAFWKeychain.m
//  FinderWindow
//
//  Created by Christopher Crone on 3/21/13.
//  Copyright (c) 2013 infinit. All rights reserved.
//
// This library makes use of older Keychain functions as they provide more flexibility. Notably,
// when Infinit injected code into the Finder, Keychain permissions had to be set for the Infinit
// application from the Finder.

#import <Security/Security.h>

#import <Gap/IAGapState.h>
#import "IAKeychainManager.h"

@implementation IAKeychainManager
{
@private
  NSString* _service_name;
  NSString* _application_path;
}

//- Initialisation ---------------------------------------------------------------------------------

+ (IAKeychainManager*)sharedInstance
{
	static IAKeychainManager* keychain_manager = nil;
	if (keychain_manager == nil)
  {
		keychain_manager = [[IAKeychainManager alloc] init];
  }
  return keychain_manager;
}

- (id)init
{
	if (self = [super init])
  {
    _service_name = @"Infinit";
    _application_path = [IAGapState.instance.protocol getApplicationPath];

  }
	return self;
}

//- General Functions ------------------------------------------------------------------------------

// Call SecKeychainFindGenericPassword to get a password from the keychain
// Making use of older, Keychain API as it is more flexible. See top of file.
- (OSStatus)getPasswordKeychain:(NSString*)user_email
                   passwordData:(void**)password_data
                 passwordLength:(UInt32*)password_length
                        itemRef:(SecKeychainItemRef*)item_ref
{
  OSStatus status;

  status = SecKeychainFindGenericPassword(
    NULL, // default keychain
    (UInt32)_service_name.length, // length of service name
    _service_name.UTF8String,     // service name
    (UInt32)user_email.length,    // length of account name
    user_email.UTF8String,        // account name
    password_length,              // length of password
    password_data,                // pointer to password data
    item_ref                      // the item reference
  );

  return status;
}

// Check if credentials are in keychain
- (BOOL)credentialsInKeychain:(NSString*)email_address
{
  if ([self getPasswordKeychain:email_address
                   passwordData:NULL
                 passwordLength:NULL
                        itemRef:NULL] == noErr)
  {
    return YES;
  }
  else
  {
    return NO;
  }
}

// Update user's password in keychain
- (OSStatus)changeUser:(NSString*)user_email
              password:(NSString*)password
{
  OSStatus status = noErr;
  SecKeychainItemRef item_ref = NULL;

  status = [self getPasswordKeychain:user_email
                        passwordData:NULL
                      passwordLength:0
                             itemRef:&item_ref];
  if (status != noErr)
    return status;

  status = SecKeychainItemModifyContent(item_ref,
                                        NULL,
                                        (UInt32)password.length,
                                        password.UTF8String);
  password = @"";
  password = nil;
  return status;
}

// Add credentials to keychain
// Making use of older, Keychain API as it is more flexible. See top of file.
- (OSStatus)addPasswordKeychain:(NSString*)user_email
                       password:(NSString*)password
{
  OSStatus status;
  SecAccessRef access;
  NSArray* trusted_applications = nil;

  SecTrustedApplicationRef infinit_app;
  status = SecTrustedApplicationCreateFromPath(_application_path.UTF8String, &infinit_app);
  if (status != noErr)
    return status;

  trusted_applications = [NSArray arrayWithObject:(__bridge id)infinit_app];

  status = SecAccessCreate((__bridge CFStringRef)_service_name,
                           (__bridge CFArrayRef)(trusted_applications),
                           &access);
  if (status != noErr)
    return status;

  SecKeychainAttribute attrs[] = {
    { kSecLabelItemAttr, (UInt32)_service_name.length, (void*)_service_name.UTF8String },
    { kSecAccountItemAttr, (UInt32)user_email.length, (void*)user_email.UTF8String },
    { kSecServiceItemAttr, (UInt32)_service_name.length, (void*)_service_name.UTF8String }
  };

  SecKeychainAttributeList attributes = { sizeof(attrs) / sizeof(attrs[0]), attrs };

  status = SecKeychainItemCreateFromContent(
                                            kSecGenericPasswordItemClass,
                                            &attributes,
                                            (UInt32)password.length,
                                            password.UTF8String,
                                            NULL, // use the default keychain
                                            access,
                                            NULL
                                            );
  if (access)
    CFRelease(access);
  password = @"";
  password = nil;
  return status;
}

@end
