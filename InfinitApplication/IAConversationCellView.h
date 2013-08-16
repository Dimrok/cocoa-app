//
//  IAConversationCellView.h
//  InfinitApplication
//
//  Created by Christopher Crone on 8/15/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface IAConversationCellView : NSTableCellView <NSTableViewDataSource,
                                                     NSTableViewDelegate>

@property (nonatomic, strong) IBOutlet NSTextField* date;
@property (nonatomic, strong) IBOutlet NSButton* files_icon;
@property (nonatomic, strong) IBOutlet NSTextField* files_label;
@property (nonatomic, strong) IBOutlet NSButton* message_button;
@property (nonatomic, strong) IBOutlet NSTableView* table_view;

- (void)setupCellWithTransaction:(IATransaction*)transaction;

@end
