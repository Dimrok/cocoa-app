//
//  IANotificationListViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 7/31/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IANotificationListViewController.h"

#import <QuartzCore/QuartzCore.h>

#import <version.hh>

#import "INPopoverController.h"

#import "IAAvatarManager.h"
#import "InfinitMetricsManager.h"
#import "InfinitNotificationListConnectionCellView.h"
#import "InfinitTooltipViewController.h"

#define IA_FEEDBACK_LINK "http://feedback.infinit.io"
#define IA_PROFILE_LINK "https://infinit.io/account"

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("OSX.NotificationListViewController");

@interface IANotificationListViewController ()
@end

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
  gap_UserStatus _connection_status;
  InfinitTooltipViewController* _tooltip;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithDelegate:(id<IANotificationListViewProtocol>)delegate
   andConnectionStatus:(gap_UserStatus)connection_status
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
                                           selector:@selector(scrollBoundsChanged)
                                               name:NSViewBoundsDidChangeNotification
                                             object:nil];
    _connection_status = connection_status;
    _changing = NO;
  }
  return self;
}

- (void)dealloc
{
  [NSNotificationCenter.defaultCenter removeObserver:self];
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (BOOL)closeOnFocusLost
{
  return YES;
}

- (void)awakeFromNib
{
  // WORKAROUND: Stop 15" Macbook Pro always rendering scroll bars
  // http://www.cocoabuilder.com/archive/cocoa/317591-can-hide-scrollbar-on-nstableview.html
  [self.table_view.enclosingScrollView setScrollerStyle:NSScrollerStyleOverlay];
  [self.table_view.enclosingScrollView.verticalScroller setControlSize:NSSmallControlSize];
  if (_connection_status != gap_user_status_online)
  {
    self.header_image.image = [IAFunctions imageNamed:@"bg-header-top-problem"];
    self.table_view.backgroundColor = IA_RGB_COLOUR(253.0, 255.0, 236.0);
  }
  else if (_transaction_list.count > 0)
  {
    IAUser* top_user = [_transaction_list[0] other_user];
    if (_connection_status != gap_user_status_online ||
        [_delegate notificationList:self unreadTransactionsForUser:top_user] > 0 ||
        [_delegate notificationList:self activeTransactionsForUser:top_user] > 0)
    {
      self.header_image.image = [IAFunctions imageNamed:@"bg-header-top-white"];
      self.table_view.backgroundColor = IA_GREY_COLOUR(255.0);
    }
  }
  else
  {
    self.header_image.image = [IAFunctions imageNamed:@"bg-header-top-gray"];
    self.table_view.backgroundColor = IA_GREY_COLOUR(248.0);
  }
}

- (void)loadView
{
  ELLE_TRACE("%s: loadview", self.description.UTF8String);
  [super loadView];
  
  NSString* version_str = [NSString stringWithFormat:@"v%@",
                           [NSString stringWithUTF8String:INFINIT_VERSION]];
  _version_item.title = version_str;
  
  if ([_delegate notificationListWantsAutoStartStatus:self])
    _auto_start_toggle.state = NSOnState;
  else
    _auto_start_toggle.state = NSOffState;
  
  if (_transaction_list.count == 0 && _connection_status == gap_user_status_online)
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
    if (_transaction_list.count > 0)
      [self updateListOfRowsWithProgress];
  }
  [self.table_view.enclosingScrollView.contentView setPostsBoundsChangedNotifications:YES];
  if ([_delegate onboardingState:self] == INFINIT_ONBOARDING_RECEIVE_CLICKED_ICON ||
      [_delegate onboardingState:self] == INFINIT_ONBOARDING_RECEIVE_IN_CONVERSATION_VIEW)
  {
    [self performSelector:@selector(delayedStartReceiveOnboarding) withObject:nil afterDelay:1.0];
  }
  else if ([_delegate onboardingState:self] == INFINIT_ONBOARDING_SEND_NO_FILES_NO_DESTINATION)
  {
    [self performSelector:@selector(delayedStartSendOnboarding) withObject:nil afterDelay:1.0];
  }
  else if ([_delegate onboardingState:self] == INFINIT_ONBOARDING_SEND_FILE_SENDING ||
           [_delegate onboardingState:self] == INFINIT_ONBOARDING_SEND_FILE_SENT)
  {
    [self performSelector:@selector(delayedFileSentOnboarding) withObject:nil afterDelay:1.0];
  }
}

