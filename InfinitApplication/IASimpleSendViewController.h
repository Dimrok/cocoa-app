//
//  IASimpleSendViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 8/2/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAViewController.h"

#import "IASearchResultsViewController.h"

@protocol IASimpleSendViewProtocol;

@interface IASimpleSendViewController : IAViewController <NSTextFieldDelegate,
                                                          IASearchResultsViewProtocol>

@property (nonatomic, strong) IBOutlet NSButton* add_person_button;
@property (nonatomic, strong) IBOutlet NSButton* add_note_button;
@property (nonatomic, strong) IBOutlet NSButton* clear_search;
@property (nonatomic, strong) IBOutlet NSButton* cancel_button;
@property (nonatomic, strong) IBOutlet NSButton* add_files_button;
@property (nonatomic, strong) IBOutlet NSTextField* search_field;
@property (nonatomic, strong) IBOutlet NSView* search_results;


- (id)initWithDelegate:(id<IASimpleSendViewProtocol>)delegate;

@end

@protocol IASimpleSendViewProtocol <NSObject>

@end
