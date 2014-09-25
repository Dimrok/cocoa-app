//
//  InfinitProxyWindow.h
//  InfinitApplication
//
//  Created by Christopher Crone on 25/09/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol InfinitProxyWindowProtocol;

@interface InfinitProxyWindow : NSWindowController

@property (nonatomic, weak) IBOutlet NSTextField* host;
@property (nonatomic, weak) IBOutlet NSTextField* port;
@property (nonatomic, weak) IBOutlet NSButtonCell* type;
@property (nonatomic, weak) IBOutlet NSButton* requires_password;
@property (nonatomic, weak) IBOutlet NSTextField* username;
@property (nonatomic, weak) IBOutlet NSTextField* username_text;
@property (nonatomic, weak) IBOutlet NSSecureTextField* password;
@property (nonatomic, weak) IBOutlet NSTextField* password_text;

- (id)initWithDelegate:(id<InfinitProxyWindowProtocol>)delegate;

- (void)close;

- (void)setProxy:(NSString*)host
            port:(NSNumber*)port
            type:(NSString*)type
        username:(NSString*)username;

@end


@protocol InfinitProxyWindowProtocol <NSObject>

- (void)proxyWindow:(InfinitProxyWindow*)sender
            gotHost:(NSString*)host
               port:(NSNumber*)port
           username:(NSString*)username
           password:(NSString*)password;

- (void)proxyWindowGotCancel:(InfinitProxyWindow*)sender;

@end