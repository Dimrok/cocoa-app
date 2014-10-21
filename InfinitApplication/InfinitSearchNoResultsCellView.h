//
//  InfinitSearchNoResultsCellView.h
//  InfinitApplication
//
//  Created by Christopher Crone on 15/10/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface InfinitSearchInfinitView : NSView
@property (nonatomic, readwrite) CGFloat hover;
@end

@protocol InfinitSearchNoResultsProcotol;

@interface InfinitSearchNoResultsCellView : NSTableCellView

@property (nonatomic, readwrite) id<InfinitSearchNoResultsProcotol> delegate;
@property (nonatomic, weak) IBOutlet NSTextField* no_results_msg;
@property (nonatomic, weak) IBOutlet InfinitSearchInfinitView* search_infinit_view;
@property (nonatomic, weak) IBOutlet NSTextField* search_infinit_msg;
@property (nonatomic, readwrite) NSString* search_string;
@property (nonatomic, weak) IBOutlet NSProgressIndicator* spinner;

- (void)gotWantsSearchInfinit;

@end

@protocol InfinitSearchNoResultsProcotol

- (void)cellWantsSearchInfinit:(InfinitSearchNoResultsCellView*)sender;

@end
