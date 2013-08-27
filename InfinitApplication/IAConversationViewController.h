//
//  IAConversationViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 8/5/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//
// The conversation view shows the transaction history for a given user

#import "IAViewController.h"

@protocol IAConversationViewProtocol;

@interface IAConversationViewController : IAViewController <NSTableViewDataSource,
                                                            NSTableViewDelegate>

@property (nonatomic, strong) IBOutlet NSImageView* avatar_view;
@property (nonatomic, strong) IBOutlet NSButton* back_button;
@property (nonatomic, strong) IBOutlet NSView* person_view;
@property (nonatomic, strong) IBOutlet NSScrollView* scroll_view;
@property (nonatomic, strong) IBOutlet NSTableView* table_view;
@property (nonatomic, strong) IBOutlet NSButton* transfer_button;
@property (nonatomic, strong) IBOutlet NSTextField* user_fullname;
@property (nonatomic, strong) IBOutlet NSTextField* user_handle;
@property (nonatomic, strong) IBOutlet NSImageView* user_online;

// XXX change when there are groups
- (id)initWithDelegate:(id<IAConversationViewProtocol>)delegate
              andUser:(IAUser*)user;

@end

@protocol IAConversationViewProtocol <NSObject>

- (NSArray*)conversationView:(IAConversationViewController*)sender
    wantsTransactionsForUser:(IAUser*)user;

- (void)conversationView:(IAConversationViewController*)sender
    wantsTransferForUser:(IAUser*)user;

- (void)conversationViewWantsBack:(IAConversationViewController*)sender;

- (void)conversationView:(IAConversationViewController*)sender
  wantsAcceptTransaction:(IATransaction*)transaction;
- (void)conversationView:(IAConversationViewController*)sender
  wantsCancelTransaction:(IATransaction*)transaction;
- (void)conversationView:(IAConversationViewController*)sender
  wantsRejectTransaction:(IATransaction*)transaction;

@end
