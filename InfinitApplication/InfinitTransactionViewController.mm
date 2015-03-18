//
//  InfinitTransactionViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 12/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitTransactionViewController.h"

#import "InfinitOnboardingController.h"
#import "InfinitTooltipViewController.h"

#import <Gap/InfinitPeerTransactionManager.h>
#import <Gap/InfinitUserManager.h>

@interface InfinitTransactionViewController ()
@end

@implementation InfinitTransactionViewController
{
@private
  // WORKAROUND: 10.7 doesn't allow weak references to certain classes (like NSViewController)
  __unsafe_unretained id<InfinitTransactionViewProtocol> _delegate;
  NSMutableArray* _list;

  NSUInteger _max_rows;
  CGFloat _row_height;

  // Progress handling.
  NSTimer* _progress_timer;
  NSMutableArray* _rows_with_progress;

  InfinitTooltipViewController* _tooltip;
}

//- Init -------------------------------------------------------------------------------------------

- (id)initWithDelegate:(id<InfinitTransactionViewProtocol>)delegate
{
  if (self = [super initWithNibName:self.className bundle:nil])
  {
    _delegate = delegate;
    [self updateModel];
    _max_rows = 4;
    _row_height = 72.0;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(avatarCallback:)
                                                 name:INFINIT_USER_AVATAR_NOTIFICATION
                                               object:nil];
  }
  return self;
}

- (void)dealloc
{
  self.table_view.delegate = nil;
  self.table_view.dataSource = nil;
  _delegate = nil;
  [NSNotificationCenter.defaultCenter removeObserver:self];
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  if (_progress_timer != nil)
  {
    [_progress_timer invalidate];
    _progress_timer = nil;
  }
}

- (void)awakeFromNib
{
  // WORKAROUND: Stop 15" Macbook Pro always rendering scroll bars
  // http://www.cocoabuilder.com/archive/cocoa/317591-can-hide-scrollbar-on-nstableview.html
  [self.table_view.enclosingScrollView setScrollerStyle:NSScrollerStyleOverlay];
  [self.table_view.enclosingScrollView.verticalScroller setControlSize:NSSmallControlSize];
}

- (void)loadView
{
  [super loadView];
  [self.table_view reloadData];
  [self resizeView];
  [self updateListOfRowsWithProgress];
}

- (void)updateModel
{
  NSArray* transactions =
    [[InfinitPeerTransactionManager sharedInstance] latestTransactionPerSwagger];
  NSMutableOrderedSet* set = [NSMutableOrderedSet orderedSet];
  for (InfinitPeerTransaction* transaction in transactions)
  {
    if (!transaction.done)
      [set addObject:transaction];
  }
  [set addObjectsFromArray:transactions];
  _list = [[set array] mutableCopy];
  [self.table_view reloadData];
  [self updateListOfRowsWithProgress];
}

//- Onboarding -------------------------------------------------------------------------------------

- (void)delayedStartReceiveOnboarding
{
  NSInteger row = ([_list indexOfObject:[_delegate receiveOnboardingTransaction:self]]);
  if (row == NSNotFound)
    return;

  if (_tooltip == nil)
    _tooltip = [[InfinitTooltipViewController alloc] init];
  NSTableRowView* row_view = [self.table_view rowViewAtRow:row makeIfNecessary:NO];
  NSString* message = NSLocalizedString(@"Click here to accept the file", nil);
  [_tooltip showPopoverForView:row_view
            withArrowDirection:INPopoverArrowDirectionLeft
                   withMessage:message
              withPopAnimation:YES
                       forTime:5.0];
}

- (void)delayedFileSentOnboarding
{
  NSInteger row = ([_list indexOfObject:[_delegate sendOnboardingTransaction:self]]);
  if (row == NSNotFound)
    return;
  if (_tooltip == nil)
    _tooltip = [[InfinitTooltipViewController alloc] init];
  NSTableRowView* row_view = [self.table_view rowViewAtRow:row makeIfNecessary:NO];
  NSString* message = NSLocalizedString(@"Click here to see your history with this person", nil);
  [_tooltip showPopoverForView:row_view
            withArrowDirection:INPopoverArrowDirectionLeft
                   withMessage:message
              withPopAnimation:YES
                       forTime:5.0];
}

//- Progress Handling ------------------------------------------------------------------------------

