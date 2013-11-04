//
//  IANotificationListViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 7/31/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IANotificationListViewController.h"

#import <QuartzCore/QuartzCore.h>

#import <Gap/version.h>

#import "IAAvatarManager.h"

#define IA_FEEDBACK_LINK "http://feedback.infinit.io"
#define IA_PROFILE_LINK "http://infinit.io/account"

@interface IANotificationListViewController ()
@end

//- Notification List Row View ---------------------------------------------------------------------

@interface IANotificationListRowView : NSTableRowView

@property (nonatomic, readwrite, setter = setUnread:) BOOL unread;
@property (nonatomic, readwrite, setter = setClicked:) BOOL clicked;

@end

@implementation IANotificationListRowView

@synthesize unread = _unread;
@synthesize clicked = _clicked;

- (void)setUnread:(BOOL)unread
{
    _unread = unread;
    [self setNeedsDisplay:YES];
}

- (void)setClicked:(BOOL)clicked
{
    _clicked = clicked;
    [self setNeedsDisplay:YES];
}

- (BOOL)isFlipped
{
    return NO;
}

- (void)drawRect:(NSRect)dirtyRect
{
    if (self.unread || self.clicked)
    {
        // White background
        NSRect white_bg_frame = NSMakeRect(self.bounds.origin.x,
                                           self.bounds.origin.y + 2.0,
                                           NSWidth(self.bounds),
                                           NSHeight(self.bounds) - 2.0);
        NSBezierPath* white_bg = [NSBezierPath bezierPathWithRect:white_bg_frame];
        [IA_GREY_COLOUR(255.0) set];
        [white_bg fill];
    }
    else
    {
        // Grey background
        NSRect grey_bg_frame = NSMakeRect(self.bounds.origin.x,
                                          self.bounds.origin.y + 2.0,
                                          NSWidth(self.bounds),
                                          NSHeight(self.bounds) - 2.0);
        NSBezierPath* grey_bg = [NSBezierPath bezierPathWithRect:grey_bg_frame];
        [IA_GREY_COLOUR(248.0) set];
        [grey_bg fill];
    }
    
    // White line
    NSRect white_line_frame = NSMakeRect(self.bounds.origin.x,
                                         1.0,
                                         NSWidth(self.bounds),
                                         1.0);
    NSBezierPath* white_line = [NSBezierPath bezierPathWithRect:white_line_frame];
    [IA_GREY_COLOUR(220.0) set];
    [white_line fill];
    
    // Grey line
    NSRect grey_line_frame = NSMakeRect(self.bounds.origin.x,
                                        0.0,
                                        NSWidth(self.bounds),
                                        1.0);
    NSBezierPath* grey_line = [NSBezierPath bezierPathWithRect:grey_line_frame];
    [IA_GREY_COLOUR(255.0) set];
    [grey_line fill];
}

@end;

@implementation IANotificationListViewController
{
@private
    id<IANotificationListViewProtocol> _delegate;
    
    CGFloat _row_height;
    NSInteger _max_rows_shown;
    NSMutableArray* _transaction_list;
    NSMutableArray* _rows_with_progress;
    NSTimer* _progress_timer;
    BOOL _changing;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithDelegate:(id<IANotificationListViewProtocol>)delegate
{
    if (self = [super initWithNibName:self.className bundle:nil])
    {
        _delegate = delegate;
        _row_height = 72.0;
        _max_rows_shown = 5;
        _transaction_list = [NSMutableArray
                             arrayWithArray:[_delegate notificationListWantsLastTransactions:self]];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(avatarCallback:)
                                                   name:IA_AVATAR_MANAGER_AVATAR_FETCHED
                                                 object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(boundsDidChange:)
                                                   name:NSViewBoundsDidChangeNotification
                                                 object:self.table_view.enclosingScrollView.contentView];
        _changing = NO;
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
    
    NSString* version_str = [NSString stringWithFormat:@"v%@",
                             [NSString stringWithUTF8String:INFINIT_VERSION]];
    _version_item.title = version_str;
    
    [self.table_view.enclosingScrollView.contentView setPostsBoundsChangedNotifications:YES];
    
    if (_transaction_list.count == 0)
    {
        [self.no_data_message setHidden:NO];
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
         {
             context.duration = 0.15;
             [self.content_height_constraint.animator setConstant:50.0];
         }
                            completionHandler:^
         {
         }];
    }
    else
    {
        [self.no_data_message setHidden:YES];
        [self.table_view reloadData];
        [self resizeContentView];
        [self updateListOfRowsWithProgress];
        IAUser* top_user = [_transaction_list[0] other_user];
        if ([_delegate notificationList:self unreadTransactionsForUser:top_user] > 0 ||
            [_delegate notificationList:self activeTransactionsForUser:top_user] > 0)
        {
            self.header_image.image = [IAFunctions imageNamed:@"bg-header-top-white"];
            self.table_view.backgroundColor = IA_GREY_COLOUR(255.0);
        }
    }
}

