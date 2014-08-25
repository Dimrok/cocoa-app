//
//  InfinitSettingsWindow.h
//  InfinitApplication
//
//  Created by Christopher Crone on 21/08/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "InfinitSettingsAccountView.h"
#import "InfinitSettingsGeneralView.h"

@protocol InfinitSettingsProtocol;

@interface InfinitSettingsWindow : NSWindowController <InfinitSettingsAccountProtocol,
                                                       InfinitSettingsGeneralProtocol>

@property (nonatomic, weak) IBOutlet NSToolbarItem* account_button;
@property (nonatomic, weak) IBOutlet NSToolbarItem* general_button;
@property (nonatomic, weak) IBOutlet NSToolbar* toolbar;

- (id)initWithDelegate:(id<InfinitSettingsProtocol>)delegate;

- (void)show;
- (void)close;

@end

@protocol InfinitSettingsProtocol <NSObject>

- (BOOL)infinitInLoginItems:(InfinitSettingsWindow*)sender;
- (void)setInfinitInLoginItems:(InfinitSettingsWindow*)sender
                            to:(BOOL)value;

- (BOOL)uploadsScreenshots:(InfinitSettingsWindow*)sender;
- (void)setUploadsScreenshots:(InfinitSettingsWindow*)sender
                           to:(BOOL)value;

@end
