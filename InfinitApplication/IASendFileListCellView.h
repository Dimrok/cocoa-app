//
//  IASendFileListCellView.h
//  InfinitApplication
//
//  Created by Christopher Crone on 8/5/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface IASendFileListCellView : NSTableCellView

@property (nonatomic, strong) IBOutlet NSButton* file_icon_and_name;
@property (nonatomic, strong) IBOutlet NSTextField* file_size;
@property (nonatomic, strong) IBOutlet NSButton* remove_file_button;

- (void)setupCellWithFilePath:(NSString*)file_path;

@end
