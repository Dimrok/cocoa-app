//
//  IANotificationListViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 7/31/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IANotificationListViewController.h"

#import <Gap/version.h>

#import "IAAvatarManager.h"
#import "IANotificationListCellView.h"

@interface IANotificationListViewController ()

@end

//- Notification List Row View ---------------------------------------------------------------------

@interface IANotificationListRowView : NSTableRowView
@end

@implementation IANotificationListRowView
{
@private
    NSTrackingArea* _tracking_area;
}

- (void)dealloc
{
    _tracking_area = nil;
}

- (void)ensureTrackingArea
{
    NSDictionary* dict = @{@"row": self};
    _tracking_area = [[NSTrackingArea alloc] initWithRect:NSZeroRect
                                                  options:(NSTrackingInVisibleRect |
                                                           NSTrackingActiveAlways |
                                                           NSTrackingMouseEnteredAndExited)
                                                    owner:[(NSTableView*)self.superview delegate]
                                                 userInfo:dict];
}

- (void)updateTrackingAreas
{
    [super updateTrackingAreas];
    [self ensureTrackingArea];
    if (![[self trackingAreas] containsObject:_tracking_area])
    {
        [self addTrackingArea:_tracking_area];
    }
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    [self setNeedsDisplay:YES];
}

- (BOOL)isFlipped
{
    return NO;
}

- (void)drawRect:(NSRect)dirtyRect
{
    if (self.selected)
    {
        // Grey background
        NSRect white_bg_frame = NSMakeRect(self.bounds.origin.x,
                                           self.bounds.origin.y + 2.0,
                                           self.bounds.size.width,
                                           self.bounds.size.height - 2.0);
        NSBezierPath* white_bg = [NSBezierPath bezierPathWithRect:white_bg_frame];
        [IA_GREY_COLOUR(255.0) set];
        [white_bg fill];
    }
    else
    {
        // Grey background
        NSRect grey_bg_frame = NSMakeRect(self.bounds.origin.x,
                                          self.bounds.origin.y + 2.0,
                                          self.bounds.size.width,
                                          self.bounds.size.height - 2.0);
        NSBezierPath* grey_bg = [NSBezierPath bezierPathWithRect:grey_bg_frame];
        [IA_GREY_COLOUR(246.0) set];
        [grey_bg fill];
    }
    
    // White line
    NSRect white_line_frame = NSMakeRect(self.bounds.origin.x,
                                         1.0,
                                         self.bounds.size.width,
                                         1.0);
    NSBezierPath* white_line = [NSBezierPath bezierPathWithRect:white_line_frame];
    [IA_GREY_COLOUR(255.0) set];
    [white_line fill];
    
    // Grey line
    NSRect grey_line_frame = NSMakeRect(self.bounds.origin.x,
                                        0.0,
                                        self.bounds.size.width,
                                        1.0);
    NSBezierPath* grey_line = [NSBezierPath bezierPathWithRect:grey_line_frame];
    [IA_GREY_COLOUR(220.0) set];
    [grey_line fill];
}

@end;

