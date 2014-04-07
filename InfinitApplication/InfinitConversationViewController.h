//
//  InfinitConversationViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 17/03/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "IAViewController.h"
#import "InfinitConversationPersonView.h"
#import "InfinitConversationCellView.h"

@protocol InfinitConversationViewProtocol;

@interface InfinitConversationViewController : IAViewController <NSTableViewDataSource,
                                                                 NSTableViewDelegate,
                                                                 InfinitConversationPersonViewProtocol,
                                                                 InfinitConversationCellViewProtocol>

@property (nonatomic, strong) IBOutlet NSButton* back_button;
@property (nonatomic, strong) IBOutlet InfinitConversationPersonView* person_view;
@property (nonatomic, strong) IBOutlet NSScrollView* scroll_view;
@property (nonatomic, strong) IBOutlet NSTableView* table_view;
@property (nonatomic, strong) IBOutlet NSButton* transfer_button;
@property (nonatomic, readonly) IAUser* user;

- (id)initWithDelegate:(id<InfinitConversationViewProtocol>)delegate
               forUser:(IAUser*)user
      withTransactions:(NSArray*)transactions;

- (IBAction)backButtonClicked:(NSButton*)sender;
- (IBAction)transferButtonClicked:(NSButton*)sender;

- (IBAction)conversationCellViewWantsAccept:(NSButton*)sender;
- (IBAction)conversationCellViewWantsCancel:(NSButton*)sender;
- (IBAction)conversationCellViewWantsReject:(NSButton*)sender;

@end

@protocol InfinitConversationViewProtocol <IAViewProtocol>

- (void)conversationView:(InfinitConversationViewController*)sender
wantsMarkTransactionsReadForUser:(IAUser*)user;

- (void)conversationView:(InfinitConversationViewController*)sender
    wantsTransferForUser:(IAUser*)user;

- (void)conversationViewWantsBack:(InfinitConversationViewController*)sender;

- (void)conversationView:(InfinitConversationViewController*)sender
  wantsAcceptTransaction:(IATransaction*)transaction;

- (void)conversationView:(InfinitConversationViewController*)sender
  wantsCancelTransaction:(IATransaction*)transaction;

- (void)conversationView:(InfinitConversationViewController*)sender
  wantsRejectTransaction:(IATransaction*)transaction;

- (IATransaction*)receiveOnboardingTransaction:(IAViewController*)sender;
- (IATransaction*)sendOnboardingTransaction:(InfinitConversationViewController*)sender;


@end