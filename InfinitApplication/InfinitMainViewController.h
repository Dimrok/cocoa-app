//
//  InfinitMainViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 13/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "IAViewController.h"

#import "InfinitTransactionViewController.h"
#import "InfinitLinkViewController.h"
#import "InfinitMainCounterView.h"

//- User Link View ---------------------------------------------------------------------------------

typedef enum _InfinitTransactionLinkMode
{
  INFINIT_MAIN_VIEW_TRANSACTION_MODE,
  INFINIT_MAIN_VIEW_LINK_MODE,
} InfinitTransactionLinkMode;

@protocol InfinitMainTransactionLinkProtocol;

@interface InfinitMainTransactionLinkView : NSView
@property (nonatomic, strong) IBOutlet NSTextField* transaction_text;
@property (nonatomic, strong) IBOutlet NSTextField* link_text;
@property (nonatomic, strong) IBOutlet InfinitMainCounterView* transaction_counter;
@property (nonatomic, strong) IBOutlet InfinitMainCounterView* link_counter;
@property (nonatomic, readwrite) InfinitTransactionLinkMode mode;
@property (nonatomic, readwrite) CGFloat animate_mode;

- (void)setDelegate:(id<InfinitMainTransactionLinkProtocol>)delegate;
- (void)setupView;

- (void)setLinkCount:(NSUInteger)count;
- (void)setTransactionCount:(NSUInteger)count;

@end

@protocol InfinitMainTransactionLinkProtocol <NSObject>
- (void)gotUserClick:(InfinitMainTransactionLinkView*)sender;
- (void)gotLinkClick:(InfinitMainTransactionLinkView*)sender;
@end

//- Controller -------------------------------------------------------------------------------------

@protocol InfinitMainViewProtocol;

@interface InfinitMainViewController : IAViewController <InfinitLinkViewProtocol,
                                                         InfinitMainTransactionLinkProtocol,
                                                         InfinitTransactionViewProtocol>

- (id)initWithDelegate:(id<InfinitMainViewProtocol>)delegate
    andTransactionList:(NSArray*)transaction_list
           andLinkList:(NSArray*)link_list;

@property (nonatomic, retain) IBOutlet NSMenuItem* auto_start_toggle;
@property (nonatomic, strong) IBOutlet InfinitMainTransactionLinkView* view_selector;
@property (nonatomic, strong) IBOutlet NSMenu* gear_menu;
@property (nonatomic, strong) IBOutlet NSButton* gear_button;
@property (nonatomic, strong) IBOutlet NSButton* send_button;
@property (nonatomic, strong) IBOutlet NSMenuItem* version_item;

@end

@protocol InfinitMainViewProtocol <NSObject>

- (NSArray*)latestTransactionsByUser:(InfinitMainViewController*)sender;

- (NSUInteger)runningTransactionsForUser:(IAUser*)user;
- (NSUInteger)notDoneTransactionsForUser:(IAUser*)user;
- (NSUInteger)unreadTransactionsForUser:(IAUser*)user;
- (CGFloat)totalProgressForUser:(IAUser*)user;

- (BOOL)transferringTransactionsForUser:(IAUser*)user;

- (void)userGotClicked:(IAUser*)user;
- (void)sendGotClicked:(InfinitMainViewController*)sender;
- (void)makeLinkGotClicked:(InfinitMainViewController*)sender;

- (void)markTransactionRead:(IATransaction*)transaction;

- (void)linkGotCopiedToPasteBoard:(InfinitLinkTransaction*)link;

//- Gear Menu Handling -----------------------------------------------------------------------------

- (BOOL)autostart:(InfinitMainViewController*)sender;
- (void)setAutoStart:(BOOL)state;
- (void)checkForUpdate:(InfinitMainViewController*)sender;
- (void)reportAProblem:(InfinitMainViewController*)sender;
- (void)logout:(InfinitMainViewController*)sender;
- (void)quit:(InfinitMainViewController*)sender;

@end
