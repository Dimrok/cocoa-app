//
//  InfinitSendFileListCellView.h
//  InfinitApplication
//
//  Created by Christopher Crone on 24/12/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface InfinitSendFileListCellView : NSTableCellView

@property (nonatomic, strong) IBOutlet NSButton* file_icon_and_name;
@property (nonatomic, strong) IBOutlet NSTextField* file_size;
@property (nonatomic, strong) IBOutlet NSButton* remove_file_button;

- (void)setupCellWithFilePath:(NSString*)file_path;

@end