@implementation IANotificationListViewController
{
@private
    id<IANotificationListViewProtocol> _delegate;
    
    CGFloat _row_height;
    NSInteger _max_rows_shown;
    NSArray* _transaction_list;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithDelegate:(id<IANotificationListViewProtocol>)delegate
{
    if (self = [super initWithNibName:self.className bundle:nil])
    {
        _delegate = delegate;
        _row_height = 72.0;
        _max_rows_shown = 5;
        _transaction_list = [_delegate notificationListWantsLastTransactions:self];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(avatarCallback:)
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

- (void)awakeFromNib
{
    NSString* version_str = [NSString stringWithFormat:@"v%@",
                             [NSString stringWithUTF8String:INFINIT_VERSION]];
    _version_item.title = version_str;
}


- (void)loadView
{
    [super loadView];
    if (_transaction_list.count == 0)
    {
        [self.no_data_message setHidden:NO];
        self.content_height_constraint.constant = 50.0;
    }
    else
    {
        [self.no_data_message setHidden:YES];
        CGFloat y_diff = [self tableHeight] - self.main_view.frame.size.height;
        [self.content_height_constraint.animator setConstant:(y_diff +
                                                       self.content_height_constraint.constant)];
        _transaction_list = nil; // XXX work around for crash on calling layout
        [self.view layoutSubtreeIfNeeded];
        [self transactionsUpdated];
    }
}

//- Avatar Callback --------------------------------------------------------------------------------

- (void)avatarCallback:(NSNotification*)notification
{
    IAUser* user = [notification.userInfo objectForKey:@"user"];
    for (IATransaction* transaction in _transaction_list)
    {
        if ((transaction.from_me && [transaction.recipient isEqual:user]) ||
            (!transaction.from_me && [transaction.sender isEqual:user]))
        {
            [self.table_view reloadDataForRowIndexes:
                    [NSIndexSet indexSetWithIndex:[_transaction_list indexOfObject:transaction]]
                                    columnIndexes:[NSIndexSet indexSetWithIndex:0]];
        }
    }
}

//- Table Functions --------------------------------------------------------------------------------

- (void)transactionsUpdated
{
     _transaction_list = [_delegate notificationListWantsLastTransactions:self];
    [self updateTable];
}

- (void)updateTable
{
    CGFloat y_diff = [self tableHeight] - self.main_view.frame.size.height;
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
     {
         context.duration = 0.25;
         [self.content_height_constraint.animator
                    setConstant:(self.content_height_constraint.constant + y_diff)];
         [self.view layoutSubtreeIfNeeded];
     }
                        completionHandler:^
     {
     }];
    [self.table_view reloadData];
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
    return YES;
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
    if (transaction.transaction_id == 0)
        return nil;
    IANotificationListCellView* cell = [tableView makeViewWithIdentifier:@"notification_cell"
                                                                   owner:self];
    IAUser* user;
    if (transaction.from_me)
        user = transaction.recipient;
    else
        user = transaction.sender;
    [cell setupCellWithTransaction:transaction
            andRunningTransactions:[_delegate notificationList:self
                                     activeTransactionsForUser:user]];
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

//- User Interaction With Table --------------------------------------------------------------------

- (IBAction)tableViewAction:(NSTableView*)sender
{
    NSInteger row = [self.table_view clickedRow];
    if (row < 0 || row > _transaction_list.count - 1)
        return;
    
    IATransaction* transaction = [_transaction_list objectAtIndex:row];
    IAUser* user;
    
    if (transaction.from_me)
        user = transaction.recipient;
    else
        user = transaction.sender;
    
    [_delegate notificationList:self gotClickOnUser:user];
}

//- Mouse Hovering ---------------------------------------------------------------------------------

- (void)mouseEntered:(NSEvent*)theEvent
{
    NSDictionary* dict = theEvent.userData;
    if (![[dict objectForKey:@"row"] isKindOfClass:[IANotificationListRowView class]])
        return;
    IANotificationListRowView* row = [dict objectForKey:@"row"];
    [self.table_view selectRowIndexes:[NSIndexSet indexSetWithIndex:[self.table_view rowForView:row]]
                 byExtendingSelection:NO];
    if ([self.table_view rowForView:row] == 0)
        self.header_image.image = [IAFunctions imageNamed:@"bg-header-top-white"];
    else
        self.header_image.image = [IAFunctions imageNamed:@"bg-header-top-gray"];
}

- (void)mouseExited:(NSEvent*)theEvent
{
    [self.table_view deselectAll:self];
    self.header_image.image = [IAFunctions imageNamed:@"bg-header-top-gray"];
}

- (void)mouseMoved:(NSEvent*)theEvent
{
}

- (void)cursorUpdate:(NSEvent*)event
{
}

//- Button Handling --------------------------------------------------------------------------------

- (IBAction)settingsButtonClicked:(NSButton*)sender
{
    NSPoint point = NSMakePoint(sender.frame.origin.x + sender.frame.size.width,
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
    [_delegate notificationListGotTransferClick:self];
}

//- Menu Handling ----------------------------------------------------------------------------------

- (IBAction)quitClicked:(NSMenuItem*)sender
{
    [_delegate notificationListWantsQuit:self];
}

//- Transaction Handling ---------------------------------------------------------------------------

@end
