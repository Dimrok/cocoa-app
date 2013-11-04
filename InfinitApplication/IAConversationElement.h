//
//  IAConversationElement.h
//  InfinitApplication
//
//  Created by Christopher Crone on 8/26/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum __IAConversationCellViewMode
{
    CONVERSATION_CELL_VIEW_NORMAL = 0,
    CONVERSATION_CELL_VIEW_FILE_LIST = 1,
    CONVERSATION_CELL_VIEW_MESSAGE = 2,
    CONVERSATION_CELL_VIEW_SPACER = 3,
} IAConversationCellViewMode;

@interface IAConversationElement : NSObject

@property (nonatomic, readwrite) BOOL historic;
@property (nonatomic, readwrite) IAConversationCellViewMode mode;
@property (nonatomic, readonly) BOOL on_left;
@property (nonatomic, readonly) IATransaction* transaction;

- (id)initWithTransaction:(IATransaction*)transaction;


@end
