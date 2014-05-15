//
//  InfinitMainCounterView.h
//  InfinitApplication
//
//  Created by Christopher Crone on 15/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface InfinitMainCounterView : NSView

@property (nonatomic, readwrite) BOOL highlighted;
@property (nonatomic, readwrite) NSUInteger count;

@end
