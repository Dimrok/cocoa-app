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

@interface InfinitSettingsGeneralView : InfinitSettingsViewController

@property (nonatomic, weak) IBOutlet NSButton* launch_at_startup;
@property (nonatomic, weak) IBOutlet NSButton* upload_screenshots;

- (id)initWithDelegate:(id<InfinitSettingsGeneralProtocol>)delegate;

@end

@protocol InfinitSettingsGeneralProtocol <NSObject>

- (BOOL)infinitInLoginItems:(InfinitSettingsGeneralView*)sender;
- (void)setInfinitInLoginItems:(InfinitSettingsGeneralView*)sender
                            to:(BOOL)value;

- (BOOL)uploadsScreenshots:(InfinitSettingsGeneralView*)sender;
- (void)setUploadsScreenshots:(InfinitSettingsGeneralView*)sender
                           to:(BOOL)value;

@end
