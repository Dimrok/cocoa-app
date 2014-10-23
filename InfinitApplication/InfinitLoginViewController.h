//
//  InfinitLoginViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 31/10/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAHoverButton.h"
#import "IAViewController.h"

typedef enum __InfinitLoginViewMode
{
  INFINIT_LOGIN_VIEW_REGISTER,
  INFINIT_LOGIN_VIEW_NOT_LOGGED_IN,
  INFINIT_LOGIN_VIEW_NOT_LOGGED_IN_WITH_CREDENTIALS,
} InfinitLoginViewMode;

@class InfinitLoginView;
@interface InfinitLoginButtonCell : NSButtonCell
@property (nonatomic, readwrite) NSDictionary* disabled_attrs;
@end

@protocol InfinitLoginViewControllerProtocol;

@interface InfinitLoginViewController : IAViewController

@property (nonatomic, weak) IBOutlet NSButton* action_button;
@property (nonatomic, weak) IBOutlet NSTextField* action_text;
@property (nonatomic, weak) IBOutlet IAHoverButton* close_button;
@property (nonatomic, weak) IBOutlet NSTextField* email_address;
@property (nonatomic, weak) IBOutlet NSTextField* error_message;
@property (nonatomic, weak) IBOutlet NSTextField* fullname;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* fullname_pos;
@property (nonatomic, weak) IBOutlet IAHoverButton* got_account;
@property (nonatomic, weak) IBOutlet IAHoverButton* help_button;
@property (nonatomic, weak) IBOutlet NSTextField* password;
@property (nonatomic, weak) IBOutlet IAHoverButton* problem_button;
@property (nonatomic, readwrite) BOOL running;
@property (nonatomic, weak) IBOutlet NSProgressIndicator* spinner;
@property (nonatomic, weak) IBOutlet NSTextField* version;

@property (nonatomic, readwrite) InfinitLoginViewMode mode;

- (id)initWithDelegate:(id<InfinitLoginViewControllerProtocol>)delegate
              withMode:(InfinitLoginViewMode)mode;

- (void)showWithError:(NSString*)error
             username:(NSString*)username
          andPassword:(NSString*)password;

@end

@protocol InfinitLoginViewControllerProtocol <NSObject>

- (void)registered:(InfinitLoginViewController*)sender
         withEmail:(NSString*)email;

- (void)alreadyLoggedIn:(InfinitLoginViewController*)sender;

- (void)tryLogin:(InfinitLoginViewController*)sender
        username:(NSString*)username
        password:(NSString*)password;

- (void)loginViewWantsClose:(InfinitLoginViewController*)sender;

- (void)loginViewWantsCloseAndQuit:(InfinitLoginViewController*)sender;

- (void)loginViewWantsReportProblem:(InfinitLoginViewController*)sender;

- (void)loginViewWantsCheckForUpdate:(InfinitLoginViewController*)sender;

@end
