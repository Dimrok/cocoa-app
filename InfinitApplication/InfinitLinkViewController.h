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
                                                         NSTableViewDelegate>

@property (nonatomic, strong) IBOutlet NSTableView* table_view;

- (id)initWithDelegate:(id<InfinitLinkViewProtocol>)delegate
           andLinkList:(NSArray*)list;

@property (nonatomic, readwrite) BOOL changing;

- (CGFloat)height;

@end

@protocol InfinitLinkViewProtocol <NSObject>

@end
