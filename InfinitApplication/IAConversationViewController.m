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

//- Conversation Row View --------------------------------------------------------------------------

@interface IAConversationRowView : NSTableRowView
@end

@implementation IAConversationRowView

- (BOOL)isOpaque
{
    return YES;
}

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

@synthesize user = _user;

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
#ifdef IA_CORE_ANIMATION_ENABLED
        [self.view setWantsLayer:YES];
        [self.view setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawOnSetNeedsDisplay];
#endif
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
    [self.person_view setDelegate:self];
    
    self.avatar_view.image = [IAFunctions makeRoundAvatar:[IAAvatarManager getAvatarForUser:_user
                                                                            andLoadIfNeeded:YES]
                                               ofDiameter:50.0
                                    withBorderOfThickness:2.0
                                                 inColour:IA_GREY_COLOUR(255.0)
                                        andShadowOfRadius:2.0];
    
    NSFont* name_font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica"
                                                                   traits:NSUnboldFontMask
                                                                   weight:7
                                                                     size:13.0];
    NSDictionary* name_attrs = [IAFunctions textStyleWithFont:name_font
                                               paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                                       colour:IA_GREY_COLOUR(29.0)
                                                       shadow:nil];
    NSAttributedString* name_str = [[NSAttributedString alloc] initWithString:_user.fullname
                                                                   attributes:name_attrs];
    self.user_fullname.attributedStringValue = name_str;
    
    NSFont* handle_font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica"
                                                                     traits:NSUnboldFontMask
                                                                     weight:0
                                                                       size:11.5];
    NSDictionary* handle_attrs = [IAFunctions
                                  textStyleWithFont:handle_font
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
    
    if (_user.is_favourite)
    {
        self.user_favourite.image = [IAFunctions imageNamed:@"icon-star-selected"];
        [self.user_favourite setToolTip:NSLocalizedString(@"Remove user as favourite",
                                                          @"remove user as favourite")];
    }
    else
    {
        self.user_favourite.image = [IAFunctions imageNamed:@"icon-star"];
        [self.user_favourite setToolTip:NSLocalizedString(@"Add user as favourite",
                                                          @"add user as favourite")];
    }
}

- (void)awakeFromNib
{
    // Workaround for 15" Macbook Pro always rendering scroll bars
    // http://www.cocoabuilder.com/archive/cocoa/317591-can-hide-scrollbar-on-nstableview.html
    [self.table_view.enclosingScrollView setScrollerStyle:NSScrollerStyleOverlay];
    [self.table_view.enclosingScrollView.verticalScroller setControlSize:NSSmallControlSize];
}

- (void)loadView
{
    [super loadView];
    [self setupPersonView];
    [self generateUserTransactionList];
    
    [self.table_view reloadData];
    [self resizeContentView];
    [self.table_view scrollRowToVisible:(self.table_view.numberOfRows - 1)];
    [self updateListOfRowsWithProgress];
    
#ifndef BUILD_PRODUCTION
    
    [self.table_view setTarget:self];
    [self.table_view setAction:@selector(tableViewAction:)];
    
#endif
    
}

//- Progress Update Functions ----------------------------------------------------------------------

- (void)setUpdatorRunning:(BOOL)is_running
{
	if (is_running && _progress_timer == nil)
		_progress_timer = [NSTimer scheduledTimerWithTimeInterval:1.5
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
    
    NSUInteger row = 0; // Start with the bottom transaction and work up
    for (IAConversationElement* element in _element_list)
    {
        if (element.mode != CONVERSATION_CELL_VIEW_SPACER &&
            element.transaction.view_mode == TRANSACTION_VIEW_RUNNING)
        {
            [_rows_with_progress addObject:[NSNumber numberWithUnsignedInteger:row]];
        }
        row++;
    }
    
    if (_rows_with_progress.count > 0)
        [self setUpdatorRunning:YES];
    else
        [self setUpdatorRunning:NO];
}

- (void)updateProgress
{
    for (NSNumber* row in _rows_with_progress)
    {
        if (row.integerValue < _element_list.count)
        {
            IAConversationCellView* cell = [self.table_view viewAtColumn:0
                                                                     row:row.unsignedIntegerValue
                                                             makeIfNecessary:NO];
            [cell updateProgress];
        }
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
                                andShadowOfRadius:1.0];
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
    NSMutableArray* important_elements = [NSMutableArray array];
    for (IATransaction* transaction in transaction_list)
    {
        // Important transactions must be at bottom of list
        if (transaction.is_active || transaction.is_new || transaction.needs_action)
        {
            IAConversationElement* element = [[IAConversationElement alloc]
                                              initWithTransaction:transaction];
            [important_elements addObject:element];
        }
        else
        {
            IAConversationElement* element = [[IAConversationElement alloc]
                                              initWithTransaction:transaction];
            [_element_list addObject:element];
        }
    }
    // Place important elements at bottom of list
    [_element_list addObjectsFromArray:important_elements];
}

- (void)generateUserTransactionList
{
    IAConversationElement* spacer_element = [[IAConversationElement alloc] initWithTransaction:nil];
    spacer_element.mode = CONVERSATION_CELL_VIEW_SPACER;
    [_element_list addObject:spacer_element];
}

- (void)scrollAfterRowAdd
{
    [self.table_view scrollRowToVisible:(self.table_view.numberOfRows - 1)];
}

- (void)backToNotificationView
{
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
     {
         context.duration = 0.15;
         [self.content_height_constraint.animator setConstant:NSHeight(self.person_view.frame)];
     }
                        completionHandler:^
     {
         [_delegate conversationViewWantsBack:self];
     }];
}

