//
//  InfinitTransactionViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 12/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "InfinitTransactionCellView.h"

#import <Gap/InfinitPeerTransaction.h>
#import <Gap/InfinitUser.h>

@protocol InfinitTransactionViewProtocol;

@interface InfinitTransactionViewController : NSViewController

@property (nonatomic, readwrite) BOOL changing;
@property (nonatomic, readonly) CGFloat height;
@property (nonatomic, readonly) NSUInteger unread_rows;

- (id)initWithDelegate:(id<InfinitTransactionViewProtocol>)delegate;

- (void)updateModel;
- (void)scrollToTop;

- (void)transactionAdded:(InfinitPeerTransaction*)transaction;
- (void)transactionUpdated:(InfinitPeerTransaction*)transaction;

- (void)userUpdated:(InfinitUser*)user;

- (void)markTransactionsRead;

- (void)closeToolTips;

@end

@protocol InfinitTransactionViewProtocol <NSObject>

- (void)transactionsViewResizeToHeight:(CGFloat)height;

- (void)userGotClicked:(InfinitUser*)user;

@end
