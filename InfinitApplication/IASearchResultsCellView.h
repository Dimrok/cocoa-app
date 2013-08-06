//
//  IASearchResultsCellView.h
//  InfinitApplication
//
//  Created by Christopher Crone on 8/4/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface IASearchResultsCellView : NSTableCellView

@property (nonatomic, strong) IBOutlet NSImageView* result_avatar;
@property (nonatomic, strong) IBOutlet NSTextField* result_fullname;
@property (nonatomic, strong) IBOutlet NSButton* result_star;

- (void)setUserFullname:(NSString*)fullname;
- (void)setUserAvatar:(NSImage*)image;
- (void)setUserFavourite:(BOOL)favourite;

@end
