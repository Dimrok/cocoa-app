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

- (id)initWithDelegate:(id<InfinitSettingsGeneralProtocol>)delegate;

@end

@protocol InfinitSettingsGeneralProtocol <NSObject>

- (BOOL)infinitInLoginItems:(InfinitSettingsGeneralView*)sender;
- (void)setInfinitInLoginItems:(InfinitSettingsGeneralView*)sender
                            to:(BOOL)value;

- (BOOL)stayAwake:(InfinitSettingsGeneralView*)sender;
- (void)setStayAwake:(InfinitSettingsGeneralView*)sender
                  to:(BOOL)value;

- (void)checkForUpdate:(InfinitSettingsGeneralView*)sender;

@end
