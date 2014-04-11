//
//  InfinitCombinedSendViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 24/12/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAViewController.h"

#import "IABottomButton.h"
#import "IAHoverButton.h"
#import "IAUserSearchViewController.h"

@class InfinitCombinedSendViewMainView;

@protocol InfinitCombinedSendViewProtocol;
@protocol InfinitCombinedSendViewMainViewProtocol;

@interface InfinitCombinedSendViewController : IAViewController <NSTableViewDataSource,
                                                                 NSTableViewDelegate,
                                                                 NSTextViewDelegate,
                                                                 IAUserSearchViewProtocol,
                                                                 InfinitCombinedSendViewMainViewProtocol>

@property (nonatomic, strong) IBOutlet IAHoverButton* add_files_button;
@property (nonatomic, strong) IBOutlet InfinitCombinedSendViewMainView* combined_view;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* combined_height_constraint;
@property (nonatomic, strong) IBOutlet NSButton* cancel_button;
@property (nonatomic, strong) IBOutlet NSTextField* characters_label;
@property (nonatomic, strong) IBOutlet NSTextField* file_count;
@property (nonatomic, strong) IBOutlet NSView* files_view;
@property (nonatomic, strong) IBOutlet IAFooterView* footer_view;
@property (nonatomic, strong) IBOutlet IAHeaderView* header_view;
@property (nonatomic, strong) IBOutlet IAMainView* main_view;
@property (nonatomic, strong) IBOutlet NSTextField* note_field;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* search_height_constraint;
@property (nonatomic, strong) IBOutlet NSView* search_view;
@property (nonatomic, strong) IBOutlet NSButton* send_button;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* table_height_constraint;
@property (nonatomic, strong) IBOutlet NSTableView* table_view;

- (id)initWithDelegate:(id<InfinitCombinedSendViewProtocol>)delegate
   andSearchController:(IAUserSearchViewController*)search_controller
              fullview:(BOOL)full_view;

- (void)filesUpdated;

@end


@protocol InfinitCombinedSendViewProtocol <IAViewProtocol>

- (NSArray*)combinedSendViewWantsFileList:(InfinitCombinedSendViewController*)sender;

- (void)combinedSendViewWantsCancel:(InfinitCombinedSendViewController*)sender;

- (void)combinedSendView:(InfinitCombinedSendViewController*)sender
  wantsRemoveFileAtIndex:(NSInteger)index;

- (void)combinedSendViewWantsOpenFileDialogBox:(InfinitCombinedSendViewController*)sender;

- (NSArray*)combinedSendView:(InfinitCombinedSendViewController*)sender
              wantsSendFiles:(NSArray*)files
                     toUsers:(NSArray*)users
                 withMessage:(NSString*)message;

- (void)combinedSendView:(InfinitCombinedSendViewController*)sender
       wantsAddFavourite:(IAUser*)user;

- (void)combinedSendView:(InfinitCombinedSendViewController*)sender
    wantsRemoveFavourite:(IAUser*)user;

- (void)combinedSendView:(InfinitCombinedSendViewController*)sender
wantsSetOnboardingSendTransactionId:(NSNumber*)transaction_id;

- (void)combinedSendView:(InfinitCombinedSendViewController*)sender
         hadFilesDropped:(NSArray*)files;

@end