- (void)setUpdatorRunning:(BOOL)is_running
{
	if (is_running && _progress_timer == nil)
  {
		_progress_timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                       target:self
                                                     selector:@selector(updateProgress)
                                                     userInfo:nil
                                                      repeats:YES];
  }
	else if (!is_running && _progress_timer != nil)
	{
		[_progress_timer invalidate];
		_progress_timer = nil;
	}
}

- (void)updateListOfRowsWithProgress
{
  if (_list.count == 0)
    return;

  if (_rows_with_progress == nil)
    _rows_with_progress = [NSMutableArray array];
  else
    [_rows_with_progress removeAllObjects];

  NSUInteger row = 0;
  InfinitPeerTransactionManager* manager = [InfinitPeerTransactionManager sharedInstance];

  for (InfinitPeerTransaction* transaction in _list)
  {
    NSUInteger running = [manager transferringTransactionsWithUser:transaction.other_user];
    if (running > 0)
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
  for (NSNumber* num in _rows_with_progress)
  {
    NSInteger row = num.unsignedIntegerValue;
    if (row < _list.count)
    {
      InfinitTransactionCellView* cell = [self.table_view viewAtColumn:0
                                                                   row:row
                                                       makeIfNecessary:NO];
      InfinitPeerTransaction* transaction = _list[row];
      cell.progress =
        [[InfinitPeerTransactionManager sharedInstance] progressWithUser:transaction.other_user];
    }
  }
}

//- Table Handling ---------------------------------------------------------------------------------

- (NSUInteger)unreadRows
{
  NSUInteger res = 0;
  InfinitPeerTransactionManager* manager = [InfinitPeerTransactionManager sharedInstance];
  for (InfinitPeerTransaction* transaction in _list)
  {
    NSUInteger unread = [manager unreadTransactionsWithUser:transaction.other_user];
    if (unread > 0)
      res++;
  }
  return res;
}

- (BOOL)tableView:(NSTableView*)tableView
  shouldSelectRow:(NSInteger)row
{
  return NO;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView*)tableView
{
  if (_list.count > 0)
    return _list.count;
  else
    return 1;
}

- (NSView*)tableView:(NSTableView*)tableView
  viewForTableColumn:(NSTableColumn*)tableColumn
                 row:(NSInteger)row
{
  if (_list.count == 0)
    return [self.table_view makeViewWithIdentifier:@"no_transaction_cell" owner:self];

  InfinitTransactionCellView* cell = [self.table_view makeViewWithIdentifier:@"transaction_cell"
                                                                       owner:self];
  InfinitPeerTransaction* transaction = _list[row];
  InfinitUser* user = transaction.other_user;
  InfinitPeerTransactionManager* manager = [InfinitPeerTransactionManager sharedInstance];
  [cell setupCellWithTransaction:transaction
         withRunningTransactions:[manager transferringTransactionsWithUser:user]
          andNotDoneTransactions:[manager incompleteTransactionsWithUser:user]
           andUnreadTransactions:[manager unreadTransactionsWithUser:user]
                     andProgress:[manager progressWithUser:user]];
  if ([IAFunctions osxVersion] < INFINIT_OS_X_VERSION_10_9)
  {
    cell.identifier = nil;
  }
  return cell;
}

- (IBAction)tableViewAction:(NSTableView*)sender
{
  _changing = YES;
  if (_list.count == 0)
    return;

  [_progress_timer invalidate];
  NSInteger row = self.table_view.clickedRow;

  InfinitPeerTransaction* transaction = _list[row];
  NSMutableIndexSet* other_rows =
    [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, _list.count)];
  [other_rows removeIndex:row];

  [self.table_view beginUpdates];
  [_list removeObjectsAtIndexes:other_rows];
  [self.table_view removeRowsAtIndexes:other_rows withAnimation:NSTableViewAnimationSlideRight];
  [self.table_view endUpdates];
  [_delegate userGotClicked:transaction.other_user];
}

//- Transaction Added/Updated ----------------------------------------------------------------------

