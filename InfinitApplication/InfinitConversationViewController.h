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

#import <Gap/InfinitPeerTransaction.h>

@protocol InfinitConversationViewProtocol;

@interface InfinitConversationViewController : IAViewController

@property (nonatomic, readonly) InfinitUser* user;

- (id)initWithDelegate:(id<InfinitConversationViewProtocol>)delegate
               forUser:(InfinitUser*)user;

@end

@protocol InfinitConversationViewProtocol <IAViewProtocol>

- (void)conversationView:(InfinitConversationViewController*)sender
    wantsTransferForUser:(InfinitUser*)user;

- (void)conversationViewWantsBack:(InfinitConversationViewController*)sender;

@end