//
//  IAAdvancedSendViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 8/4/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAViewController.h"

#import "IAUserSearchViewController.h"

@protocol IAAdvancedSendViewProtocol;

@interface IAAdvancedSendViewController : IAViewController <NSTableViewDataSource,
                                                            NSTableViewDelegate,
                                                            NSTextViewDelegate,
                                                            IAUserSearchViewProtocol>

@property (nonatomic, strong) IBOutlet NSButton* add_files_button;
@property (nonatomic, strong) IBOutlet NSView* advanced_view;
@property (nonatomic, strong) IBOutlet IAHeaderView* header_view;
@property (nonatomic, strong) IBOutlet IAMainView* main_view;
@property (nonatomic, strong) IBOutlet NSButton* cancel_button;
@property (nonatomic, strong) IBOutlet NSTableView* table_view;
@property (nonatomic, strong) IBOutlet NSView* files_view;
@property (nonatomic, strong) IBOutlet IAFooterView* footer_view;
@property (nonatomic, strong) IBOutlet NSView* search_view;
@property (nonatomic, strong) IBOutlet NSButton* send_button;
@property (nonatomic, strong) IBOutlet NSTextField* note_field;
@property (nonatomic, strong) IBOutlet NSTextField* characters_label;

- (id)initWithDelegate:(id<IAAdvancedSendViewProtocol>)delegate
   andSearchController:(IAUserSearchViewController*)search_controller;

- (void)filesUpdated;

@end


@protocol IAAdvancedSendViewProtocol <NSObject>

- (NSArray*)advancedSendViewWantsFileList:(IAAdvancedSendViewController*)sender;
- (void)advancedSendViewWantsCancel:(IAAdvancedSendViewController*)sender;
- (void)advancedSendView:(IAAdvancedSendViewController*)sender
  wantsRemoveFileAtIndex:(NSInteger)index;

@end