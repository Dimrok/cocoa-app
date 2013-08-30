//
//  IAConversationHeaderView.h
//  InfinitApplication
//
//  Created by Christopher Crone on 8/30/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol IAConversationHeaderProtocol;

@interface IAConversationHeaderView : NSView

- (void)setDelegate:(id<IAConversationHeaderProtocol>)delegate;

@end

@protocol IAConversationHeaderProtocol <NSObject>

- (void)conversationHeaderGotClick:(IAConversationHeaderView*)sender;

@end

