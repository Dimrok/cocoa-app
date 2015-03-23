//
//  InfinitFacebookWidowController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 19/03/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define kInfinitFacebookAccessKey @"access_token"
#define kInfinitFacebookErrorKey  @"error"

@protocol InfinitFacebookWindowProtocol;

@interface InfinitFacebookWindowController : NSWindowController

- (instancetype)initWithDelegate:(id<InfinitFacebookWindowProtocol>)delegate;

@end

@protocol InfinitFacebookWindowProtocol <NSObject>

- (void)facebookWindow:(InfinitFacebookWindowController*)sender gotError:(NSString*)error;
- (void)facebookWindow:(InfinitFacebookWindowController*)sender gotToken:(NSString*)token;

@end
