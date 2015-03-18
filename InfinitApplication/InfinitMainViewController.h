//
//  InfinitMainViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 13/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "IAViewController.h"

#import "InfinitLinkViewController.h"
#import "InfinitMainCounterView.h"
#import "InfinitMainTransactionLinkView.h"
#import "InfinitTransactionViewController.h"

#import <Gap/InfinitUser.h>

//- Controller -------------------------------------------------------------------------------------

@protocol InfinitMainViewProtocol;

@interface InfinitMainViewController : IAViewController <InfinitLinkViewProtocol,
                                                         InfinitMainTransactionLinkProtocol,
                                                         InfinitTransactionViewProtocol>

- (id)initWithDelegate:(id<InfinitMainViewProtocol>)delegate
         forPeopleView:(BOOL)flag;

@property (nonatomic, strong) IBOutlet InfinitMainTransactionLinkView* view_selector;
@property (nonatomic, strong) IBOutlet NSMenu* gear_menu;
@property (nonatomic, strong) IBOutlet NSButton* gear_button;
@property (nonatomic, strong) IBOutlet NSButton* send_button;
@property (nonatomic, strong) IBOutlet NSMenuItem* version_item;

@end

@protocol InfinitMainViewProtocol <IAViewProtocol>

- (void)userGotClicked:(InfinitUser*)user;
- (void)sendGotClicked:(InfinitMainViewController*)sender;
- (void)makeLinkGotClicked:(InfinitMainViewController*)sender;

- (void)copyLinkToClipboard:(InfinitLinkTransaction*)link;

//- Gear Menu Handling -----------------------------------------------------------------------------

- (void)settings:(InfinitMainViewController*)sender;
- (void)reportAProblem:(InfinitMainViewController*)sender;
- (void)logout:(InfinitMainViewController*)sender;
- (void)quit:(InfinitMainViewController*)sender;

@end
