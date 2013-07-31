//
//  IALoginViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 7/29/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface IALoginWindow : NSWindow
@end

@class IALoginView;

@protocol IALoginViewControllerProtocol;

@interface IALoginViewController : NSViewController <NSTextFieldDelegate,
                                                     NSWindowDelegate>

@property (nonatomic, strong) IBOutlet NSTextField* create_account_link;
@property (nonatomic, strong) IBOutlet NSTextField* email_address;
@property (nonatomic, strong) IBOutlet NSTextField* error_message;
@property (nonatomic, strong) IBOutlet NSTextField* fogot_password_link;
@property (nonatomic, strong) IBOutlet NSButton* login_button;
@property (nonatomic, strong) IBOutlet IALoginView* login_view;
@property (nonatomic, strong) IBOutlet NSTextField* password;

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
