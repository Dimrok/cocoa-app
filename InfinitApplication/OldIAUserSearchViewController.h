//
//  OldIASearchResultsViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 8/4/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "OldIASearchResultsCellView.h"
#import "IAHoverButton.h"
#import "OldInfinitSearchController.h"

#import "OEXTokenField.h"

//- Controller -------------------------------------------------------------------------------------

@protocol OldIAUserSearchViewProtocol;

@interface OldIASearchBoxView : NSView
@property (nonatomic, readwrite, setter = setLoading:) BOOL loading;
@end

@interface OldIAUserSearchViewController : NSViewController <NSTableViewDataSource,
                                                             NSTableViewDelegate,
                                                             NSTextViewDelegate,
                                                             OEXTokenFieldDelegate,
                                                             OldIASearchResultsCellProtocol,
                                                             OldInfinitSearchControllerProtocol>

@property (nonatomic, weak) IBOutlet NSScrollView* results_view;
@property (nonatomic, weak) IBOutlet OldIASearchBoxView* search_box_view;
@property (nonatomic, weak) IBOutlet OEXTokenField* search_field;
@property (nonatomic, weak) IBOutlet NSImageView* search_image;
@property (nonatomic, weak) IBOutlet NSProgressIndicator* search_spinner;
@property (nonatomic, weak) IBOutlet NSTextField* no_results_message;
@property (nonatomic, weak) IBOutlet NSTableView* table_view;

- (id)init;

- (void)setDelegate:(id<OldIAUserSearchViewProtocol>)delegate;

- (void)addUser:(IAUser*)user;

- (void)removeUser:(IAUser*)user;

- (void)cursorAtEndOfSearchBox;

- (NSArray*)recipientList;

- (void)checkInputs;

- (void)aboutToChangeView;

@end

@protocol OldIAUserSearchViewProtocol <NSObject>

- (void)searchView:(OldIAUserSearchViewController*)sender
   changedToHeight:(CGFloat)height;

- (BOOL)searchViewWantsIfGotFile:(OldIAUserSearchViewController*)sender;

- (void)searchViewWantsLoseFocus:(OldIAUserSearchViewController*)sender;

- (void)searchView:(OldIAUserSearchViewController*)sender
 wantsAddFavourite:(IAUser*)user;

- (void)searchView:(OldIAUserSearchViewController*)sender
 wantsRemoveFavourite:(IAUser*)user;

- (void)searchViewInputsChanged:(OldIAUserSearchViewController*)sender;

- (void)searchViewGotWantsSend:(OldIAUserSearchViewController*)sender;

- (NSArray*)searchViewWantsFriendsByLastInteraction:(OldIAUserSearchViewController*)sender;


@end

@interface OldInfinitSearchElement : NSObject

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