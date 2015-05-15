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
#import "InfinitFileListScrollView.h"

@class InfinitConversationMessageField;
@class InfinitConversationBubbleView;
@protocol InfinitConversationCellViewProtocol;
@protocol InfinitConversationBubbleViewProtocol;

@interface InfinitConversationCellView : NSTableCellView <NSTableViewDataSource,
                                                          NSTableViewDelegate,
                                                          InfinitConversationBubbleViewProtocol>

@property (nonatomic, weak) IBOutlet NSImageView* avatar;
@property (nonatomic, weak) IBOutlet NSImageView* file_icon;
@property (nonatomic, weak) IBOutlet NSTextField* file_name;
@property (nonatomic, weak) IBOutlet NSImageView* file_list_icon;
@property (nonatomic, weak) IBOutlet NSImageView* message_icon;
@property (nonatomic, weak) IBOutlet NSTextField* time_indicator;
@property (nonatomic, weak) IBOutlet NSTextField* information;
@property (nonatomic, weak) IBOutlet IAHoverButton* bottom_button;
@property (nonatomic, weak) IBOutlet IAHoverButton* top_button;
@property (nonatomic, weak) IBOutlet IAHoverButton* transaction_status_button;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* bubble_height;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* table_height;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* message_height;
@property (nonatomic, weak) IBOutlet InfinitFileListScrollView* table_container;
@property (nonatomic, weak) IBOutlet InfinitConversationMessageField* message;
@property (nonatomic, weak) IBOutlet InfinitConversationBubbleView* bubble_view;
@property (nonatomic, weak) IBOutlet InfinitConversationProgressBar* progress;


+ (CGFloat)heightOfCellForElement:(InfinitConversationElement*)element;

- (void)setupCellForElement:(InfinitConversationElement*)element
               withDelegate:(id<InfinitConversationCellViewProtocol>)delegate;

- (void)showFiles;
- (void)hideFiles;

- (void)onTransactionModeChangeIsNew:(BOOL)is_new;

- (void)updateAvatarWithImage:(NSImage*)avatar_image;

- (void)updateProgress;

@end

@protocol InfinitConversationCellViewProtocol <NSObject>

- (void)conversationCellViewWantsShowFiles:(InfinitConversationCellView*)sender;
- (void)conversationCellViewWantsHideFiles:(InfinitConversationCellView*)sender;
- (void)conversationCellBubbleViewGotClicked:(InfinitConversationCellView*)sender;

@end

@protocol InfinitConversationBubbleViewProtocol <NSObject>

- (void)bubbleViewGotClick:(InfinitConversationBubbleView*)sender;
- (void)bubbleViewGotHover:(InfinitConversationBubbleView*)sender;
- (void)bubbleViewGotUnHover:(InfinitConversationBubbleView*)sender;

@end