- (void)delayedStartReceiveOnboarding
{
  if (_tooltip == nil)
    _tooltip = [[InfinitTooltipViewController alloc] init];
  InfinitNotificationListRowView* row_view = [self.table_view rowViewAtRow:0 makeIfNecessary:NO];
  NSString* message = NSLocalizedString(@"Click on the contact to accept the file", nil);
  [_tooltip showPopoverForView:row_view
            withArrowDirection:INPopoverArrowDirectionLeft
                   withMessage:message];
}

- (void)delayedStartSendOnboarding
{
  if (_tooltip == nil)
    _tooltip = [[InfinitTooltipViewController alloc] init];
  NSString* message = NSLocalizedString(@"Click on the icon to send a file", nil);
  [_tooltip showPopoverForView:self.transfer_button
            withArrowDirection:INPopoverArrowDirectionLeft
                   withMessage:message];
}

- (void)delayedFileSentOnboarding
{
  if (_tooltip == nil)
    _tooltip = [[InfinitTooltipViewController alloc] init];
  InfinitNotificationListRowView* row_view = [self.table_view rowViewAtRow:0 makeIfNecessary:NO];
  NSString* message = NSLocalizedString(@"Click on the contact to see your history", nil);
  [_tooltip showPopoverForView:row_view
            withArrowDirection:INPopoverArrowDirectionLeft
                   withMessage:message];
}

//- Avatar Callback --------------------------------------------------------------------------------

