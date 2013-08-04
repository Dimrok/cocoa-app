//
//  IASearchResultsViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 8/4/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol IASearchResultsViewProtocol;

@interface IASearchResultsViewController : NSViewController <NSTableViewDataSource,
                                                             NSTableViewDelegate>

@property (nonatomic, strong) IBOutlet NSTableView* table_view;

- (id)initWithDelegate:(id<IASearchResultsViewProtocol>)delegate;

- (void)searchForString:(NSString*)str;

@end

@protocol IASearchResultsViewProtocol <NSObject>

@end