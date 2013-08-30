//
//  IALoginViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 7/29/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//
//  This view controller is responsible for the login window.

#import <Cocoa/Cocoa.h>

@interface IALoginWindow : NSWindow
@end

@class IALoginView;

@protocol IALoginViewControllerProtocol;

@interface IALoginViewController : NSViewController <NSTextFieldDelegate,
                                                     NSWindowDelegate>

@property (nonatomic, strong) IBOutlet NSButton* close_button;
@property (nonatomic, strong) IBOutlet NSButton* create_account_button;
@property (nonatomic, strong) IBOutlet NSTextField* email_address;
@property (nonatomic, strong) IBOutlet NSTextField* error_message;
@property (nonatomic, strong) IBOutlet NSButton* forgot_password_button;
@property (nonatomic, strong) IBOutlet NSButton* login_button;
@property (nonatomic, strong) IBOutlet IALoginView* login_view;
@property (nonatomic, strong) IBOutlet NSTextField* password;
@property (nonatomic, strong) IBOutlet NSProgressIndicator* spinner;

- (id)initWithDelegate:(id<IALoginViewControllerProtocol>)delegate;

- (void)closeLoginWindow;
- (BOOL)loginWindowOpen;
- (void)showLoginWindowOnScreen:(NSScreen*)screen;
- (void)showLoginWindowOnScreen:(NSScreen*)screen withError:(NSString*)error;

@end

@protocol IALoginViewControllerProtocol <NSObject>
- (void)tryLogin:(IALoginViewController*)sender
        username:(NSString*)username
        password:(NSString*)password;
@end
