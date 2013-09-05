//
//  IABottomButton.h
//  InfinitApplication
//
//  Created by Christopher Crone on 9/4/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface IABottomButton : NSButton

@property(nonatomic, readwrite) BOOL enabled;

- (BOOL)isEnabled;

@end
