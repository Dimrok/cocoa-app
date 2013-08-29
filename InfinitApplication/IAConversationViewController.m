//
//  IAConversationViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/5/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAConversationViewController.h"

#import "IAAvatarManager.h"
#import "IAConversationCellView.h"
#import "IAConversationElement.h"

@interface IAConversationViewController ()

@end

//- Conversation Header View -----------------------------------------------------------------------

@interface IAConversationHeaderView : NSView
@end

@implementation IAConversationHeaderView

- (void)drawRect:(NSRect)dirtyRect
{
    // White background
    NSBezierPath* white_bg = [NSBezierPath bezierPathWithRect:
                                                        NSMakeRect(0.0,
                                                                   2.0,
                                                                   self.bounds.size.width,
                                                                   self.bounds.size.height - 2.0)];
    [IA_GREY_COLOUR(255.0) set];
    [white_bg fill];
    
    // Grey line
    NSBezierPath* grey_line = [NSBezierPath bezierPathWithRect:NSMakeRect(0.0,
                                                                          1.0,
                                                                          self.bounds.size.width,
                                                                          1.0)];
    [IA_GREY_COLOUR(223.0) set];
    [grey_line fill];
    
    // White line
    NSBezierPath* white_line = [NSBezierPath bezierPathWithRect:NSMakeRect(0.0,
                                                                           0.0,
                                                                           self.bounds.size.width,
                                                                           1.0)];
    [IA_GREY_COLOUR(255.0) set];
    [white_line fill];
}

@end

//- Conversation Row View --------------------------------------------------------------------------

@interface IAConversationRowView : NSTableRowView
@end

@implementation IAConversationRowView

@end

//- Conversation View Controller -------------------------------------------------------------------

@implementation IAConversationViewController
{
@private
    id<IAConversationViewProtocol> _delegate;
    
    IAUser* _user;
    NSMutableArray* _element_list;
    NSMutableArray* _rows_with_progress;
    CGFloat _max_table_height;
    NSTimer* _progress_timer;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithDelegate:(id<IAConversationViewProtocol>)delegate
              andUser:(IAUser*)user
{
    if (self = [super initWithNibName:self.className bundle:nil])
    {
        _delegate = delegate;
        _user = user;
        _max_table_height = 290.0;
        [self getReversedTransactionList];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(avatarReceivedCallback:)
                                                   name:IA_AVATAR_MANAGER_AVATAR_FETCHED
                                                 object:nil];
    }
    return self;
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (BOOL)closeOnFocusLost
{
    return YES;
}

- (void)setupPersonView
{
    self.avatar_view.image = [IAFunctions makeRoundAvatar:[IAAvatarManager getAvatarForUser:_user
                                                                            andLoadIfNeeded:YES]
                                               ofDiameter:50.0
                                    withBorderOfThickness:3.0
                                                 inColour:IA_GREY_COLOUR(255.0)
                                        andShadowOfRadius:1.0];
    NSDictionary* name_attrs = [IAFunctions textStyleWithFont:[NSFont boldSystemFontOfSize:12.0]
                                               paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                                       colour:IA_GREY_COLOUR(29.0)
                                                       shadow:nil];
    NSAttributedString* name_str = [[NSAttributedString alloc] initWithString:_user.fullname
                                                                   attributes:name_attrs];
    self.user_fullname.attributedStringValue = name_str;
    NSDictionary* handle_attrs = [IAFunctions
                                  textStyleWithFont:[NSFont systemFontOfSize:11.0]
                                  paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                  colour:IA_GREY_COLOUR(193.0)
                                  shadow:nil];
    NSAttributedString* handle_str = [[NSAttributedString alloc] initWithString:_user.handle
                                                                     attributes:handle_attrs];
    self.user_handle.attributedStringValue = handle_str;
    if (_user.status == gap_user_status_online)
        [self.user_online setHidden:NO];
    else
        [self.user_online setHidden:YES];
}

- (void)awakeFromNib
{
    [self setupPersonView];
}

- (void)loadView
{
    [super loadView];
    CGFloat y_diff = (self.person_view.frame.size.height + [self tableHeight]) -
    self.main_view.frame.size.height;
    [self.content_height_constraint.animator setConstant:(y_diff +
                                                          self.content_height_constraint.constant)];
    _element_list = nil; // XXX work around for crash on calling layout
    [self.view layoutSubtreeIfNeeded];
    [self generateUserTransactionList];
}

//- Progress Update Functions ----------------------------------------------------------------------

- (void)setUpdatorRunning:(BOOL)is_running
{
	if (is_running && _progress_timer == nil)
		_progress_timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                           target:self
                                                         selector:@selector(updateProgress)
                                                         userInfo:nil
                                                          repeats:YES];
	else if (!is_running && _progress_timer != nil)
	{
		[_progress_timer invalidate];
		_progress_timer = nil;
	}
}

