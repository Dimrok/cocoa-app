//
//  InfinitLoginViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 31/10/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IABottomButton.h"
#import "IAHoverButton.h"
#import "IAViewController.h"

typedef enum __InfinitLoginViewMode
{
    LOGIN_VIEW_NOT_LOGGED_IN = 0,
    LOGIN_VIEW_NOT_LOGGED_IN_WITH_CREDENTIALS = 1,
    LOGIN_VIEW_LOGGING_IN = 2,
} InfinitLoginViewMode;

@class InfinitLoginView;

@protocol InfinitLoginViewControllerProtocol;

@interface InfinitLoginViewController : IAViewController

@property (nonatomic, strong) IBOutlet IAHoverButton* close_button;
@property (nonatomic, strong) IBOutlet IAHoverButton* create_account_button;
@property (nonatomic, strong) IBOutlet NSTextField* email_address;
@property (nonatomic, strong) IBOutlet NSTextField* error_message;
@property (nonatomic, strong) IBOutlet IAHoverButton* forgot_password_button;
@property (nonatomic, strong) IBOutlet IABottomButton* login_button;
@property (nonatomic, readwrite, setter = setLoginViewMode:) InfinitLoginViewMode mode;
@property (nonatomic, strong) IBOutlet NSTextField* password;
@property (nonatomic, strong) IBOutlet NSProgressIndicator* spinner;

- (id)initWithDelegate:(id<InfinitLoginViewControllerProtocol>)delegate
              withMode:(InfinitLoginViewMode)mode;

- (void)setLoginViewMode:(InfinitLoginViewMode)mode;

- (void)showWithError:(NSString*)error
             username:(NSString*)username
          andPassword:(NSString*)password;

@end

@protocol InfinitLoginViewControllerProtocol <NSObject>
- (void)tryLogin:(InfinitLoginViewController*)sender
        username:(NSString*)username
        password:(NSString*)password;

- (void)loginViewWantsClose:(InfinitLoginViewController*)sender;

- (void)loginViewWantsCloseAndQuit:(InfinitLoginViewController*)sender;

@end