//- Table Functions --------------------------------------------------------------------------------

- (void)resizeContentView
{
    if (self.content_height_constraint.constant == NSHeight(self.person_view.frame) + _max_table_height)
        return;
    
    CGFloat new_height = NSHeight(self.person_view.frame) + [self tableHeight];
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
     {
         context.duration = 0.15;
     }
                        completionHandler:^
     {
         [self.content_height_constraint.animator setConstant:new_height];
     }];
}

- (CGFloat)tableHeight
{
    CGFloat total_height = IA_CONVERSATION_VIEW_SPACER_SIZE;
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
        
        case CONVERSATION_CELL_VIEW_SPACER:
            cell = [self.table_view makeViewWithIdentifier:@"conversation_spacer"
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
                
                case TRANSACTION_VIEW_ACCEPTED_WAITING_ONLINE:
                    cell = [self.table_view makeViewWithIdentifier:
                            [NSString stringWithFormat:@"conversation_cell_message_cancel_%@",
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
            break;
            
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
    [self backToNotificationView];
}

- (IBAction)favouriteButtonClicked:(NSButton*)sender
{
    if (_user.is_favourite)
    {
        [_delegate conversationView:self wantsRemoveFavourite:_user];
        self.user_favourite.image = [IAFunctions imageNamed:@"icon-star"];
        [self.user_favourite setToolTip:NSLocalizedString(@"Add user as favourite",
                                                          @"add user as favourite")];
    }
    else
    {
        [_delegate conversationView:self wantsAddFavourite:_user];
        self.user_favourite.image = [IAFunctions imageNamed:@"icon-star-selected"];
        [self.user_favourite setToolTip:NSLocalizedString(@"Remove user as favourite",
                                                          @"remove user as favourite")];
    }
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
    if (row == _element_list.count - 2) // Scroll to spacer at bottom if it's the last file
        [self.table_view scrollRowToVisible:(self.table_view.numberOfRows - 1)];
    else
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
    if (row == _element_list.count - 2) // Scroll to spacer at bottom if it's the last file
        [self.table_view scrollRowToVisible:(self.table_view.numberOfRows - 1)];
    else
        [self.table_view scrollRowToVisible:row];
}

- (IBAction)transferButtonClicked:(NSButton*)sender
{
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
     {
         context.duration = 0.15;
         [self.content_height_constraint.animator setConstant:72.0];
         [self.table_view removeFromSuperview];
     }
                        completionHandler:^
     {
         [_delegate conversationView:self wantsTransferForUser:_user];
     }];
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

//- Conversation Header View -----------------------------------------------------------------------

- (void)conversationHeaderGotClick:(IAConversationHeaderView*)sender
{
    [self backToNotificationView];
}

//- User Table Interaction -------------------------------------------------------------------------

#ifndef BUILD_PRODUCTION
- (IBAction)tableViewAction:(NSTableView*)sender
{
    NSInteger row = [self.table_view clickedRow];
    if (row < 0 || row > _element_list.count - 1)
        return;
    
    IATransaction* transaction = [_element_list[row] transaction];
    NSString* message = [NSString stringWithFormat:@"row number: %ld\n%@", row, transaction.description];
    NSAlert* popup = [NSAlert alertWithMessageText:@"Transaction"
                                     defaultButton:@"OK"
                                   alternateButton:nil
                                       otherButton:nil
                         informativeTextWithFormat:@"%@", message];
    [popup runModal];
}
#endif

//- Transaction Callbacks --------------------------------------------------------------------------

- (void)transactionAdded:(IATransaction*)transaction
{
    if (![transaction.other_user isEqual:_user])
        return;
    
    IAConversationElement* element = [[IAConversationElement alloc] initWithTransaction:transaction];
    [self.table_view beginUpdates];
    NSUInteger list_bottom = _element_list.count - 1;
    [_element_list insertObject:element atIndex:list_bottom];
    [self.table_view insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:list_bottom]
                           withAnimation:NSTableViewAnimationSlideDown];
    [self.table_view endUpdates];
    [self resizeContentView];
    
    // XXX Scrolling before row animation is complete doesn't scroll properly
    [self performSelector:@selector(scrollAfterRowAdd)
               withObject:nil
               afterDelay:0.2];
    
    [self updateListOfRowsWithProgress];
}

- (void)transactionUpdated:(IATransaction*)transaction
{
    if (![transaction.other_user isEqual:_user])
        return;

    NSUInteger count = 0;
    for (IAConversationElement* element in _element_list)
    {
        if ([element.transaction.transaction_id isEqualToNumber:transaction.transaction_id])
            break;
        count++;
    }
    
    if (count >= _element_list.count)
        return;

    IAConversationElement* element = [[IAConversationElement alloc] initWithTransaction:transaction];
    element.historic = NO; // We want to keep it the same colour that it was before updating
    [self.table_view beginUpdates];
    [self.table_view removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:count]
                           withAnimation:NSTableViewAnimationSlideRight];
    [_element_list removeObjectAtIndex:count];
    [_element_list insertObject:element atIndex:count];
    [self.table_view insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:count]
                           withAnimation:NSTableViewAnimationSlideLeft];
    [self.table_view endUpdates];
    [self resizeContentView];

    if (count == _element_list.count - 2)
        [self.table_view scrollRowToVisible:(_element_list.count - 1)];
    else
        [self.table_view scrollRowToVisible:count];
    [self updateListOfRowsWithProgress];
}

//- User Callbacks ---------------------------------------------------------------------------------

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
    [_delegate conversationView:self wantsMarkTransactionsReadForUser:_user];
}

@end