//- Avatar Callback --------------------------------------------------------------------------------

- (void)avatarCallback:(NSNotification*)notification
{
    IAUser* user = [notification.userInfo objectForKey:@"user"];
    for (IATransaction* transaction in _transaction_list)
    {
        if ([transaction.other_user isEqual:user])
        {
            [self.table_view reloadDataForRowIndexes:
                    [NSIndexSet indexSetWithIndex:[_transaction_list indexOfObject:transaction]]
                                    columnIndexes:[NSIndexSet indexSetWithIndex:0]];
        }
    }
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
    
    NSUInteger row = 0;
    for (IATransaction* transaction in _transaction_list)
    {
        if ([_delegate notificationList:self
        transferringTransactionsForUser:transaction.other_user])
        {
            [_rows_with_progress addObject:[NSNumber numberWithUnsignedInteger:row]];
        }
        row++;
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
        if (row.integerValue < _transaction_list.count)
        {
            IANotificationListCellView* cell = [self.table_view viewAtColumn:0
                                                                         row:row.unsignedIntegerValue
                                                             makeIfNecessary:NO];
            [cell setTotalTransactionProgress:[_delegate notificationList:self
                                              transactionsProgressForUser:
                                               [[_transaction_list objectAtIndex:
                                                 row.unsignedIntegerValue] other_user]]];
        }
    }
}

//- Table Functions --------------------------------------------------------------------------------

- (void)resizeContentView
{
    if (self.content_height_constraint.constant == [self tableHeight])
        return;
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
     {
         context.duration = 0.15;
         [self.content_height_constraint.animator setConstant:[self tableHeight]];
         
     }
                        completionHandler:^
     {
     }];
}

- (CGFloat)tableHeight
{
    CGFloat total_height = _transaction_list.count * _row_height;
    CGFloat max_height = _row_height * _max_rows_shown;
    if (total_height > max_height)
        return max_height;
    else
        return total_height;
}

- (BOOL)tableView:(NSTableView*)aTableView
  shouldSelectRow:(NSInteger)row
{
    return NO;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView*)tableView
{
    return _transaction_list.count;
}

- (CGFloat)tableView:(NSTableView*)tableView
         heightOfRow:(NSInteger)row
{
    return _row_height;
}

- (NSView*)tableView:(NSTableView*)tableView
  viewForTableColumn:(NSTableColumn*)tableColumn
                 row:(NSInteger)row
{
    IATransaction* transaction = [_transaction_list objectAtIndex:row];
    if (transaction.transaction_id.unsignedIntValue == gap_null())
        return nil;
    IANotificationListCellView* cell = [tableView makeViewWithIdentifier:@"notification_cell"
                                                                   owner:self];
    // Ensure that the cell is not reused as otherwise the round progress is drawn on multiple views.
    cell.identifier = nil;
    
    IAUser* user = transaction.other_user;
    
    NSUInteger unread_notifications = [_delegate notificationList:self unreadTransactionsForUser:user];
    NSUInteger active_transfers = [_delegate notificationList:self activeTransactionsForUser:user];
    
    [cell setupCellWithTransaction:transaction
            withRunningTransactions:active_transfers
            andUnreadNotifications:unread_notifications
                       andProgress:[_delegate notificationList:self transactionsProgressForUser:user]
                       andDelegate:self];
    IANotificationListRowView* row_view = [self.table_view rowViewAtRow:row makeIfNecessary:NO];
    if (unread_notifications > 0 || active_transfers > 0)
        row_view.unread = YES;
    else
        row_view.unread = NO;
    return cell;
}

- (NSTableRowView*)tableView:(NSTableView*)tableView
               rowViewForRow:(NSInteger)row
{
    IANotificationListRowView* row_view = [tableView rowViewAtRow:row makeIfNecessary:YES];
    if (row_view == nil)
        row_view = [[IANotificationListRowView alloc] initWithFrame:NSZeroRect];
    return row_view;
}

- (void)boundsDidChange:(NSNotification*)notification
{
    if (_changing)
        return;
    [self updateHeaderAndBackground];
}

- (void)updateHeaderAndBackground
{
    NSRange visible_rows = [self.table_view rowsInRect:self.table_view.visibleRect];
    IANotificationListRowView* row_view = [self.table_view rowViewAtRow:visible_rows.location
                                                        makeIfNecessary:NO];
    if (row_view.unread)
    {
        self.header_image.image = [IAFunctions imageNamed:@"bg-header-top-white"];
        self.table_view.backgroundColor = IA_GREY_COLOUR(255.0);
    }
    else
    {
        self.header_image.image = [IAFunctions imageNamed:@"bg-header-top-gray"];
        self.table_view.backgroundColor = IA_GREY_COLOUR(248.0);
    }
}

