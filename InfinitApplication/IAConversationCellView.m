//
//  IAConversationCellView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/15/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAConversationCellView.h"

//- Conversation Bubble View -----------------------------------------------------------------------

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
    IAConversationBubbleView* _current_bubble;
    BOOL _files_shown;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithFrame:(NSRect)frameRect
{
    if (self = [super initWithFrame:frameRect])
    {
        _files_shown = NO;
        self.progress_indicator = nil;
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSBezierPath* grey_bg = [NSBezierPath bezierPathWithRect:self.bounds];
    [IA_GREY_COLOUR(246.0) set];
    [grey_bg fill];
}

//- General Functions ------------------------------------------------------------------------------

+ (CGFloat)heightOfCellWithElement:(IAConversationElement*)element
{
    CGFloat normal = 56.0;
    CGFloat message = 70.0;
    CGFloat file_list = normal;
    if (element.transaction.files_count > 3)
    {
        file_list += 14.0 + 15.0 * 3;
    }
    else
    {
        file_list += 14.0 + 15.0 * element.transaction.files_count;
    }
    CGFloat buttons = normal + 30.0;
    CGFloat progress = normal + 30.0;
    CGFloat error = normal + 25.0;
    switch (element.mode)
    {
        case CONVERSATION_CELL_VIEW_MESSAGE:
            return message;

        case CONVERSATION_CELL_VIEW_FILE_LIST:
            return file_list;
            
        case CONVERSATION_CELL_VIEW_NORMAL:
            switch (element.transaction.view_mode)
            {
                case TRANSACTION_VIEW_PENDING_SEND:
                    return buttons;
                
                case TRANSACTION_VIEW_WAITING_REGISTER:
                    return buttons;
                
                case TRANSACTION_VIEW_WAITING_ONLINE:
                    return buttons;
                    
                case TRANSACTION_VIEW_WAITING_ACCEPT:
                    return buttons;
                    
                case TRANSACTION_VIEW_PREPARING:
                    return progress;
                
                case TRANSACTION_VIEW_RUNNING:
                    return progress;
                    
                case TRANSACTION_VIEW_PAUSE_AUTO:
                    return buttons;
                
                case TRANSACTION_VIEW_PAUSE_USER:
                    return buttons;
                
                case TRANSACTION_VIEW_REJECTED:
                    return error;
                    
                case TRANSACTION_VIEW_CANCELLED_SELF:
                    return error;
                    
                case TRANSACTION_VIEW_CANCELLED_OTHER:
                    return error;
                    
                case TRANSACTION_VIEW_FINISHED:
                    return normal;
                    
                case TRANSACTION_VIEW_FAILED:
                    return error;
                    
                default:
                    return normal;
            }
        
        default:
            return normal;
    }
}

- (void)updateProgress
{
    self.progress_indicator.doubleValue = _transaction.progress;
}


//- Drawing Functions ------------------------------------------------------------------------------

- (void)setupCellWithElement:(IAConversationElement*)element
{
    _transaction = element.transaction;
    
    NSMutableParagraphStyle* text_align = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    if (element.on_left)
        text_align.alignment = NSLeftTextAlignment;
    else
        text_align.alignment = NSRightTextAlignment;
    
    if (_transaction.message.length == 0)
        [self.message_button setHidden:YES];
    
    NSMutableParagraphStyle* date_para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    date_para.alignment = NSCenterTextAlignment;
    NSDictionary* date_attrs = [IAFunctions textStyleWithFont:[NSFont systemFontOfSize:11.0]
                                               paragraphStyle:date_para
                                                       colour:IA_GREY_COLOUR(206.0)
                                                       shadow:nil];
    NSString* date_str = [IAFunctions relativeDateOf:_transaction.last_edit_timestamp];
    self.date.attributedStringValue = [[NSAttributedString alloc] initWithString:date_str
                                                                      attributes:date_attrs];
    
    NSDictionary* files_name_attrs = [IAFunctions
                                      textStyleWithFont:[NSFont systemFontOfSize:12.0]
                                      paragraphStyle:text_align
                                      colour:IA_GREY_COLOUR(46.0)
                                      shadow:nil];
    NSString* files_str;
    if (_transaction.files_count > 1)
    {
        files_str = [NSString stringWithFormat:@"%ld %@", _transaction.files_count,
                     NSLocalizedString(@"files", @"files")];
    }
    else
    {
        self.files_icon.image = [[NSWorkspace sharedWorkspace]
                                 iconForFileType:[_transaction.files[0] pathExtension]];
        files_str = _transaction.files[0];
    }
    self.files_label.attributedStringValue = [[NSAttributedString alloc]
                                              initWithString:files_str
                                              attributes:files_name_attrs];
    
    if (element.mode == CONVERSATION_CELL_VIEW_MESSAGE)
    {
        self.message_text.stringValue = _transaction.message;
        self.message_button.state = NSOnState;
    }
    else if (element.mode == CONVERSATION_CELL_VIEW_FILE_LIST)
    {
        // Do nothing
    }
    else if (element.mode == CONVERSATION_CELL_VIEW_NORMAL)
    {
        self.message_button.state = NSOffState;
        NSDictionary* info_attrs = [IAFunctions textStyleWithFont:[NSFont systemFontOfSize:12.0]
                                                   paragraphStyle:text_align
                                                           colour:IA_GREY_COLOUR(56.0)
                                                           shadow:nil];
        
        NSString* info;
        
        switch (_transaction.view_mode)
        {
            case TRANSACTION_VIEW_PENDING_SEND:
                break;
                
            case TRANSACTION_VIEW_WAITING_REGISTER:
                if (_transaction.from_me)
                {
                    info = NSLocalizedString(@"Waiting for user to register...",
                                             @"waiting for user to register");
                    self.information_text.attributedStringValue = [[NSAttributedString alloc]
                                                                   initWithString:info
                                                                   attributes:info_attrs];
                }
                break;
                
            case TRANSACTION_VIEW_WAITING_ONLINE:
                if (_transaction.from_me)
                {
                    info = NSLocalizedString(@"Waiting for user to be online...",
                                             @"waiting for user to be online");
                    self.information_text.attributedStringValue = [[NSAttributedString alloc]
                                                                   initWithString:info
                                                                   attributes:info_attrs];
                }
                break;
                
            case TRANSACTION_VIEW_WAITING_ACCEPT:
                if (_transaction.from_me)
                {
                    info = NSLocalizedString(@"Waiting for user to accept...",
                                             @"waiting for user to accept");
                    self.information_text.attributedStringValue = [[NSAttributedString alloc]
                                                                   initWithString:info
                                                                   attributes:info_attrs];
                }
                break;
                
            case TRANSACTION_VIEW_REJECTED:
                if (_transaction.from_me)
                {
                    info = NSLocalizedString(@"Send rejected", @"send rejected");
                    self.information_text.attributedStringValue = [[NSAttributedString alloc]
                                                                   initWithString:info
                                                                   attributes:info_attrs];
                }
                break;
            
            case TRANSACTION_VIEW_PREPARING:
                [self.progress_indicator setIndeterminate:YES];
                break;
                
            case TRANSACTION_VIEW_RUNNING:
                [self.progress_indicator setIndeterminate:NO];
                break;
            
            case TRANSACTION_VIEW_CANCELLED_OTHER:
                info = NSLocalizedString(@"Transaction cancelled", @"transaction cancelled");
                self.information_text.attributedStringValue = [[NSAttributedString alloc]
                                                               initWithString:info
                                                               attributes:info_attrs];
                break;
                
            case TRANSACTION_VIEW_CANCELLED_SELF:
                info = NSLocalizedString(@"Transaction cancelled", @"transaction cancelled");
                self.information_text.attributedStringValue = [[NSAttributedString alloc]
                                                               initWithString:info
                                                               attributes:info_attrs];
                break;
                
            case TRANSACTION_VIEW_FINISHED:
                // Do nothing
                break;
            
            case TRANSACTION_VIEW_FAILED:
                info = NSLocalizedString(@"Transfer failed", @"transfer failed");
                self.information_text.attributedStringValue = [[NSAttributedString alloc]
                                                               initWithString:info
                                                               attributes:info_attrs];
                break;
                            
            default:
                // Do nothing
                break;
        }
    }
}

//- Table Handling ---------------------------------------------------------------------------------

- (NSInteger)numberOfRowsInTableView:(NSTableView*)tableView
{
    return _transaction.files_count;
}

- (id)tableView:(NSTableView*)tableView
objectValueForTableColumn:(NSTableColumn*)tableColumn
            row:(NSInteger)row
{
    return _transaction.files[row];
}

- (CGFloat)tableView:(NSTableView*)tableView
         heightOfRow:(NSInteger)row
{
    return 15.0;
}

//- Button Handling --------------------------------------------------------------------------------

@end
