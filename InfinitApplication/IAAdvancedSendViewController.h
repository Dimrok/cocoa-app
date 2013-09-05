//
//  IAAdvancedSendViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 8/4/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAViewController.h"

#import "IAUserSearchViewController.h"
#import "IABottomButton.h"

typedef enum IAAdvancedSendViewFocus
{
    ADVANCED_VIEW_USER_SEARCH_FOCUS = 0,
    ADVANCED_VIEW_NOTE_FOCUS
} IAAdvancedSendViewFocus;

@protocol IAAdvancedSendViewProtocol;

@interface IAAdvancedSendViewController : IAViewController <NSTableViewDataSource,
                                                            NSTableViewDelegate,
                                                            NSTextViewDelegate,
                                                            IAUserSearchViewProtocol>

@property (nonatomic, strong) IBOutlet NSButton* add_files_button;
@property (nonatomic, strong) IBOutlet NSView* advanced_view;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* advanced_height_constraint;
@property (nonatomic, strong) IBOutlet NSButton* cancel_button;
@property (nonatomic, strong) IBOutlet NSTextField* characters_label;
@property (nonatomic, strong) IBOutlet NSView* files_view;
@property (nonatomic, strong) IBOutlet IAFooterView* footer_view;
@property (nonatomic, strong) IBOutlet IAHeaderView* header_view;
@property (nonatomic, strong) IBOutlet IAMainView* main_view;
@property (nonatomic, strong) IBOutlet NSTextField* note_field;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* search_height_constraint;
@property (nonatomic, strong) IBOutlet NSView* search_view;
@property (nonatomic, strong) IBOutlet IABottomButton* send_button;
@property (nonatomic, strong) IBOutlet NSTableView* table_view;

- (id)initWithDelegate:(id<IAAdvancedSendViewProtocol>)delegate
   andSearchController:(IAUserSearchViewController*)search_controller
               focusOn:(IAAdvancedSendViewFocus)focus;

- (void)filesUpdated;

@end


@protocol IAAdvancedSendViewProtocol <NSObject>

- (NSArray*)advancedSendViewWantsFileList:(IAAdvancedSendViewController*)sender;

- (void)advancedSendViewWantsCancel:(IAAdvancedSendViewController*)sender;

- (void)advancedSendView:(IAAdvancedSendViewController*)sender
  wantsRemoveFileAtIndex:(NSInteger)index;

- (void)advancedSendViewWantsOpenFileDialogBox:(IAAdvancedSendViewController*)sender;

- (void)advancedSendView:(IAAdvancedSendViewController*)sender
          wantsSendFiles:(NSArray*)files
                 toUsers:(NSArray*)users
             withMessage:(NSString*)message;

- (void)advancedSendView:(IAAdvancedSendViewController*)sender
       wantsAddFavourite:(IAUser*)user;

- (void)advancedSendView:(IAAdvancedSendViewController*)sender
    wantsRemoveFavourite:(IAUser*)user;

@end