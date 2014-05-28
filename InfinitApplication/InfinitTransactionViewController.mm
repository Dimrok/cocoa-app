//
//  InfinitTransactionViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 12/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitTransactionViewController.h"

#import "IAAvatarManager.h"
#import "InfinitOnboardingController.h"
#import "InfinitTooltipViewController.h"

@interface InfinitTransactionViewController ()
@end

@implementation InfinitTransactionViewController
{
@private
  id<InfinitTransactionViewProtocol> _delegate;
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
    andTransactionList:(NSArray*)transaction_list
{
  if (self = [super initWithNibName:self.className bundle:nil])
  {
    _delegate = delegate;
    _list = [NSMutableArray arrayWithArray:transaction_list];
    _max_rows = 4;
    _row_height = 72.0;

    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(avatarCallback:)
                                               name:IA_AVATAR_MANAGER_AVATAR_FETCHED
                                             object:nil];
  }
  return self;
}

- (void)dealloc
{
  _progress_timer = nil;
  [NSNotificationCenter.defaultCenter removeObserver:self];
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
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

- (void)updateModelWithList:(NSArray*)list
{
  _list = [NSMutableArray arrayWithArray:list];
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

  for (IATransaction* transaction in _list)
  {
    if ([_delegate transferringTransactionsForUser:transaction.other_user])
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
      IATransaction* transaction = _list[row];
      cell.progress = [_delegate totalProgressForUser:transaction.other_user];
    }
  }
}

//- Table Handling ---------------------------------------------------------------------------------

- (NSUInteger)unreadRows
{
  NSUInteger res = 0;
  for (IATransaction* transaction in _list)
  {
    if ([_delegate unreadTransactionsForUser:transaction.other_user] > 0)
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
  IATransaction* transaction = _list[row];
  IAUser* user = transaction.other_user;
  [cell setupCellWithTransaction:transaction
         withRunningTransactions:[_delegate runningTransactionsForUser:user]
          andNotDoneTransactions:[_delegate notDoneTransactionsForUser:user]
           andUnreadTransactions:[_delegate unreadTransactionsForUser:user]
                     andProgress:[_delegate totalProgressForUser:user]];
  return cell;
}

- (IBAction)tableViewAction:(NSTableView*)sender
{
  _changing = YES;
  if (_list.count == 0)
    return;

  [_progress_timer invalidate];
  NSInteger row = self.table_view.clickedRow;

  IATransaction* transaction = _list[row];
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

- (void)transactionAdded:(IATransaction*)transaction
{
  if (_changing)
    return;

  if ([_list containsObject:transaction])
    return;

  BOOL found = NO;

  // Check for exisiting transaction for this user
  for (IATransaction* existing_transaction in _list)
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
    [self.table_view beginUpdates];
    [_list insertObject:transaction atIndex:0];
    [self.table_view insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:0]
                           withAnimation:NSTableViewAnimationSlideDown];
    [self.table_view endUpdates];
  }

  InfinitTransactionCellView* cell = [self.table_view viewAtColumn:0 row:0 makeIfNecessary:NO];
  [cell setBadgeCount:[_delegate notDoneTransactionsForUser:transaction.other_user]];

  [self resizeView];
}

- (void)transactionUpdated:(IATransaction*)transaction
{
  if (_changing)
    return;

  for (IATransaction* existing_transaction in _list)
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
      [cell setBadgeCount:[_delegate notDoneTransactionsForUser:transaction.other_user]];
      break;
    }
  }
  [self updateListOfRowsWithProgress];
}

//- User Status Changed ----------------------------------------------------------------------------

- (void)userUpdated:(IAUser*)user
{
  for (IATransaction* transaction in _list)
  {
    if (transaction.other_user == user)
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

  IAUser* user = [notification.userInfo objectForKey:@"user"];
  for (IATransaction* transaction in _list)
  {
    if ([transaction.other_user isEqual:user])
    {
      NSImage* image = [notification.userInfo objectForKey:@"avatar"];
      InfinitTransactionCellView* cell =
        [self.table_view viewAtColumn:0
                                  row:[_list indexOfObject:transaction]
                      makeIfNecessary:NO];
      if (image == nil || cell == nil)
        return;
      [cell loadAvatarImage:image];
    }
  }
}

//- View Handling ----------------------------------------------------------------------------------

- (CGFloat)height
{
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
}

- (void)resizeView
{
  [_delegate transactionsViewResizeToHeight:self.height];
}

- (void)markTransactionsRead
{
  for (IATransaction* transaction in _list)
  {
    NSUInteger active = [_delegate runningTransactionsForUser:transaction.other_user];
    NSUInteger unread = [_delegate unreadTransactionsForUser:transaction.other_user];
    if ((active == 0 && unread == 1) || (active == 1 && unread == 0))
    {
      [_delegate markTransactionRead:transaction];
    }
  }
}

- (void)closeToolTips
{
  [_tooltip close];
}

@end
