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

@property (nonatomic, strong) IBOutlet NSImageView* loading_icon;
@property (nonatomic, strong) IBOutlet NSTextField* message;
@property (nonatomic, strong) IBOutlet NSTextField* no_connection;
@property (nonatomic, strong) IBOutlet IAHoverButton* problem_button;

- (void)setHeaderStr:(NSString*)str;

- (void)setMessageStr:(NSString*)str;

- (void)setUpCell;

@end
