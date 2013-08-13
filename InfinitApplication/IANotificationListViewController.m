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

- (BOOL)isFlipped
{
    return NO;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Grey background
    NSRect grey_bg_frame = NSMakeRect(self.bounds.origin.x,
                                      self.bounds.origin.y + 2.0,
                                      self.bounds.size.width,
                                      self.bounds.size.height - 2.0);
    NSBezierPath* grey_bg = [NSBezierPath bezierPathWithRect:grey_bg_frame];
    [TH_RGBCOLOR(246.0, 246.0, 246.0) set];
    [grey_bg fill];
    
    // White line
    NSRect white_line_frame = NSMakeRect(self.bounds.origin.x,
                                         1.0,
                                         self.bounds.size.width,
                                         1.0);
    NSBezierPath* white_line = [NSBezierPath bezierPathWithRect:white_line_frame];
    [TH_RGBCOLOR(255.0, 255.0, 255.0) set];
    [white_line fill];
    
    // Grey line
    NSRect grey_line_frame = NSMakeRect(self.bounds.origin.x,
                                        0.0,
                                        self.bounds.size.width,
                                        1.0);
    NSBezierPath* grey_line = [NSBezierPath bezierPathWithRect:grey_line_frame];
    [TH_RGBCOLOR(220.0, 220.0, 220.0) set];
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
        _max_rows_shown = 4;
        _transaction_list = [_delegate notificationListWantsTransactions:self];
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

- (NSString*)description
{
    return @"[NotificationListViewController]";
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
        self.main_view_height_constraint.constant = 50.0;
    }
    else
    {
        [self.no_data_message setHidden:YES];
        CGFloat y_diff = [self tableHeight] - self.main_view.frame.size.height;
        self.main_view_height_constraint.constant += y_diff;
    }
    _transaction_list = nil; // XXX work around for crash on calling layout
    [self.view layoutSubtreeIfNeeded];
    [self transactionsUpdated];
}

//- Avatar Callback --------------------------------------------------------------------------------

- (void)avatarCallback:(NSNotification*)notification
{
    IAUser* user = [notification.userInfo objectForKey:@"user"];
    for (IATransaction* transaction in _transaction_list)
    {
        if ((transaction.from_me && [transaction.recipient_id isEqualToString:user.user_id]) ||
            (!transaction.from_me && [transaction.sender_id isEqualToString:user.user_id]))
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
     _transaction_list = [_delegate notificationListWantsTransactions:self];
    [self updateTable];
}

- (void)updateTable
{
    CGFloat y_diff = [self tableHeight] - self.main_view.frame.size.height;
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
     {
         context.duration = 0.25;
         [self.main_view_height_constraint.animator
                    setConstant:(self.main_view_height_constraint.constant + y_diff)];
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
    if (transaction.transaction_id.length == 0)
        return nil;
    IANotificationListCellView* cell = [tableView makeViewWithIdentifier:@"notification_cell"
                                                                   owner:self];
    [cell setupCellWithTransaction:transaction];
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

@end
