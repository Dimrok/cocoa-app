//
//  IASimpleSendViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 8/2/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAViewController.h"

#import "IAUserSearchViewController.h"

@protocol IASimpleSendViewProtocol;

@interface IASimpleSendViewController : IAViewController <IAUserSearchViewProtocol>

@property (nonatomic, strong) IBOutlet NSButton* add_person_button;
@property (nonatomic, strong) IBOutlet NSButton* add_note_button;
@property (nonatomic, strong) IBOutlet NSButton* cancel_button;
@property (nonatomic, strong) IBOutlet NSButton* add_files_button;


- (id)initWithDelegate:(id<IASimpleSendViewProtocol>)delegate
   andSearchController:(IAUserSearchViewController*)search_controller;

@end

@protocol IASimpleSendViewProtocol <NSObject>

- (void)simpleSendViewWantsAddFile:(IASimpleSendViewController*)sender;
- (void)simpleSendViewWantsAddNote:(IASimpleSendViewController*)sender;
- (void)simpleSendViewWantsAddRecipient:(IASimpleSendViewController*)sender;
- (void)simpleSendViewWantsCancel:(IASimpleSendViewController*)sender;

@end
