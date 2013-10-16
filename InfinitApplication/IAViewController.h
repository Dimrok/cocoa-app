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

@interface IAFooterView : NSView
@end

@interface IAHeaderView : NSView
@end

@interface IAMainView : NSView
@end

@interface IAViewController : NSViewController

@property (nonatomic, retain) IBOutlet NSLayoutConstraint* content_height_constraint;
@property (nonatomic, retain) IBOutlet NSLayoutConstraint* content_width_constraint;
@property (nonatomic, retain) IBOutlet IAFooterView* footer_view;
@property (nonatomic, retain) IBOutlet IAHeaderView* header_view;
@property (nonatomic, retain) IBOutlet IAMainView* main_view;

- (BOOL)closeOnFocusLost;

- (void)aboutToChangeView;

- (void)transactionAdded:(IATransaction*)transaction;
- (void)transactionUpdated:(IATransaction*)transaction;
- (void)userUpdated:(IAUser*)user;

@end
