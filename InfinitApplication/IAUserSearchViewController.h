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

//- Controller -------------------------------------------------------------------------------------

@protocol IAUserSearchViewProtocol;

@interface IASearchBoxView : NSView
@property (nonatomic, readwrite, setter = setLoading:) BOOL loading;
@end

@interface IAUserSearchViewController : NSViewController <NSTableViewDataSource,
                                                          NSTableViewDelegate,
                                                          NSTextViewDelegate,
                                                          OEXTokenFieldDelegate,
                                                          IASearchResultsCellProtocol,
                                                          InfinitSearchControllerProtocol>

@property (nonatomic, weak) IBOutlet NSScrollView* results_view;
@property (nonatomic, weak) IBOutlet IASearchBoxView* search_box_view;
@property (nonatomic, weak) IBOutlet OEXTokenField* search_field;
@property (nonatomic, weak) IBOutlet NSImageView* search_image;
@property (nonatomic, weak) IBOutlet NSProgressIndicator* search_spinner;
@property (nonatomic, weak) IBOutlet NSTextField* no_results_message;
@property (nonatomic, weak) IBOutlet NSTableView* table_view;

- (id)init;

- (void)setDelegate:(id<IAUserSearchViewProtocol>)delegate;

- (void)addUser:(IAUser*)user;

- (void)removeUser:(IAUser*)user;

- (void)cursorAtEndOfSearchBox;

- (NSArray*)recipientList;

- (void)checkInputs;

@end

@protocol IAUserSearchViewProtocol <NSObject>

- (void)searchView:(IAUserSearchViewController*)sender
   changedToHeight:(CGFloat)height;

- (BOOL)searchViewWantsIfGotFile:(IAUserSearchViewController*)sender;

- (void)searchViewWantsLoseFocus:(IAUserSearchViewController*)sender;

- (void)searchView:(IAUserSearchViewController*)sender
 wantsAddFavourite:(IAUser*)user;

- (void)searchView:(IAUserSearchViewController*)sender
 wantsRemoveFavourite:(IAUser*)user;

- (void)searchViewInputsChanged:(IAUserSearchViewController*)sender;

- (void)searchViewGotWantsSend:(IAUserSearchViewController*)sender;

- (NSArray*)searchViewWantsFriendsByLastInteraction:(IAUserSearchViewController*)sender;


@end

@interface InfinitSearchElement : NSObject

@property (nonatomic, readwrite) NSImage* avatar;
@property (nonatomic, readwrite) NSString* email;
@property (nonatomic, readwrite) NSString* fullname;
@property (nonatomic, readwrite) IAUser* user;
@property (nonatomic, readwrite) BOOL hover;
@property (nonatomic, readwrite) BOOL selected;

- (id)initWithAvatar:(NSImage*)avatar
               email:(NSString*)email
            fullname:(NSString*)fullname
                user:(IAUser*)user;

@end