- (void)avatarCallback:(NSNotification*)notification
{
  IAUser* user = [notification.userInfo objectForKey:@"user"];
  for (IATransaction* transaction in _transaction_list)
  {
    if ([transaction.other_user isEqual:user])
    {
      NSImage* image = [notification.userInfo objectForKey:@"avatar"];
      IANotificationListCellView* cell =
      [self.table_view viewAtColumn:0
                                row:[_transaction_list indexOfObject:transaction]
                    makeIfNecessary:NO];
      if (image == nil || cell == nil)
        return;
      [cell loadAvatarImage:image];
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
  if (_connection_status != gap_user_status_online)
    total_height += _row_height;
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
  if (_connection_status == gap_user_status_online)
    return _transaction_list.count;
  else
    return (_transaction_list.count + 1);
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
  if (_connection_status != gap_user_status_online && row == 0)
  {
    InfinitNotificationListConnectionCellView* cell =
    [tableView makeViewWithIdentifier:@"connection_notification_cell" owner:self];
    [cell setMessageStr:NSLocalizedString(@"Have you tried turning it off and on again?",
                                          @"have you tried turning it off and on again")];
    [cell setUpCell];
    return cell;
  }
  
  // If we don't have a connection, we add a row to show this
  NSUInteger table_row = row;
  if (_connection_status != gap_user_status_online)
    table_row -= 1;
  
  IATransaction* transaction = _transaction_list[table_row];
  if (transaction.transaction_id.unsignedIntValue == 0)
    return nil;
  IANotificationListCellView* cell = [tableView makeViewWithIdentifier:@"user_notification_cell"
                                                                 owner:self];
  // WORKAROUND: Ensure that the cell is not reused as otherwise the round progress is drawn on
  // multiple views.
  cell.identifier = nil;
  
  IAUser* user = transaction.other_user;
  
  NSUInteger unread_notifications = [_delegate notificationList:self unreadTransactionsForUser:user];
  NSUInteger active_transfers = [_delegate notificationList:self activeTransactionsForUser:user];
  
  [cell setupCellWithTransaction:transaction
         withRunningTransactions:active_transfers
          andUnreadNotifications:unread_notifications
                     andProgress:[_delegate notificationList:self transactionsProgressForUser:user]
                     andDelegate:self];
  InfinitNotificationListRowView* row_view = [self.table_view rowViewAtRow:row makeIfNecessary:NO];
  if (unread_notifications > 0 || active_transfers > 0)
    row_view.unread = YES;
  else
    row_view.unread = NO;
  
  return cell;
}

- (NSTableRowView*)tableView:(NSTableView*)tableView
               rowViewForRow:(NSInteger)row
{
  InfinitNotificationListRowView* row_view = [tableView rowViewAtRow:row makeIfNecessary:YES];
  if (row_view == nil)
  {
    row_view = [[InfinitNotificationListRowView alloc] initWithFrame:NSZeroRect
                                                        withDelegate:self
                                                        andClickable:YES];
  }
  if (_connection_status != gap_user_status_online && row == 0)
  {
    row_view.unread = YES;
    row_view.clickable = NO;
    row_view.error = YES;
  }
  return row_view;
}

- (void)updateHeaderAndBackground
{
  if (self.table_view.numberOfRows == 0)
    return;
  
  NSRange visible_rows = [self.table_view rowsInRect:self.table_view.visibleRect];
  InfinitNotificationListRowView* row_view = [self.table_view rowViewAtRow:visible_rows.location
                                                           makeIfNecessary:NO];
  if (row_view.error)
  {
    self.header_image.image = [IAFunctions imageNamed:@"bg-header-top-problem"];
    self.table_view.backgroundColor = IA_RGB_COLOUR(253.0, 255.0, 236.0);
  }
  else if (row_view.hovered && !_changing)
  {
    self.header_image.image = [IAFunctions imageNamed:@"bg-header-top-hover"];
    self.table_view.backgroundColor = IA_RGB_COLOUR(236.0, 253.0, 255.0);
  }
  else if (row_view.unread || _changing)
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
  
  if (_connection_status != gap_user_status_online && row == 0)
    return;
  
  if ([_delegate onboardingState:self] == INFINIT_ONBOARDING_RECEIVE_CLICKED_ICON)
  {
    [_delegate setOnboardingState:INFINIT_ONBOARDING_RECEIVE_IN_CONVERSATION_VIEW];
  }
  else if ([_delegate onboardingState:self] == INFINIT_ONBOARDING_SEND_FILE_SENT)
  {
    
  }
  
  [self setUpdatorRunning:NO];
  
  _changing = YES;
  
  [[self.table_view rowViewAtRow:row makeIfNecessary:NO] setClicked:YES];
  self.header_image.image = [IAFunctions imageNamed:@"bg-header-top-white"];
  
  NSUInteger transaction_num = row;
  if (_connection_status != gap_user_status_online)
    transaction_num -= 1;
  
  IATransaction* transaction = _transaction_list[transaction_num];
  IAUser* user = transaction.other_user;
  
  if (_transaction_list.count == 1)
  {
    [_delegate notificationList:self gotClickOnUser:user];
  }
  else
  {
    
    NSRange visible_rows = [self.table_view rowsInRect:self.table_view.visibleRect];
    
    NSMutableIndexSet* invisible_users = [NSMutableIndexSet indexSetWithIndexesInRange:
                                          NSMakeRange(0, self.table_view.numberOfRows)];
    NSMutableIndexSet* visible_users = [NSMutableIndexSet indexSetWithIndexesInRange:visible_rows];
    [invisible_users removeIndexes:visible_users];
    
    [self.table_view beginUpdates];
    [_transaction_list removeObjectsAtIndexes:invisible_users];
    [self.table_view removeRowsAtIndexes:invisible_users
                           withAnimation:NSTableViewAnimationEffectNone];
    [self.table_view endUpdates];
    
    NSInteger new_row = [_transaction_list indexOfObject:transaction];
    if (_connection_status != gap_user_status_online)
      new_row += 1;
    NSMutableIndexSet* other_users = [NSMutableIndexSet indexSetWithIndexesInRange:
                                      NSMakeRange(0, self.table_view.numberOfRows)];
    [other_users removeIndex:new_row];
    
    self.table_view.backgroundColor = IA_GREY_COLOUR(255.0);
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
     {
       context.duration = 0.15;
       [self.content_height_constraint.animator setConstant:44.0];
       [self.table_view beginUpdates];
       [self.table_view moveRowAtIndex:new_row toIndex:0];
       [self.table_view endUpdates];
       [self.content_height_constraint.animator setConstant:_row_height];
     }
                        completionHandler:^
     {
       [_delegate notificationList:self gotClickOnUser:user];
     }];
  }
}

//- User Interaction With Table --------------------------------------------------------------------

- (IBAction)tableViewAction:(NSTableView*)sender
{
  NSInteger row = [self.table_view clickedRow];
  if (_connection_status != gap_user_status_online)
  {
    if (row < 1 || row > _transaction_list.count)
      return;
  }
  else
  {
    if (row < 0 || row > _transaction_list.count - 1)
      return;
  }
  [self userRowGotClicked:row];
}

- (void)scrollBoundsChanged
{
  if (_changing)
    return;
  [self updateHeaderAndBackground];
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
  if ([_delegate onboardingState:self] == INFINIT_ONBOARDING_RECEIVE_DONE)
  {
    [_delegate setOnboardingState:INFINIT_ONBOARDING_SEND_NO_FILES_NO_DESTINATION];
  }
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
   {
     context.duration = 0.15;
     if (self.content_height_constraint.constant > 72.0)
       [self.content_height_constraint.animator setConstant:72.0];
   }
                      completionHandler:^
   {
     [_delegate notificationListGotTransferClick:self];
     [InfinitMetricsManager sendMetric:INFINIT_METRIC_MAIN_SEND];
   }];
}