//- General Functions ------------------------------------------------------------------------------

- (void)userRowGotClicked:(NSInteger)row
{
    if (_changing)
        return;
    
    [self setUpdatorRunning:NO];
    
    _changing = YES;
    
    [[self.table_view rowViewAtRow:row makeIfNecessary:NO] setClicked:YES];
    
    IATransaction* transaction = _transaction_list[row];
    IAUser* user = transaction.other_user;
    
    NSRange visible_rows = [self.table_view rowsInRect:self.table_view.visibleRect];
    
    NSMutableIndexSet* invisible_users = [NSMutableIndexSet indexSetWithIndexesInRange:
                                          NSMakeRange(0, _transaction_list.count)];
    NSMutableIndexSet* visible_users = [NSMutableIndexSet indexSetWithIndexesInRange:visible_rows];
    [invisible_users removeIndexes:visible_users];
    
    [self.table_view beginUpdates];
    [_transaction_list removeObjectsAtIndexes:invisible_users];
    [self.table_view removeRowsAtIndexes:invisible_users
                           withAnimation:NSTableViewAnimationEffectNone];
    [self.table_view endUpdates];
    
    NSInteger new_row = [_transaction_list indexOfObject:transaction];
    NSMutableIndexSet* other_users = [NSMutableIndexSet indexSetWithIndexesInRange:
                                      NSMakeRange(0, _transaction_list.count)];
    [other_users removeIndex:new_row];
    
    self.table_view.backgroundColor = IA_GREY_COLOUR(255.0);
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
     {
         context.duration = 0.15;
         [self.table_view beginUpdates];
         [self.table_view moveRowAtIndex:new_row toIndex:0];
         [self.table_view endUpdates];
         [self.content_height_constraint.animator setConstant:_row_height];
         self.header_image.image = [IAFunctions imageNamed:@"bg-header-top-white"];
     }
                        completionHandler:^
     {
         [_delegate notificationList:self gotClickOnUser:user];
     }];
}

//- User Interaction With Table --------------------------------------------------------------------

- (IBAction)tableViewAction:(NSTableView*)sender
{
    NSInteger row = [self.table_view clickedRow];
    if (row < 0 || row > _transaction_list.count - 1)
        return;
    [self userRowGotClicked:row];
}

//- Button Handling --------------------------------------------------------------------------------

- (IBAction)settingsButtonClicked:(NSButton*)sender
{
    NSPoint point = NSMakePoint(sender.frame.origin.x + NSWidth(sender.frame),
                                sender.frame.origin.y);
    NSPoint menu_origin = [sender.superview convertPoint:point toView:nil];
    NSEvent* event = [NSEvent mouseEventWithType:NSLeftMouseDown
                                        location:menu_origin
                                   modifierFlags:NSLeftMouseDownMask
                                       timestamp:0
                                    windowNumber:sender.window.windowNumber
                                         context:sender.window.graphicsContext
                                     eventNumber:0
                                      clickCount:1
                                        pressure:1];
    [NSMenu popUpContextMenu:_gear_menu withEvent:event forView:sender];
}

- (IBAction)transferButtonClicked:(NSButton*)sender
{
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
     {
         context.duration = 0.15;
         if (self.content_height_constraint.constant > 72.0)
             [self.content_height_constraint.animator setConstant:72.0];
     }
                        completionHandler:^
     {
         [_delegate notificationListGotTransferClick:self];
     }];
}

//- Menu Handling ----------------------------------------------------------------------------------

- (IBAction)quitClicked:(NSMenuItem*)sender
{
     [_delegate notificationListWantsQuit:self];
}

- (IBAction)onFeedbackClick:(NSMenuItem*)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:
                                            [NSString stringWithUTF8String:IA_FEEDBACK_LINK]]];
}

- (IBAction)onProfileClick:(NSMenuItem*)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:
                                            [NSString stringWithUTF8String:IA_PROFILE_LINK]]];
}

- (IBAction)onReportProblemClick:(NSMenuItem*)sender
{
    [_delegate notificationListWantsReportProblem:self];
}

- (IBAction)onCheckForUpdateClick:(NSMenuItem*)sender
{
    [_delegate notificationListWantsCheckForUpdate:self];
}

//- Transaction Handling ---------------------------------------------------------------------------

- (void)updateBadgeForRow:(NSUInteger)row
{
    IANotificationListCellView* cell = [self.table_view viewAtColumn:0
                                                                 row:row
                                                     makeIfNecessary:NO];
    if (cell == nil)
        return;
    
    [cell setBadgeCount:[_delegate notificationList:self
                          activeTransactionsForUser:[_transaction_list[row] other_user]]];
}