- (void)updateListOfRowsWithProgress
{
    if (_rows_with_progress == nil)
        _rows_with_progress = [NSMutableArray array];
    else
        [_rows_with_progress removeAllObjects];
    
    for (IAConversationElement* element in _element_list)
    {
        NSUInteger row = 0;
        if (element.transaction.view_mode == TRANSACTION_VIEW_RUNNING)
            [_rows_with_progress addObject:[NSNumber numberWithUnsignedInteger:row++]];
    }
    
    if (_rows_with_progress.count > 0)
        [self setUpdatorRunning:YES];
    else
    {
        [self updateProgress]; // Update progress for case that transfer has finished
        [self setUpdatorRunning:NO];
    }
}

- (void)updateProgress
{
    for (NSNumber* row in _rows_with_progress)
    {
        IAConversationCellView* cell = [self.table_view viewAtColumn:0
                                                                 row:row.unsignedIntegerValue
                                                         makeIfNecessary:NO];
        [cell updateProgress];
    }
}

//- Avatar Callback --------------------------------------------------------------------------------

- (void)avatarReceivedCallback:(NSNotification*)notification
{
    IAUser* user = [notification.userInfo objectForKey:@"user"];
    if (user == _user)
        self.avatar_view.image = [IAFunctions
                                  makeRoundAvatar:[IAAvatarManager getAvatarForUser:_user
                                                                    andLoadIfNeeded:YES]
                                       ofDiameter:50.0
                            withBorderOfThickness:2.0
                                         inColour:IA_GREY_COLOUR(255.0)
                                andShadowOfRadius:2.0];
}

//- General Functions ------------------------------------------------------------------------------

- (void)getReversedTransactionList
{
    NSArray* user_transactions = [_delegate conversationView:self
                                    wantsTransactionsForUser:_user];
    NSSortDescriptor* ascending = [NSSortDescriptor sortDescriptorWithKey:nil
                                                                ascending:YES
                                                                 selector:@selector(compare:)];
    NSArray* transaction_list;
    transaction_list = [user_transactions sortedArrayUsingDescriptors:
                        [NSArray arrayWithObject:ascending]];
    _element_list = [NSMutableArray array];
    for (IATransaction* transaction in transaction_list)
    {
        IAConversationElement* element = [[IAConversationElement alloc]
                                          initWithTransaction:transaction];
        [_element_list addObject:element];
    }
}

- (void)generateUserTransactionList
{
    [self getReversedTransactionList];
    [self.table_view reloadData];
    [self resizeContentView];
    [self.table_view scrollRowToVisible:(_element_list.count - 1)];
    [self updateListOfRowsWithProgress];
}

//- Table Functions --------------------------------------------------------------------------------

- (void)resizeContentView
{
    CGFloat y_diff = [self tableHeight] - self.content_height_constraint.constant;
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
     {
         context.duration = 0.25;
         [self.content_height_constraint.animator setConstant:(y_diff +
                                                        self.content_height_constraint.constant)];
     }
                        completionHandler:^
     {
         [self.view layoutSubtreeIfNeeded];
     }];
}

- (CGFloat)tableHeight
{
    CGFloat total_height = 0.0;
    for (NSInteger i = 0; i < _element_list.count; i++)
    {
        total_height += [self tableView:self.table_view heightOfRow:i];
    }
    if (total_height > _max_table_height)
        return _max_table_height;
    else
        return total_height;
}

- (CGFloat)tableView:(NSTableView*)tableView
         heightOfRow:(NSInteger)row
{
    return [IAConversationCellView heightOfCellWithElement:_element_list[row]];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView*)tableView
{
    return _element_list.count;
}

