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

- (void)reportProblemControllerDone:(IAReportProblemWindowController*)sender;

@end