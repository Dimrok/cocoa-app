//
//  IASearchResultsViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 8/4/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol IAUserSearchViewProtocol;

@interface IAUserSearchViewController : NSViewController <NSTableViewDataSource,
                                                          NSTableViewDelegate,
                                                          NSTextViewDelegate>

@property (nonatomic, strong) IBOutlet NSButton* clear_search;
@property (nonatomic, strong) IBOutlet NSTextField* search_field;
@property (nonatomic, strong) IBOutlet NSTableView* table_view;

- (id)initWithDelegate:(id<IAUserSearchViewProtocol>)delegate;

- (void)searchForString:(NSString*)str;

@end

@protocol IAUserSearchViewProtocol <NSObject>

@end