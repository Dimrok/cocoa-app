//
//  InfinitSettingsAccountView.h
//  InfinitApplication
//
//  Created by Christopher Crone on 21/08/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "InfinitSettingsViewController.h"
#import "InfinitSettingsAvatarView.h"

@protocol InfinitSettingsAccountProtocol;

@interface InfinitSettingsAccountView : InfinitSettingsViewController <NSTextFieldDelegate,
                                                                       InfinitSettingsAvatarProtocol>

@property (nonatomic, weak) IBOutlet InfinitSettingsAvatarView* avatar;
@property (nonatomic, weak) IBOutlet NSTextField* name;
@property (nonatomic, weak) IBOutlet NSTextField* handle;
@property (nonatomic, weak) IBOutlet NSTextField* email;

@property (nonatomic, weak) IBOutlet NSButton* change_avatar;
@property (nonatomic, weak) IBOutlet NSButton* change_email;
@property (nonatomic, weak) IBOutlet NSButton* change_password;

@property (nonatomic, weak) IBOutlet NSButton* save_avatar;
@property (nonatomic, weak) IBOutlet NSButton* save_fullname;
@property (nonatomic, weak) IBOutlet NSButton* save_handle;

@property (nonatomic, weak) IBOutlet NSProgressIndicator* avatar_progress;
@property (nonatomic, weak) IBOutlet NSProgressIndicator* fullname_progress;
@property (nonatomic, weak) IBOutlet NSProgressIndicator* handle_progress;

@property (nonatomic, weak) IBOutlet NSImageView* fullname_check;
@property (nonatomic, weak) IBOutlet NSImageView* handle_check;

@property (nonatomic, weak) IBOutlet NSTextField* handle_error;

// Change email panel
@property (nonatomic, weak) IBOutlet NSPanel* change_email_panel;
@property (nonatomic, weak) IBOutlet NSTextField* change_email_field;
@property (nonatomic, weak) IBOutlet NSSecureTextField* change_email_password;
@property (nonatomic, weak) IBOutlet NSTextField* change_email_error;
@property (nonatomic, weak) IBOutlet NSButton* cancel_change_email;
@property (nonatomic, weak) IBOutlet NSButton* confirm_change_email;
@property (nonatomic, weak) IBOutlet NSProgressIndicator* change_email_progress;

// Changed email panel
@property (nonatomic, weak) IBOutlet NSPanel* changed_email_panel;

// Change password panel
@property (nonatomic, weak) IBOutlet NSPanel* change_password_panel;
@property (nonatomic, weak) IBOutlet NSSecureTextField* old_password_field;
@property (nonatomic, weak) IBOutlet NSSecureTextField* change_password_field;
@property (nonatomic, weak) IBOutlet NSTextField* password_error;
@property (nonatomic, weak) IBOutlet NSButton* confirm_change_password;
@property (nonatomic, weak) IBOutlet NSProgressIndicator* change_password_progress;


- (id)initWithDelegate:(id<InfinitSettingsAccountProtocol>)delegate;

@end

@protocol InfinitSettingsAccountProtocol <NSObject>

- (NSWindow*)getWindow:(InfinitSettingsAccountView*)sender;

@end
