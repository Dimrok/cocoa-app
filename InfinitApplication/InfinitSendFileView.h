//
//  InfinitSendFileView.h
//  InfinitApplication
//
//  Created by Christopher Crone on 14/10/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//- Single File View -------------------------------------------------------------------------------

@interface InfinitSendFileView : NSView

@property (nonatomic, weak, readwrite) NSButton* icon_button;
@property (nonatomic, weak, readwrite) NSButton* remove_button;

@property (nonatomic, readwrite) BOOL add_files_placeholder;

@end
