//
//  IAFWKeychain.h
//  FinderWindow
//
//  Created by Christopher Crone on 3/21/13.
//  Copyright (c) 2013 infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IAKeychainManager : NSObject

+ (IAKeychainManager*)sharedInstance;

- (OSStatus)getPasswordKeychain:(NSString*)user_email
                   passwordData:(void**)password_data
                 passwordLength:(UInt32*)password_length
                        itemRef:(SecKeychainItemRef*)item_ref;

- (BOOL)credentialsInKeychain:(NSString*)email_address;

- (OSStatus)addPasswordKeychain:(NSString*)user_email
                       password:(NSString*)password;

@end