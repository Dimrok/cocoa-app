//
//  InfinitSettingsWindow.h
//  InfinitApplication
//
//  Created by Christopher Crone on 21/08/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol InfinitSettingsProtocol;

@interface InfinitSettingsWindow : NSWindowController

@property (nonatomic, weak) id<InfinitSettingsProtocol> delegate;

+ (instancetype)sharedInstance;

@end

@protocol InfinitSettingsProtocol <NSObject>

- (BOOL)infinitInLoginItems:(InfinitSettingsWindow*)sender;
- (void)setInfinitInLoginItems:(InfinitSettingsWindow*)sender
                            to:(BOOL)value;

- (BOOL)stayAwake:(InfinitSettingsWindow*)sender;
- (void)setStayAwake:(InfinitSettingsWindow*)sender
                  to:(BOOL)value;

- (void)checkForUpdate:(InfinitSettingsWindow*)sender;

@end
