//
//  IASearchResultsViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 8/4/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface IASearchResultsViewController : NSViewController <NSTableViewDataSource,
                                                             NSTableViewDelegate>

@property (nonatomic, strong) IBOutlet NSTableView* table_view;

@end
