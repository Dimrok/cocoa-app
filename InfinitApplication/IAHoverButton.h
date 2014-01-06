//
//  IAHoverButton.h
//  InfinitApplication
//
//  Created by Christopher Crone on 9/6/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface IAHoverButton : NSButton

@property (nonatomic) BOOL hand_cursor;
@property (nonatomic, setter = setHoverTextAttributes:) NSDictionary* hover_attrs;
@property (nonatomic, strong, setter = setHoverImage:) NSImage* hover_image;
@property (nonatomic, setter = setNormalTextAttributes:) NSDictionary* normal_attrs;
@property (nonatomic, strong, setter = setNormalImage:) NSImage* normal_image;

@end