- (NSView*)tableView:(NSTableView*)tableView
  viewForTableColumn:(NSTableColumn*)tableColumn
                 row:(NSInteger)row
{
    IAConversationElement* element = _element_list[row];
    IAConversationCellView* cell;
    
    NSString* left_right_select;
    if (element.transaction.from_me)
        left_right_select = @"right";
    else
        left_right_select = @"left";
    
    switch (element.mode)
    {
        case CONVERSATION_CELL_VIEW_MESSAGE:
            cell = [self.table_view makeViewWithIdentifier:
                    [NSString stringWithFormat:@"conversation_cell_message_%@", left_right_select]
                                         owner:self];
            break;
        
        case CONVERSATION_CELL_VIEW_FILE_LIST:
            cell = [self.table_view makeViewWithIdentifier:
                    [NSString stringWithFormat:@"conversation_cell_none_files_%@", left_right_select]
                                         owner:self];
            break;
            
        case CONVERSATION_CELL_VIEW_NORMAL:
            switch (element.transaction.view_mode)
            {
                case TRANSACTION_VIEW_PENDING_SEND:
                    cell = [self.table_view makeViewWithIdentifier:
                            [NSString stringWithFormat:@"conversation_cell_none_%@",
                             left_right_select]
                                                             owner:self];
                    break;
                
                case TRANSACTION_VIEW_WAITING_REGISTER:
                    cell = [self.table_view makeViewWithIdentifier:
                            [NSString stringWithFormat:@"conversation_cell_message_cancel_%@",
                             left_right_select]
                                                             owner:self];
                    break;
                    
                case TRANSACTION_VIEW_WAITING_ONLINE:
                    cell = [self.table_view makeViewWithIdentifier:
                            [NSString stringWithFormat:@"conversation_cell_message_cancel_%@",
                             left_right_select]
                                                             owner:self];
                    break;

                case TRANSACTION_VIEW_WAITING_ACCEPT:
                    if (element.transaction.from_me)
                    {
                        cell = [self.table_view makeViewWithIdentifier:
                                [NSString stringWithFormat:@"conversation_cell_message_cancel_%@",
                                 left_right_select]
                                                                 owner:self];
                    }
                    else
                    {
                        cell = [self.table_view makeViewWithIdentifier:
                                [NSString stringWithFormat:@"conversation_cell_buttons_%@",
                                 left_right_select]
                                                                 owner:self];
                    }
                    break;
                
                case TRANSACTION_VIEW_REJECTED:
                    cell = [self.table_view makeViewWithIdentifier:
                            [NSString stringWithFormat:@"conversation_cell_info_%@",
                             left_right_select]
                                                             owner:self];
                    break;
                    
                case TRANSACTION_VIEW_PREPARING:
                    cell = [self.table_view makeViewWithIdentifier:
                            [NSString stringWithFormat:@"conversation_cell_progress_%@",
                             left_right_select]
                                                             owner:self];
                    break;
                
                case TRANSACTION_VIEW_RUNNING:
                    cell = [self.table_view makeViewWithIdentifier:
                            [NSString stringWithFormat:@"conversation_cell_progress_%@",
                             left_right_select]
                                                             owner:self];
                    break;
                    
                case TRANSACTION_VIEW_FINISHED:
                    cell = [self.table_view makeViewWithIdentifier:
                            [NSString stringWithFormat:@"conversation_cell_none_%@",
                                                       left_right_select]
                                                             owner:self];
                    break;
                    
                case TRANSACTION_VIEW_CANCELLED_SELF:
                    cell = [self.table_view makeViewWithIdentifier:
                            [NSString stringWithFormat:@"conversation_cell_info_%@",
                             left_right_select]
                                                             owner:self];
                    break;
                    
                case TRANSACTION_VIEW_CANCELLED_OTHER:
                    cell = [self.table_view makeViewWithIdentifier:
                            [NSString stringWithFormat:@"conversation_cell_info_%@",
                             left_right_select]
                                                             owner:self];
                    break;
                    
                case TRANSACTION_VIEW_FAILED:
                    cell = [self.table_view makeViewWithIdentifier:
                            [NSString stringWithFormat:@"conversation_cell_info_%@",
                             left_right_select]
                                                             owner:self];
                    break;
                    
                default:
                    cell = [self.table_view makeViewWithIdentifier:
                            [NSString stringWithFormat:@"conversation_cell_none_%@",
                                                       left_right_select]
                                                             owner:self];
                    break;
            }
            
        default:
            break;
    }
    [cell setupCellWithElement:element];
    return cell;
}

- (NSTableRowView*)tableView:(NSTableView*)tableView
               rowViewForRow:(NSInteger)row
{
    IAConversationRowView* row_view = [self.table_view rowViewAtRow:row makeIfNecessary:YES];
    if (row_view == nil)
        row_view = [[IAConversationRowView alloc] initWithFrame:NSZeroRect];
    return row_view;
}

//- Button Handling --------------------------------------------------------------------------------

- (IBAction)backButtonClicked:(NSButton*)sender
{
    [_delegate conversationViewWantsBack:self];
}

- (IBAction)collapseFilesClicked:(NSButton*)sender
{
    NSUInteger row = [self.table_view rowForView:sender];
    
    IAConversationElement* element = _element_list[row];
    
    element.mode = CONVERSATION_CELL_VIEW_NORMAL;
    [self.table_view beginUpdates];
    [_element_list replaceObjectAtIndex:row
                             withObject:element];
    [self.table_view reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row]
                               columnIndexes:[NSIndexSet indexSetWithIndex:0]];
    [self.table_view endUpdates];
    [self.table_view noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:row]];
    [self resizeContentView];
    [self.table_view scrollRowToVisible:row];
}

