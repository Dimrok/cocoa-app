//
//  InfinitStartupMessageController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 15/11/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@protocol InfinitStartupMessageControllerProtocol;

@interface InfinitStartupMessageController : NSWindowController

@property (nonatomic, strong) IBOutlet NSButton* quit_button;
@property (nonatomic, strong) IBOutlet WebView* web_view;

- (id)initWithDelegate:(id<InfinitStartupMessageControllerProtocol>)delegate;

- (BOOL)metaStatusGood;

- (void)showStartupMessage;

@end


@protocol InfinitStartupMessageControllerProtocol <NSObject>

- (void)startupMessageControllerWantsQuit:(InfinitStartupMessageController*)sender;

@end