//- Menu Handling ----------------------------------------------------------------------------------

- (IBAction)onLogoutClicked:(NSMenuItem*)sender
{
  [_delegate notificationListWantsLogout:self];
}

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

- (IBAction)onToggleAutoStartClick:(NSMenuItem*)sender
{
  if (sender.state == NSOffState)
  {
    sender.state = NSOnState;
    [_delegate notificationList:self setAutoStart:YES];
  }
  else
  {
    sender.state = NSOffState;
    [_delegate notificationList:self setAutoStart:NO];
  }
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
  if (_connection_status != gap_user_status_online)
  {
    if (row < 1 || row > _transaction_list.count)
      return;
  }
  else
  {
    if (row < 0 || row > _transaction_list.count - 1)
      return;
  }
  
  [self userRowGotClicked:row];
}

//- Change View Handling ---------------------------------------------------------------------------

- (void)aboutToChangeView
{
  _changing = YES;
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  [_tooltip close];
  [self setUpdatorRunning:NO];
  for (IATransaction* transaction in _transaction_list)
  {
    NSUInteger active = [_delegate notificationList:self activeTransactionsForUser:transaction.other_user];
    NSUInteger unread = [_delegate notificationList:self unreadTransactionsForUser:transaction.other_user];
    if ((active == 0 && unread == 1) || (active == 1 && unread == 0))
    {
      [_delegate notificationList:self wantsMarkTransactionRead:transaction];
    }
  }
}

//- Connection Handling ----------------------------------------------------------------------------

- (void)setConnected:(gap_UserStatus)connection_status
{
  if (_connection_status == connection_status)
    return;
  
  _connection_status = connection_status;
  if (_connection_status != gap_user_status_online)
  {
    [self.table_view insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:0]
                           withAnimation:NSTableViewAnimationSlideDown];
  }
  else
  {
    [self.table_view removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:0]
                           withAnimation:NSTableViewAnimationSlideUp];
  }
  [self resizeContentView];
  [self updateHeaderAndBackground];
}

//- Notification Row Protocol ----------------------------------------------------------------------

- (void)notificationRowHoverChanged:(InfinitNotificationListRowView*)sender
{
  [self updateHeaderAndBackground];
}

@end