- (IBAction)expandFilesClicked:(NSButton*)sender
{
    NSUInteger row = [self.table_view rowForView:sender];
    
    IAConversationElement* element = _element_list[row];
    if (element.transaction.files_count == 1)
        return;
    
    element.mode = CONVERSATION_CELL_VIEW_FILE_LIST;
    [self.table_view beginUpdates];
    [_element_list replaceObjectAtIndex:row
                             withObject:element];
    [self.table_view reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row]
                               columnIndexes:[NSIndexSet indexSetWithIndex:0]];
    [self.table_view endUpdates];
    [self.table_view noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:row]];
    [self resizeContentView];
    [self.table_view scrollRowToVisible:row];
}

- (IBAction)transferButtonClicked:(NSButton*)sender
{
    [_delegate conversationView:self wantsTransferForUser:_user];
}

- (IBAction)messageButtonClicked:(NSButton*)sender
{
    NSUInteger row = [self.table_view rowForView:sender];
    
    IAConversationElement* element = _element_list[row];
    
    if (element.mode == CONVERSATION_CELL_VIEW_MESSAGE)
        element.mode = CONVERSATION_CELL_VIEW_NORMAL;
    else
        element.mode = CONVERSATION_CELL_VIEW_MESSAGE;
    
    [self.table_view beginUpdates];
    [_element_list replaceObjectAtIndex:row
                             withObject:element];
    [self.table_view removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:row]
                           withAnimation:NSTableViewAnimationSlideRight];
    [self.table_view insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:row]
                           withAnimation:NSTableViewAnimationSlideLeft];
    [self.table_view scrollRowToVisible:row];
    [self.table_view endUpdates];
    [self.table_view noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:row]];
    [self resizeContentView];
}

- (IBAction)acceptButtonClicked:(NSButton*)sender
{
    NSUInteger row = [self.table_view rowForView:sender];
    IAConversationElement* element = _element_list[row];
    [_delegate conversationView:self
         wantsAcceptTransaction:element.transaction];
}

- (IBAction)cancelButtonClicked:(NSButton*)sender
{
    NSUInteger row = [self.table_view rowForView:sender];
    IAConversationElement* element = _element_list[row];
    [_delegate conversationView:self
         wantsCancelTransaction:element.transaction];
}

- (IBAction)rejectButtonClicked:(NSButton*)sender
{
    NSUInteger row = [self.table_view rowForView:sender];
    IAConversationElement* element = _element_list[row];
    [_delegate conversationView:self
         wantsRejectTransaction:element.transaction];
}

//- Transaction Callbacks --------------------------------------------------------------------------

- (void)transactionAdded:(IATransaction*)transaction
{
    if (![transaction.other_user isEqual:_user])
        return;
    
    IAConversationElement* element = [[IAConversationElement alloc] initWithTransaction:transaction];
    [self.table_view beginUpdates];
    [_element_list addObject:element];
    NSUInteger list_bottom = _element_list.count - 1;
    [self.table_view insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:list_bottom]
                           withAnimation:NSTableViewAnimationSlideDown];
    [self.table_view endUpdates];
    [self.table_view scrollRowToVisible:list_bottom];
    [self resizeContentView];

    [self updateListOfRowsWithProgress];
}

- (void)transactionUpdated:(IATransaction*)transaction
{
    if (![transaction.other_user isEqual:_user])
        return;
    
    NSUInteger count = 0;
    for (IAConversationElement* element in _element_list)
    {
        if (element.transaction.transaction_id == transaction.transaction_id)
            break;
        count++;
    }
    
    if ([_element_list[count] transaction].view_mode == transaction.view_mode)
        return;
    
    IAConversationElement* element = [[IAConversationElement alloc] initWithTransaction:transaction];
    [self.table_view beginUpdates];
    [self.table_view removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:count]
                           withAnimation:NSTableViewAnimationSlideLeft];
    [_element_list removeObjectAtIndex:count];
    [_element_list insertObject:element atIndex:count];
    [self.table_view insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:count]
                           withAnimation:NSTableViewAnimationSlideRight];
    [self.table_view endUpdates];
    [self.table_view scrollRowToVisible:count];
    [self resizeContentView];

    [self updateListOfRowsWithProgress];
}

//- User callbacks ---------------------------------------------------------------------------------

- (void)userUpdated:(IAUser*)user
{
    if (![user isEqual:_user])
        return;
    
    [self setupPersonView];
}

//- Change View Handling ---------------------------------------------------------------------------

- (void)aboutToChangeView
{
    [self setUpdatorRunning:NO];
}

@end
