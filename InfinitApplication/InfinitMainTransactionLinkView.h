//
//  InfinitMainTransactionLinkView.h
//  InfinitApplication
//
//  Created by Christopher Crone on 16/03/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "InfinitMainCounterView.h"

typedef NS_ENUM(NSUInteger, InfinitTransactionLinkMode)
{
  INFINIT_MAIN_VIEW_TRANSACTION_MODE,
  INFINIT_MAIN_VIEW_LINK_MODE,
};

@protocol InfinitMainTransactionLinkProtocol;

@interface InfinitMainTransactionLinkView : NSView

@property (nonatomic, weak) IBOutlet NSTextField* transaction_text;
@property (nonatomic, weak) IBOutlet NSTextField* link_text;
@property (nonatomic, weak) IBOutlet InfinitMainCounterView* transaction_counter;
@property (nonatomic, weak) IBOutlet InfinitMainCounterView* link_counter;
@property (nonatomic, readwrite) InfinitTransactionLinkMode mode;
@property (nonatomic, readwrite) CGFloat animate_mode;

- (void)setDelegate:(id<InfinitMainTransactionLinkProtocol>)delegate;

- (void)setupViewForPeopleView:(BOOL)flag;

- (void)setLinkCount:(NSUInteger)count;
- (void)setTransactionCount:(NSUInteger)count;

@end

@protocol InfinitMainTransactionLinkProtocol <NSObject>
- (void)gotUserClick:(InfinitMainTransactionLinkView*)sender;
- (void)gotLinkClick:(InfinitMainTransactionLinkView*)sender;
@end