- (void)transactionAdded:(IATransaction*)transaction
{
    if ([_transaction_list containsObject:transaction])
        return;
    
    BOOL found = NO;
    
    if (_transaction_list.count == 0)
    {
        [self.no_data_message setHidden:YES];
        [self resizeContentView];
    }
    
    // Check for exisiting transaction for this user
    for (IATransaction* existing_transaction in _transaction_list)
    {
        if ([existing_transaction.other_user isEqual:transaction.other_user])
        {
            [self.table_view beginUpdates];
            NSUInteger row = [_transaction_list indexOfObject:existing_transaction];
            [self.table_view removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:row]
                                   withAnimation:NSTableViewAnimationSlideRight];
            [_transaction_list removeObject:existing_transaction];
            [_transaction_list insertObject:transaction
                                    atIndex:0];
            [self.table_view insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:0]
                                   withAnimation:NSTableViewAnimationSlideLeft];
            [self.table_view endUpdates];
            found = YES;
            break;
        }
    }
    if (!found) // Got transaction with new user
    {
        [self.table_view beginUpdates];
        [_transaction_list insertObject:transaction
                                atIndex:0];
        [self.table_view insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:0]
                               withAnimation:NSTableViewAnimationSlideDown];
        [self.table_view endUpdates];
    }
    
    [self updateHeaderAndBackground];
    
    [self updateBadgeForRow:0];
    
    if (self.content_height_constraint.constant < _max_rows_shown * _row_height)
        [self resizeContentView];
}

- (void)transactionUpdated:(IATransaction*)transaction
{
    for (IATransaction* existing_transaction in _transaction_list)
    {
        if ([existing_transaction.transaction_id isEqualToNumber:transaction.transaction_id])
        {
            NSUInteger row = [_transaction_list indexOfObject:existing_transaction];
            [self.table_view beginUpdates];
            [self.table_view removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:row]
                                   withAnimation:NSTableViewAnimationEffectNone];
            [_transaction_list removeObjectAtIndex:row];
            [_transaction_list insertObject:transaction
                                    atIndex:row];
            [self.table_view insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:row]
                                   withAnimation:NSTableViewAnimationEffectNone];
            [self.table_view endUpdates];
            [self updateBadgeForRow:row];
            break;
        }
    }
    [self updateHeaderAndBackground];
    [self updateListOfRowsWithProgress];
}

//- User Handling ----------------------------------------------------------------------------------

- (void)userUpdated:(IAUser*)user
{
    for (IATransaction* transaction in _transaction_list)
    {
        if (transaction.other_user == user)
        {
            NSUInteger row = [_transaction_list indexOfObject:transaction];
            [self.table_view beginUpdates];
            [self.table_view reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row]
                                       columnIndexes:[NSIndexSet indexSetWithIndex:0]];
            [self.table_view endUpdates];
        }
    }
}

//- Notification List Cell View Protocol -----------------------------------------------------------

- (void)notificationListCellAcceptClicked:(IANotificationListCellView*)sender
{
    NSInteger row = [self.table_view rowForView:sender];
    if (row < 0 || row >= _transaction_list.count)
        return;
    [_delegate notificationList:self
              acceptTransaction:[_transaction_list objectAtIndex:row]];
}

- (void)notificationListCellCancelClicked:(IANotificationListCellView*)sender
{
    NSInteger row = [self.table_view rowForView:sender];
    if (row < 0 || row >= _transaction_list.count)
        return;
    [_delegate notificationList:self
              cancelTransaction:[_transaction_list objectAtIndex:row]];
}

- (void)notificationListCellRejectClicked:(IANotificationListCellView*)sender
{
    NSInteger row = [self.table_view rowForView:sender];
    if (row < 0 || row >= _transaction_list.count)
        return;
    [_delegate notificationList:self
              rejectTransaction:[_transaction_list objectAtIndex:row]];
}

- (void)notificationListCellAvatarClicked:(IANotificationListCellView*)sender
{
    NSInteger row = [self.table_view rowForView:sender];
    if (row < 0 || row >= _transaction_list.count)
        return;
    
    [self userRowGotClicked:row];
}

//- Change View Handling ---------------------------------------------------------------------------

- (void)aboutToChangeView
{
    _changing = YES;
    [self setUpdatorRunning:NO];
    for (IATransaction* transaction in _transaction_list)
    {
        if ([_delegate notificationList:self activeTransactionsForUser:transaction.other_user] == 0 &&
            [_delegate notificationList:self unreadTransactionsForUser:transaction.other_user] == 1)
        {
            [_delegate notificationList:self wantsMarkTransactionRead:transaction];
        }
    }
}

@end
