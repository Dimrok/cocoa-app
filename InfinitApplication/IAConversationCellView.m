//
//  IAConversationCellView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/15/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAConversationCellView.h"

//- Conversation Bubble View -----------------------------------------------------------------------

@interface IAConversationBubbleView : NSView
@end

@implementation IAConversationBubbleView

- (void)drawRect:(NSRect)dirtyRect
{
    // Grey border
    NSBezierPath* grey_border = [NSBezierPath bezierPathWithRect:self.bounds];
    [IA_GREY_COLOUR(212.0) set];
    [grey_border stroke];
    
    // White background
    NSBezierPath* white_bg = [NSBezierPath bezierPathWithRect:
                              NSMakeRect(1.0,
                                         1.0,
                                         self.bounds.size.width - 2.0,
                                         self.bounds.size.height - 2.0)];
    [IA_GREY_COLOUR(255.0) set];
    [white_bg fill];
}

@end

//- Conversation Cell View -------------------------------------------------------------------------

@implementation IAConversationCellView
{
@private
    IATransaction* _transaction;
}

//typedef enum __IATransactionViewMode
//{
//    TRANSACTION_VIEW_NONE = 0,
//    TRANSACTION_VIEW_PENDING_SEND,
//    TRANSACTION_VIEW_WAITING_REGISTER,
//    TRANSACTION_VIEW_WAITING_ONLINE,
//    TRANSACTION_VIEW_WAITING_ACCEPT,
//    TRANSACTION_VIEW_PREPARING,
//    TRANSACTION_VIEW_RUNNING,
//    TRANSACTION_VIEW_PAUSE_USER,
//    TRANSACTION_VIEW_PAUSE_AUTO,
//    TRANSACTION_VIEW_FINISHED,
//    TRANSACTION_VIEW_CANCELLED_SELF,
//    TRANSACTION_VIEW_CANCELLED_OTHER,
//    TRANSACTION_VIEW_FAILED
//} IATransactionViewMode;

+ (CGFloat)cellHeight:(IATransactionViewMode)view_mode
{
    CGFloat no_message = 62.0;
    CGFloat message = no_message + 25.0;
    CGFloat buttons = no_message + 35.0;
    CGFloat progress = no_message + 35.0;
    switch (view_mode) {
        case TRANSACTION_VIEW_PENDING_SEND:
            return buttons;
        case TRANSACTION_VIEW_WAITING_REGISTER:
            return message;
        case TRANSACTION_VIEW_WAITING_ONLINE:
            return buttons;
        case TRANSACTION_VIEW_WAITING_ACCEPT:
            return buttons;
        case TRANSACTION_VIEW_PREPARING:
            return progress;
        case TRANSACTION_VIEW_RUNNING:
            return progress;
        case TRANSACTION_VIEW_PAUSE_USER:
            return buttons;
        case TRANSACTION_VIEW_PAUSE_AUTO:
            return buttons;
        case TRANSACTION_VIEW_FINISHED:
            return no_message;
        case TRANSACTION_VIEW_CANCELLED_SELF:
            return message;
        case TRANSACTION_VIEW_CANCELLED_OTHER:
            return message;
        case TRANSACTION_VIEW_FAILED:
            return message;
        default:
            return no_message;
    }
}

//- Initialisation ---------------------------------------------------------------------------------

- (void)drawRect:(NSRect)dirtyRect
{
    NSBezierPath* grey_bg = [NSBezierPath bezierPathWithRect:self.bounds];
    [IA_GREY_COLOUR(246.0) set];
    [grey_bg fill];
}

//- General Functions ------------------------------------------------------------------------------



//- Drawing Functions ------------------------------------------------------------------------------

- (void)setupCellWithTransaction:(IATransaction*)transaction
{
    _transaction = transaction;
    NSMutableParagraphStyle* date_para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    date_para.alignment = NSCenterTextAlignment;
    NSDictionary* date_attrs = [IAFunctions textStyleWithFont:[NSFont systemFontOfSize:11.0]
                                               paragraphStyle:date_para
                                                       colour:IA_GREY_COLOUR(206.0)
                                                       shadow:nil];
    NSString* date_str = [IAFunctions relativeDateOf:transaction.timestamp];
    self.date.attributedStringValue = [[NSAttributedString alloc] initWithString:date_str
                                                                      attributes:date_attrs];
    
    NSMutableParagraphStyle* files_para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    files_para.alignment = NSRightTextAlignment;
    NSDictionary* files_name_attrs = [IAFunctions
                                      textStyleWithFont:[NSFont systemFontOfSize:12.0]
                                      paragraphStyle:files_para
                                      colour:IA_GREY_COLOUR(46.0)
                                      shadow:nil];
    NSString* files_str;
    if (transaction.files_count > 1)
    {
        files_str = [NSString stringWithFormat:@"%ld %@", transaction.files_count,
                     NSLocalizedString(@"files", @"files")];
    }
    else
    {
        self.files_icon.image = [[NSWorkspace sharedWorkspace]
                                 iconForFileType:[transaction.first_filename pathExtension]];
        files_str = transaction.first_filename;
    }
    self.files_label.attributedStringValue = [[NSAttributedString alloc]
                                              initWithString:files_str
                                              attributes:files_name_attrs];
}

//- Table Handling ---------------------------------------------------------------------------------

- (NSInteger)numberOfRowsInTableView:(NSTableView*)tableView
{
    if (_transaction.files_count > 1)
        return _transaction.files_count;
    else
        return 0;
}

//- Button Handling --------------------------------------------------------------------------------

- (IBAction)messageButtonClicked:(NSButton*)sender
{
    
}

- (IBAction)expandFilesClicked:(NSButton*)sender
{
    
}

@end
