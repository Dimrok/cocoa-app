//
//  InfinitLinkCellView.h
//  InfinitApplication
//
//  Created by Christopher Crone on 13/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <Gap/InfinitLinkTransaction.h>

#import "IAHoverButton.h"
#import "InfinitLinkProgressIndicator.h"
#import "InfinitLinkClickCountView.h"
#import "InfinitLinkFileIconView.h"

@interface InfinitLinkCellView : NSTableCellView

@property (nonatomic, strong) IBOutlet InfinitLinkFileIconView* icon_view;
@property (nonatomic, strong) IBOutlet NSTextField* name;
@property (nonatomic, strong) IBOutlet NSTextField* information;
@property (nonatomic, strong) IBOutlet InfinitLinkClickCountView* click_count;
@property (nonatomic, strong) IBOutlet IAHoverButton* link;
@property (nonatomic, strong) IBOutlet IAHoverButton* clipboard;
@property (nonatomic, strong) IBOutlet InfinitLinkProgressIndicator* progress_indicator;

@property (nonatomic, readwrite) CGFloat progress;

- (void)setupCellWithLink:(InfinitLinkTransaction*)link;

@end
