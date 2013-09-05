//
//  IAConversationCellView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/15/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAConversationCellView.h"

//- Clickable Text Field ---------------------------------------------------------------------------

@interface IAClickableTextField : NSTextField
@end

@implementation IAClickableTextField

- (void)mouseDown:(NSEvent*)theEvent
{
    [self sendAction:self.action to:self.target];
}

@end

//- Conversation Bubble View -----------------------------------------------------------------------

@implementation IAConversationBubbleView

- (void)drawRect:(NSRect)dirtyRect
{
    // Grey border
    NSBezierPath* grey_border = [NSBezierPath bezierPathWithRoundedRect:self.bounds
                                                                xRadius:4.0
                                                                yRadius:4.0];
    [IA_GREY_COLOUR(212.0) set];
    [grey_border stroke];
    
    // White background
    NSBezierPath* white_bg = [NSBezierPath bezierPathWithRoundedRect:
                              NSMakeRect(1.0,
                                         1.0,
                                         self.bounds.size.width - 2.0,
                                         self.bounds.size.height - 2.0)
                                                             xRadius:4.0
                                                             yRadius:4.0];
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
    CGFloat normal = 66.0;
    CGFloat message = 110.0;
    CGFloat file_list = normal;
    CGFloat spacer = 25.0;
    if (element.transaction.files_count > 3)
    {
        file_list += 14.0 + 15.0 * 3;
    }
    else
    {
        file_list += 14.0 + 15.0 * element.transaction.files_count;
    }
    CGFloat buttons = 92.0;
    CGFloat progress = 92.0;
    CGFloat error = 92.0;
    switch (element.mode)
    {
        case CONVERSATION_CELL_VIEW_MESSAGE:
            return message;

        case CONVERSATION_CELL_VIEW_FILE_LIST:
            return file_list;
            
        case CONVERSATION_CELL_VIEW_SPACER:
            return spacer;
            
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
                    
                case TRANSACTION_VIEW_ACCEPTED_WAITING_ONLINE:
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
    if (element.transaction == nil) // Spacer element
        return;
    
    _transaction = element.transaction;
    
    NSMutableParagraphStyle* text_align = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    if (element.on_left)
        text_align.alignment = NSLeftTextAlignment;
    else
        text_align.alignment = NSRightTextAlignment;
    
    if (_transaction.message.length == 0)
        [self.message_button setHidden:YES];
    else
        [self.message_button setHidden:NO];
    
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
    
    if (!_transaction.from_me && _transaction.view_mode == TRANSACTION_VIEW_FINISHED)
    {
        self.files_label.action = @selector(finishedFileClicked);
        self.files_label.target = self;
    }
    
    if (element.mode == CONVERSATION_CELL_VIEW_MESSAGE)
    {
        NSDictionary* note_attrs = [IAFunctions textStyleWithFont:[NSFont systemFontOfSize:11.5]
                                                   paragraphStyle:text_align
                                                           colour:IA_GREY_COLOUR(184.0)
                                                           shadow:nil];
        NSAttributedString* note_str = [[NSAttributedString alloc] initWithString:_transaction.message
                                                                       attributes:note_attrs];
        self.message_text.attributedStringValue = note_str;
        self.message_button.state = NSOnState;
    }
    else if (element.mode == CONVERSATION_CELL_VIEW_FILE_LIST)
    {
        self.files_icon.image = [IAFunctions imageNamed:@"icon-collapse"];
    }
    else if (element.mode == CONVERSATION_CELL_VIEW_NORMAL)
    {
        if (_transaction.files_count > 1)
        {
            NSString* side;
            if (element.on_left)
                side = @"left";
            else
                side = @"right";
            self.files_icon.image = [IAFunctions imageNamed:[NSString
                                                             stringWithFormat:@"icon-expand-%@", side]];
        }
        
        self.message_button.state = NSOffState;
        NSDictionary* info_attrs = [IAFunctions textStyleWithFont:[NSFont systemFontOfSize:12.0]
                                                   paragraphStyle:text_align
                                                           colour:IA_GREY_COLOUR(204.0)
                                                           shadow:nil];
        
        NSDictionary* error_attrs = [IAFunctions
                                     textStyleWithFont:[NSFont systemFontOfSize:12.0]
                                     paragraphStyle:text_align
                                     colour:IA_RGB_COLOUR(222.0, 104.0, 81.0)
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
                
            case TRANSACTION_VIEW_ACCEPTED_WAITING_ONLINE:
                if (_transaction.from_me)
                {
                    info = NSLocalizedString(@"Waiting for user to be online...",
                                             @"Waiting for user to be online");
                    self.information_text.attributedStringValue = [[NSAttributedString alloc]
                                                                   initWithString:info
                                                                   attributes:info_attrs];
                }
                break;
            
            case TRANSACTION_VIEW_PREPARING:
                [self.progress_indicator setIndeterminate:YES];
                [self.progress_indicator startAnimation:nil];
                break;
                
            case TRANSACTION_VIEW_RUNNING:
                [self.progress_indicator stopAnimation:nil];
                self.progress_indicator.maxValue = 1.0;
                [self.progress_indicator setIndeterminate:NO];
                self.progress_indicator.doubleValue = _transaction.progress;
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
                                                               attributes:error_attrs];
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

//- User Interaction Handling ----------------------------------------------------------------------

- (void)finishedFileClicked
{
    NSString* download_dir = [NSHomeDirectory() stringByAppendingPathComponent:@"/Downloads"];
    NSMutableArray* file_urls = [NSMutableArray array];
    for (NSString* filename in _transaction.files)
    {
        NSString* file_path = [download_dir stringByAppendingPathComponent:filename];
        if ([[NSFileManager defaultManager] fileExistsAtPath:file_path])
        {
            [file_urls addObject:[[NSURL fileURLWithPath:file_path] absoluteURL]];
        }
    }
    if (file_urls.count > 0)
        [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:file_urls];
}

@end
