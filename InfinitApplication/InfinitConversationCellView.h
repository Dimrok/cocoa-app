//
//  InfinitConversationCellView.h
//  InfinitApplication
//
//  Created by Christopher Crone on 17/03/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "InfinitConversationElement.h"
#import "IAHoverButton.h"
#import "InfinitConversationProgressBar.h"

@class InfinitConversationBubbleView;
@protocol InfinitConversationCellViewProtocol;
@protocol InfinitConversationBubbleViewProtocol;

@interface InfinitConversationCellView : NSTableCellView <NSTableViewDataSource,
                                                          NSTableViewDelegate,
                                                          InfinitConversationBubbleViewProtocol>

@property (nonatomic, strong) IBOutlet NSImageView* avatar;
@property (nonatomic, strong) IBOutlet NSImageView* file_icon;
@property (nonatomic, strong) IBOutlet NSTextField* file_name;
@property (nonatomic, strong) IBOutlet NSImageView* file_list_icon;
@property (nonatomic, strong) IBOutlet NSImageView* message_icon;
@property (nonatomic, strong) IBOutlet NSTextField* time_indicator;
@property (nonatomic, strong) IBOutlet NSTextField* information;
@property (nonatomic, strong) IBOutlet IAHoverButton* reject_button;
@property (nonatomic, strong) IBOutlet IAHoverButton* accept_button;
@property (nonatomic, strong) IBOutlet IAHoverButton* transaction_status_button;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* bubble_height;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* table_height;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* message_height;
@property (nonatomic, strong) IBOutlet NSTableView* file_list;
@property (nonatomic, strong) IBOutlet NSTextField* message;
@property (nonatomic, strong) IBOutlet InfinitConversationBubbleView* bubble_view;
@property (nonatomic, strong) IBOutlet InfinitConversationProgressBar* progress;


+ (CGFloat)heightOfCellForElement:(InfinitConversationElement*)element;

- (void)setupCellForElement:(InfinitConversationElement*)element
               withDelegate:(id<InfinitConversationCellViewProtocol>)delegate;

- (void)showFiles;
- (void)hideFiles;

- (void)updateProgress;

@end

@protocol InfinitConversationCellViewProtocol <NSObject>

- (void)conversationCellViewWantsShowFiles:(InfinitConversationCellView*)sender;
- (void)conversationCellViewWantsHideFiles:(InfinitConversationCellView*)sender;

@end

@protocol InfinitConversationBubbleViewProtocol <NSObject>

- (void)bubbleViewGotClick:(InfinitConversationBubbleView*)sender;
- (void)bubbleViewGotHover:(InfinitConversationBubbleView*)sender;
- (void)bubbleViewGotUnHover:(InfinitConversationBubbleView*)sender;

@end
