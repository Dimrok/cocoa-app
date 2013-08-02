//
//  IAViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 7/31/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//
//  Each view shown in the notification window is made up of three parts:
//  1) A header view (the arrow pointing to the icon)
//  2) A main view (scrolling list of transactions or search, etc.)
//  3) A footer view (piece at the bottom with or without buttons)
//
//  This class abstracts this idea so that views can be passed to the window controller.

#import <Cocoa/Cocoa.h>

@interface IAViewController : NSViewController

@property (nonatomic, retain) IBOutlet NSView* footer_view;
@property (nonatomic, retain) IBOutlet NSView* header_view;
@property (nonatomic, retain) IBOutlet NSView* main_view;

@end
