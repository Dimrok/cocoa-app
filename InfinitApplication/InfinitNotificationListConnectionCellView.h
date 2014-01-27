//
//  InfinitNotificationListConnectionCellView.h
//  InfinitApplication
//
//  Created by Christopher Crone on 17/12/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IAHoverButton.h"

@interface InfinitNotificationListConnectionCellView : NSTableCellView

@property (nonatomic, strong) IBOutlet NSProgressIndicator* loading_indicator;
@property (nonatomic, strong) IBOutlet NSTextField* message;
@property (nonatomic, strong) IBOutlet IAHoverButton* problem_button;

- (void)setMessageStr:(NSString*)str;

- (void)setUpCell;

@end
