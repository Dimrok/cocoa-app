//
//  InfinitSettingsGeneralView.h
//  InfinitApplication
//
//  Created by Christopher Crone on 25/08/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "InfinitSettingsViewController.h"

@protocol InfinitSettingsGeneralProtocol;

@interface InfinitSettingsGeneralView : InfinitSettingsViewController <NSOpenSavePanelDelegate>

@property (nonatomic, weak) IBOutlet NSButton* launch_at_startup;
@property (nonatomic, weak) IBOutlet NSButton* stay_awake;
@property (nonatomic, weak) IBOutlet NSButton* upload_screenshots;
@property (nonatomic, weak) IBOutlet NSTextField* download_dir;

- (id)initWithDelegate:(id<InfinitSettingsGeneralProtocol>)delegate;

@end

@protocol InfinitSettingsGeneralProtocol <NSObject>

- (BOOL)infinitInLoginItems:(InfinitSettingsGeneralView*)sender;
- (void)setInfinitInLoginItems:(InfinitSettingsGeneralView*)sender
                            to:(BOOL)value;

- (BOOL)uploadsScreenshots:(InfinitSettingsGeneralView*)sender;
- (void)setUploadsScreenshots:(InfinitSettingsGeneralView*)sender
                           to:(BOOL)value;

- (BOOL)stayAwake:(InfinitSettingsGeneralView*)sender;
- (void)setStayAwake:(InfinitSettingsGeneralView*)sender
                  to:(BOOL)value;

- (void)checkForUpdate:(InfinitSettingsGeneralView*)sender;

@end
