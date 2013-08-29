//
//  IASearchResultsViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 8/4/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IASearchResultsCellView.h"

@protocol IAUserSearchViewProtocol;

@interface IAUserSearchViewController : NSViewController <NSTableViewDataSource,
                                                          NSTableViewDelegate,
                                                          NSTextViewDelegate,
                                                          NSTokenFieldDelegate,
                                                          IASearchResultsCellProtocol>

@property (nonatomic, strong) IBOutlet NSView* search_box_view;
@property (nonatomic, strong) IBOutlet NSTokenField* search_field;
@property (nonatomic, strong) IBOutlet NSTableView* table_view;
@property (nonatomic, strong) IBOutlet NSScrollView* results_view;
@property (nonatomic, strong) IBOutlet NSTextField* no_results_message;
@property (nonatomic, strong) IBOutlet NSButton* send_button;

- (id)init;

- (void)setDelegate:(id<IAUserSearchViewProtocol>)delegate;

- (void)addUser:(IAUser*)user;

- (void)cursorAtEndOfSearchBox;

- (NSArray*)recipientList;

- (void)hideSendButton;

- (void)showSendButton;

@end

@protocol IAUserSearchViewProtocol <NSObject>

- (void)searchView:(IAUserSearchViewController*)sender
       changedSize:(NSSize)size
  withActiveSearch:(BOOL)searching;

- (void)searchViewWantsLoseFocus:(IAUserSearchViewController*)sender;

- (void)searchViewHadSendButtonClick:(IAUserSearchViewController*)sender;

- (void)searchView:(IAUserSearchViewController*)sender
 wantsAddFavourite:(IAUser*)user;

- (void)searchView:(IAUserSearchViewController*)sender
 wantsRemoveFavourite:(IAUser*)user;

- (void)searchViewWantsCheckInputs:(IAUserSearchViewController*)sender;

- (void)searchViewGotEnterPress:(IAUserSearchViewController*)sender;

@end