//
//  InfinitLoginButton.h
//  InfinitApplication
//
//  Created by Christopher Crone on 19/03/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class InfinitLoginButtonCell;

@interface InfinitLoginButton : NSButton

@property (nonatomic, readwrite) NSColor* color;
@property (nonatomic, readwrite) NSString* text;

@end
