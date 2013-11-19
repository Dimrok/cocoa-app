//
//  InfinitServerTestController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 15/11/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

typedef enum __InfinitServerStatus
{
    INFINIT_SERVER_STATUS_UNKOWN = 0,
    INFINIT_SERVER_UNREACHABLE = 1,
    INFINIT_SERVER_DOWN_WITH_MESSAGE = 2,
    INFINIT_SERVER_UP = 3,
} InfinitServerStatus;

@protocol InfinitServerTestControllerProtocol;

@interface InfinitServerTestController : NSWindowController <NSStreamDelegate>

@property (nonatomic, strong) IBOutlet NSButton* quit_button;
@property (nonatomic, strong) IBOutlet WebView* web_view;

- (id)initWithDelegate:(id<InfinitServerTestControllerProtocol>)delegate;

- (InfinitServerStatus)metaStatus;

- (void)fetchTrophoniusStatus;

- (void)showMetaMessage;

- (void)showTrophoniusMessage;

@end


@protocol InfinitServerTestControllerProtocol <NSObject>

- (void)serverTestControllerWantsQuit:(InfinitServerTestController*)sender;

- (void)serverTestControllerHasTrophoniusStatus:(InfinitServerTestController*)sender
                                         status:(InfinitServerStatus)status;

@end