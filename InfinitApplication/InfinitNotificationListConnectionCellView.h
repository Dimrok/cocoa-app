//
//  InfinitNotificationListConnectionCellView.h
//  InfinitApplication
//
//  Created by Christopher Crone on 17/12/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface InfinitNotificationListConnectionCellView : NSTableCellView

@property (nonatomic, strong) IBOutlet NSTextField* message;
@property (nonatomic, strong) IBOutlet NSTextField* no_connection;
@property (nonatomic, strong) IBOutlet NSImageView* loading_icon;

- (void)setHeaderStr:(NSString*)str;

- (void)setMessageStr:(NSString*)str;

@end
