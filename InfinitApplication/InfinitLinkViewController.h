//
//  InfinitLinkViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 13/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "InfinitLinkCellView.h"

@protocol InfinitLinkViewProtocol;

@interface InfinitLinkViewController : NSViewController <NSTableViewDataSource,
                                                         NSTableViewDelegate,
                                                         InfinitLinkCellProtocol>

@property (nonatomic, weak) IBOutlet NSTableView* table_view;

- (id)initWithDelegate:(id<InfinitLinkViewProtocol>)delegate;

@property (nonatomic, readwrite) BOOL changing;

- (void)updateModel;

- (void)linkAdded:(InfinitLinkTransaction*)link;
- (void)linkUpdated:(InfinitLinkTransaction*)link;

- (NSUInteger)linksRunning;

- (CGFloat)height;

- (void)resizeComplete;

- (void)selfStatusChanged:(BOOL)status;

@end

@protocol InfinitLinkViewProtocol <NSObject>

- (void)copyLinkToPasteBoard:(InfinitLinkTransaction*)link;
- (void)linksViewResizeToHeight:(CGFloat)height;

@end
