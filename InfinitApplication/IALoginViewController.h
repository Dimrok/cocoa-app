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
{
@private
    id<IALoginViewControllerProtocol> _delegate;
    NSWindow* _window;
}

@property (nonatomic, strong) IBOutlet NSTextField* create_account_link;
@property (nonatomic, strong) IBOutlet NSTextField* email_address;
@property (nonatomic, strong) IBOutlet NSTextField* fogot_password_link;
@property (nonatomic, strong) IBOutlet IALoginView* login_view;
@property (nonatomic, strong) IBOutlet NSTextField* password;

- (id)initWithDelegate:(id<IALoginViewControllerProtocol>)delegate;
- (void)showLoginWindowOnScreen:(NSScreen*)screen;

@end

@protocol IALoginViewControllerProtocol <NSObject>

@end
