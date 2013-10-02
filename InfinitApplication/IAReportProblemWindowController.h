//
//  IAReportProblemWindowController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 10/2/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol IAReportProblemProtocol;

@interface IAReportProblemWindowController : NSWindowController <NSTextFieldDelegate>

@property (nonatomic, strong) IBOutlet NSTextField* file_message;
@property (nonatomic, strong) IBOutlet NSTextField* user_message;

- (id)initWithDelegate:(id<IAReportProblemProtocol>)delegate;

- (void)show;

- (void)close;

@end

@protocol IAReportProblemProtocol <NSObject>

- (void)reportProblemControllerWantsCancel:(IAReportProblemWindowController*)sender;

- (void)reportProblemController:(IAReportProblemWindowController*)sender
               wantsSendMessage:(NSString*)message
                        andFile:(NSString*)file_path;

@end