//
//  IASearchResultsViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 8/4/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IASearchResultsCellView.h"
#import "IAHoverButton.h"
#import "InfinitSearchController.h"

#import "OEXTokenField.h"

@protocol IAUserSearchViewProtocol;

@interface IASearchBoxView : NSView

@property (readwrite, nonatomic, setter = setNoResults:) BOOL no_results;

@end

@interface IAUserSearchViewController : NSViewController <NSTableViewDataSource,
                                                          NSTableViewDelegate,
                                                          NSTextViewDelegate,
                                                          OEXTokenFieldDelegate,
                                                          IASearchResultsCellProtocol,
                                                          InfinitSearchControllerProtocol>

@property (nonatomic, strong) IBOutlet NSScrollView* results_view;
@property (nonatomic, strong) IBOutlet IASearchBoxView* search_box_view;
@property (nonatomic, strong) IBOutlet NSTokenField* search_field;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* search_field_width;
@property (nonatomic, strong) IBOutlet NSImageView* search_image;
@property (nonatomic, strong) IBOutlet NSProgressIndicator* search_spinner;
@property (nonatomic, strong) IBOutlet NSTextField* no_results_message;
@property (nonatomic, strong) IBOutlet IAHoverButton* more_button;
@property (nonatomic, strong) IBOutlet NSTableView* table_view;

- (id)init;

- (void)setDelegate:(id<IAUserSearchViewProtocol>)delegate;

- (void)addUser:(IAUser*)user;

- (void)removeUser:(IAUser*)user;

- (void)cursorAtEndOfSearchBox;

- (NSArray*)recipientList;

- (void)checkInputs;

- (void)showMoreButton:(BOOL)show;

@end

@protocol IAUserSearchViewProtocol <NSObject>

- (void)searchView:(IAUserSearchViewController*)sender
   changedToHeight:(CGFloat)height;

- (BOOL)searchViewWantsIfGotFile:(IAUserSearchViewController*)sender;

- (void)searchViewWantsLoseFocus:(IAUserSearchViewController*)sender;

- (void)searchViewHadMoreButtonClick:(IAUserSearchViewController*)sender;

- (void)searchView:(IAUserSearchViewController*)sender
 wantsAddFavourite:(IAUser*)user;

- (void)searchView:(IAUserSearchViewController*)sender
 wantsRemoveFavourite:(IAUser*)user;

- (void)searchViewInputsChanged:(IAUserSearchViewController*)sender;

- (void)searchViewGotEnterPress:(IAUserSearchViewController*)sender;

@end

@interface InfinitSearchElement : NSObject

@property (nonatomic, readwrite) NSImage* avatar;
@property (nonatomic, readwrite) NSString* email;
@property (nonatomic, readwrite) NSString* fullname;
@property (nonatomic, readwrite) IAUser* user;

- (id)initWithAvatar:(NSImage*)avatar
               email:(NSString*)email
            fullname:(NSString*)fullname
                user:(IAUser*)user;

@end