- (void)transactionAdded:(InfinitPeerTransaction*)transaction
{
  if (_changing)
    return;

  if ([_list containsObject:transaction])
    return;

  BOOL found = NO;

  // Check for exisiting transaction for this user
  for (InfinitPeerTransaction* existing_transaction in _list)
  {
    if ([existing_transaction.other_user isEqual:transaction.other_user])
    {
      [self.table_view beginUpdates];
      NSUInteger row = [_list indexOfObject:existing_transaction];
      [self.table_view removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:row]
                             withAnimation:NSTableViewAnimationSlideRight];
      [_list removeObject:existing_transaction];
      [_list insertObject:transaction atIndex:0];
      [self.table_view insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:0]
                             withAnimation:NSTableViewAnimationSlideLeft];
      [self.table_view endUpdates];
      found = YES;
      break;
    }
  }
  if (!found) // Got transaction with new user
  {
    [_list insertObject:transaction atIndex:0];
    [self.table_view beginUpdates];
    if (_list.count == 1) // First transaction.
    {
      [self.table_view removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:0]
                             withAnimation:NSTableViewAnimationSlideRight];
      [self.table_view insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:0]
                             withAnimation:NSTableViewAnimationSlideRight];
    }
    else
    {
      [self.table_view insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:0]
                             withAnimation:NSTableViewAnimationSlideDown];
    }
    [self.table_view endUpdates];
  }

  InfinitTransactionCellView* cell = [self.table_view viewAtColumn:0 row:0 makeIfNecessary:NO];
  InfinitPeerTransactionManager* manager = [InfinitPeerTransactionManager sharedInstance];
  [cell setBadgeCount:[manager incompleteTransactionsWithUser:transaction.other_user]];

  [self resizeView];
}

- (void)transactionUpdated:(InfinitPeerTransaction*)transaction
{
  if (_changing)
    return;

  for (InfinitPeerTransaction* existing_transaction in _list)
  {
    if (existing_transaction.other_user == transaction.other_user)
    {
      NSUInteger row = [_list indexOfObject:existing_transaction];
      [self.table_view beginUpdates];
      [self.table_view removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:row]
                             withAnimation:NSTableViewAnimationEffectNone];
      [_list removeObjectAtIndex:row];
      [_list insertObject:transaction atIndex:row];
      [self.table_view insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:row]
                             withAnimation:NSTableViewAnimationEffectNone];
      [self.table_view endUpdates];
      InfinitTransactionCellView* cell = [self.table_view viewAtColumn:0 row:row makeIfNecessary:NO];
      InfinitPeerTransactionManager* manager = [InfinitPeerTransactionManager sharedInstance];
      [cell setBadgeCount:[manager incompleteTransactionsWithUser:transaction.other_user]];
      break;
    }
  }
  [self updateListOfRowsWithProgress];
}

//- User Status Changed ----------------------------------------------------------------------------

- (void)userUpdated:(InfinitUser*)user
{
  for (InfinitPeerTransaction* transaction in _list)
  {
    if ([transaction.other_user isEqual:user])
    {
      NSUInteger row = [_list indexOfObject:transaction];
      [self.table_view beginUpdates];
      [self.table_view reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row]
                                 columnIndexes:[NSIndexSet indexSetWithIndex:0]];
      [self.table_view endUpdates];
    }
  }
}

//- Avatar Callback --------------------------------------------------------------------------------

- (void)avatarCallback:(NSNotification*)notification
{
  if (_changing)
    return;

  NSNumber* id_ = notification.userInfo[kInfinitUserId];
  InfinitUser* user = [[InfinitUserManager sharedInstance] userWithId:id_];
  for (InfinitPeerTransaction* transaction in _list)
  {
    if ([transaction.other_user isEqual:user])
    {
      InfinitTransactionCellView* cell =
        [self.table_view viewAtColumn:0 row:[_list indexOfObject:transaction] makeIfNecessary:NO];
      if (user.avatar == nil || cell == nil)
        return;
      [cell loadAvatarImage:user.avatar];
    }
  }
}

//- View Handling ----------------------------------------------------------------------------------

- (CGFloat)height
{
  if (_list.count == 0)
    return _row_height;
  CGFloat height = self.table_view.numberOfRows * _row_height;

  if (height > _max_rows * _row_height)
    return (_max_rows * _row_height);
  else
    return height;
}

- (void)setChanging:(BOOL)changing
{
  _changing = changing;
  if (changing)
  {
    [_progress_timer invalidate];
    _progress_timer = nil;
  }
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)resizeView
{
  [_delegate transactionsViewResizeToHeight:self.height];
}

- (void)markTransactionsRead
{
  InfinitPeerTransactionManager* manager = [InfinitPeerTransactionManager sharedInstance];
  for (InfinitPeerTransaction* transaction in _list)
  {
    NSUInteger active = [manager transferringTransactionsWithUser:transaction.other_user];
    NSUInteger unread = [manager unreadTransactionsWithUser:transaction.other_user];;
    if ((active == 0 && unread == 1) || (active == 1 && unread == 0))
      [manager markTransactionRead:transaction];
  }
}

- (void)closeToolTips
{
  [_tooltip close];
}

@end
