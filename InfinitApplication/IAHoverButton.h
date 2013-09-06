//
//  IAHoverButton.h
//  InfinitApplication
//
//  Created by Christopher Crone on 9/6/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface IAHoverButton : NSButton

@property (nonatomic, strong) NSImage* hoverImage;

- (void)setHoverImage:(NSImage*)hoverImage;

- (void)setHoverTextAttributes:(NSDictionary*)attrs;
- (void)setNormalTextAttributes:(NSDictionary*)attrs;

@end
