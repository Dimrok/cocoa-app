//
//  IASearchResultsViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 8/4/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "InfinitSearchBoxView.h"
#import "IAHoverButton.h"
#import "InfinitSearchController.h"
#import "InfinitSearchResultCell.h"
#import "InfinitSearchNoResultsCellView.h"

#import "OEXTokenField.h"

#import <Gap/InfinitUser.h>

//- Controller -------------------------------------------------------------------------------------

@protocol IAUserSearchViewProtocol;

@interface IAUserSearchViewController : NSViewController <NSTableViewDataSource,
                                                          NSTableViewDelegate,
                                                          NSTextViewDelegate,
                                                          OEXTokenFieldDelegate,
                                                          InfinitSearchResultCellProtocol,
                                                          InfinitSearchControllerProtocol>

@property (nonatomic, weak) IBOutlet NSScrollView* results_view;
@property (nonatomic, weak) IBOutlet InfinitSearchBoxView* search_box_view;
@property (nonatomic, weak) IBOutlet OEXTokenField* search_field;
@property (nonatomic, weak) IBOutlet NSTextField* search_label;
@property (nonatomic, weak) IBOutlet NSImageView* link_icon;
@property (nonatomic, weak) IBOutlet NSTextField* link_text;
@property (nonatomic, weak) IBOutlet NSProgressIndicator* search_spinner;
@property (nonatomic, weak) IBOutlet NSTableView* table_view;

@property (nonatomic, readwrite) BOOL link_mode;

- (void)setDelegate:(id<IAUserSearchViewProtocol>)delegate;

- (void)addUser:(InfinitUser*)user;

- (void)removeUser:(InfinitUser*)user;

- (void)cursorAtEndOfSearchBox;

- (NSArray*)recipientList;

- (void)aboutToChangeView;

- (void)showResults;

- (void)fixClipView;

@end

@protocol IAUserSearchViewProtocol <NSObject>

- (void)searchView:(id)sender
   changedToHeight:(CGFloat)height;

- (void)searchViewWantsLoseFocus:(IAUserSearchViewController*)sender;

- (void)searchViewInputsChanged:(IAUserSearchViewController*)sender;

- (void)searchViewGotWantsSend:(IAUserSearchViewController*)sender;

- (BOOL)searchViewGotEscapePressedShrink:(IAUserSearchViewController*)sender;

@end
