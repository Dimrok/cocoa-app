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

@property (nonatomic, strong) IBOutlet NSTableView* table_view;

- (id)initWithDelegate:(id<InfinitLinkViewProtocol>)delegate
           andLinkList:(NSArray*)list
         andSelfStatus:(gap_UserStatus)status;

@property (nonatomic, readwrite) BOOL changing;

- (void)updateModelWithList:(NSArray*)list;

- (void)linkAdded:(InfinitLinkTransaction*)link;
- (void)linkUpdated:(InfinitLinkTransaction*)link;

- (NSUInteger)linksRunning;

- (CGFloat)height;

- (void)selfStatusChanged:(gap_UserStatus)status;

@end

@protocol InfinitLinkViewProtocol <NSObject>

- (void)copyLinkToPasteBoard:(InfinitLinkTransaction*)link;
- (void)linksViewResizeToHeight:(CGFloat)height;

@end
