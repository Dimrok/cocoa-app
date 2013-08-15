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
                                                          NSTextViewDelegate,
                                                          NSTokenFieldDelegate>

@property (nonatomic, strong) IBOutlet NSView* search_box_view;
@property (nonatomic, strong) IBOutlet NSTokenField* search_field;
@property (nonatomic, strong) IBOutlet NSTableView* table_view;
@property (nonatomic, strong) IBOutlet NSScrollView* results_view;
@property (nonatomic, strong) IBOutlet NSTextField* no_results_message;

- (id)init;

- (void)setDelegate:(id<IAUserSearchViewProtocol>)delegate;

- (void)addUser:(IAUser*)user;

@end

@protocol IAUserSearchViewProtocol <NSObject>

- (void)searchView:(IAUserSearchViewController*)sender
       changedSize:(NSSize)size
  withActiveSearch:(BOOL)searching;

- (void)searchViewWantsLoseFocus:(IAUserSearchViewController*)sender;

@end