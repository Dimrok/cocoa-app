//
//  InfinitTransactionViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 12/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitTransactionViewController.h"

#import "IAHoverButton.h"
#import "InfinitOnboardingWindowController.h"
#import "InfinitOSVersion.h"
#import "InfinitTooltipViewController.h"

#import <Gap/InfinitColor.h>
#import <Gap/InfinitPeerTransactionManager.h>
#import <Gap/InfinitUserManager.h>

@interface InfinitTransactionViewController () <InfinitOnboardingWindowProtocol,
                                                NSTableViewDelegate,
                                                NSTableViewDataSource>

@property (nonatomic, weak) IBOutlet IAHoverButton* tutorial_button;
@property (nonatomic, weak) IBOutlet NSTableView* table_view;

@property (nonatomic, unsafe_unretained) id<InfinitTransactionViewProtocol> delegate;
@property (atomic, readonly) NSMutableArray* list;
@property (nonatomic, readonly) InfinitOnboardingWindowController* onboarding_window;
@property (nonatomic, readonly) NSTimer* progress_timer;
@property (atomic, readonly) NSMutableArray* rows_with_progress;
@property (nonatomic, readonly) InfinitTooltipViewController* tooltip;

@end

static dispatch_once_t _awake_token = 0;
static NSUInteger _max_rows = 4;
static CGFloat _row_height = 72.0f;

@implementation InfinitTransactionViewController

#pragma mark - Init

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
  _awake_token = 0;
  self.table_view.delegate = nil;
  self.table_view.dataSource = nil;
  _delegate = nil;
  [NSNotificationCenter.defaultCenter removeObserver:self];
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  if (self.progress_timer != nil)
  {
    [self.progress_timer invalidate];
    _progress_timer = nil;
  }
}

- (void)awakeFromNib
{
  dispatch_once(&_awake_token, ^
  {
    // WORKAROUND: Stop 15" Macbook Pro always rendering scroll bars
    // http://www.cocoabuilder.com/archive/cocoa/317591-can-hide-scrollbar-on-nstableview.html
    [self.table_view.enclosingScrollView setScrollerStyle:NSScrollerStyleOverlay];
    [self.table_view.enclosingScrollView.verticalScroller setControlSize:NSSmallControlSize];

    NSFont* link_font = [NSFont fontWithName:@"SourceSansPro-Semibold" size:13.0f];
    NSMutableParagraphStyle* para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    para.alignment = NSCenterTextAlignment;
    NSColor* link_color = [InfinitColor colorWithRed:0 green:208 blue:206];
    NSDictionary* link_attrs = @{NSFontAttributeName: link_font,
                                 NSParagraphStyleAttributeName: para,
                                 NSForegroundColorAttributeName: link_color};
    NSColor* hover_color = [InfinitColor colorWithRed:0 green:170 blue:162];
    NSDictionary* link_hover_attrs = @{NSFontAttributeName: link_font,
                                       NSParagraphStyleAttributeName: para,
                                       NSForegroundColorAttributeName: hover_color};

    self.tutorial_button.hover_attrs = link_hover_attrs;
    self.tutorial_button.normal_attrs = link_attrs;
    [self.table_view reloadData];
    [self resizeView];
    [self updateListOfRowsWithProgress];
  });
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

- (void)scrollToTop
{
  [self.table_view scrollRowToVisible:0];
}

#pragma mark - Progress Handling

- (void)setUpdatorRunning:(BOOL)is_running
{
	if (is_running && self.progress_timer == nil)
  {
		_progress_timer = [NSTimer scheduledTimerWithTimeInterval:1.0f
                                                       target:self
                                                     selector:@selector(updateProgress)
                                                     userInfo:nil
                                                      repeats:YES];
  }
	else if (!is_running && self.progress_timer != nil)
	{
		[self.progress_timer invalidate];
		_progress_timer = nil;
	}
}

- (void)updateListOfRowsWithProgress
{
  if (self.list.count == 0)
    return;

  if (self.rows_with_progress == nil)
    _rows_with_progress = [NSMutableArray array];
  else
    [self.rows_with_progress removeAllObjects];

  InfinitPeerTransactionManager* manager = [InfinitPeerTransactionManager sharedInstance];

  [self.list enumerateObjectsUsingBlock:^(InfinitPeerTransaction* transaction,
                                          NSUInteger row,
                                          BOOL* stop)
  {
    NSUInteger running = [manager transferringTransactionsWithUser:transaction.other_user];
    if (running > 0)
    {
      [self.rows_with_progress addObject:[NSNumber numberWithUnsignedInteger:row]];
    }
  }];

  if (self.rows_with_progress.count > 0)
    [self setUpdatorRunning:YES];
  else
  {
    [self updateProgress]; // Update progress for case that transfer has finished
    [self setUpdatorRunning:NO];
  }
}

- (void)updateProgress
{
  for (NSNumber* num in self.rows_with_progress)
  {
    NSInteger row = num.unsignedIntegerValue;
    if (row < self.list.count)
    {
      InfinitTransactionCellView* cell =
        [self.table_view viewAtColumn:0 row:row makeIfNecessary:NO];
      InfinitPeerTransaction* transaction = self.list[row];
      cell.progress =
        [[InfinitPeerTransactionManager sharedInstance] progressWithUser:transaction.other_user];
    }
  }
}

#pragma mark - Table Handling

- (NSUInteger)unread_rows
{
  NSUInteger res = 0;
  InfinitPeerTransactionManager* manager = [InfinitPeerTransactionManager sharedInstance];
  for (InfinitPeerTransaction* transaction in self.list)
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
  return (self.list.count > 0 ? self.list.count : 1);
}

- (CGFloat)tableView:(NSTableView*)tableView
         heightOfRow:(NSInteger)row
{
  return (self.list.count == 0 ? 279.0f : _row_height);
}

- (NSView*)tableView:(NSTableView*)tableView
  viewForTableColumn:(NSTableColumn*)tableColumn
                 row:(NSInteger)row
{
  if (self.list.count == 0)
    return [self.table_view makeViewWithIdentifier:@"no_transaction_cell" owner:self];

  InfinitTransactionCellView* cell = [self.table_view makeViewWithIdentifier:@"transaction_cell"
                                                                       owner:self];
  InfinitPeerTransaction* transaction = self.list[row];
  InfinitUser* user = transaction.other_user;
  InfinitPeerTransactionManager* manager = [InfinitPeerTransactionManager sharedInstance];
  [cell setupCellWithTransaction:transaction
         withRunningTransactions:[manager transferringTransactionsWithUser:user]
          andNotDoneTransactions:[manager incompleteTransactionsWithUser:user]
           andUnreadTransactions:[manager unreadTransactionsWithUser:user]
                     andProgress:[manager progressWithUser:user]];
  if ([InfinitOSVersion lessThan:{10, 9, 0}])
  {
    // WORKAROUND: Progress rendering glitches on 10.7 and 10.8.
    cell.identifier = nil;
  }
  return cell;
}

- (IBAction)tableViewAction:(NSTableView*)sender
{
  self.changing = YES;
  if (self.list.count == 0)
    return;

  [_progress_timer invalidate];
  NSInteger row = self.table_view.clickedRow;

  InfinitPeerTransaction* transaction = self.list[row];
  NSMutableIndexSet* other_rows =
    [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.list.count)];
  [other_rows removeIndex:row];

  [self.table_view beginUpdates];
  [self.list removeObjectsAtIndexes:other_rows];
  [self.table_view removeRowsAtIndexes:other_rows withAnimation:NSTableViewAnimationSlideRight];
  [self.table_view endUpdates];
  [self.delegate userGotClicked:transaction.other_user];
}

#pragma mark - Transaction Handling

- (void)transactionAdded:(InfinitPeerTransaction*)transaction
{
  if (self.changing)
    return;

  if ([self.list containsObject:transaction])
    return;

  __block BOOL found = NO;

  // Check for exisiting transaction for this user
  [self.list enumerateObjectsUsingBlock:^(InfinitPeerTransaction* existing_transaction,
                                          NSUInteger row,
                                          BOOL* stop)
  {
    if ([existing_transaction.other_user isEqual:transaction.other_user])
    {
      [self.table_view beginUpdates];
      [self.list removeObject:existing_transaction];
      [self.list insertObject:transaction atIndex:0];
      [self.table_view removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:row]
                             withAnimation:NSTableViewAnimationSlideRight];
      [self.table_view insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:0]
                             withAnimation:NSTableViewAnimationSlideLeft];
      [self.table_view endUpdates];
      found = YES;
      *stop = YES;
    }
  }];
  if (!found) // Got transaction with new user
  {
    [self.table_view beginUpdates];
    [self.list insertObject:transaction atIndex:0];
    if (self.list.count == 1) // First transaction.
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
  if (self.changing)
    return;

  [self.list enumerateObjectsUsingBlock:^(InfinitPeerTransaction* existing_transaction,
                                          NSUInteger row,
                                          BOOL* stop)
  {
    if (existing_transaction.other_user == transaction.other_user)
    {
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
      *stop = YES;
    }
  }];
  [self updateListOfRowsWithProgress];
}

#pragma mark - User Status Handling

- (void)userUpdated:(InfinitUser*)user
{
  [self.list enumerateObjectsUsingBlock:^(InfinitPeerTransaction* transaction,
                                          NSUInteger row,
                                          BOOL* stop)
  {
    if ([transaction.other_user isEqual:user])
    {
      [self.table_view beginUpdates];
      [self.table_view reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row]
                                 columnIndexes:[NSIndexSet indexSetWithIndex:0]];
      [self.table_view endUpdates];
      *stop = YES;
    }
  }];
}

//- Avatar Callback --------------------------------------------------------------------------------

- (void)avatarCallback:(NSNotification*)notification
{
  if (self.changing)
    return;

  NSNumber* id_ = notification.userInfo[kInfinitUserId];
  InfinitUser* user = [InfinitUserManager userWithId:id_];
  if (user.avatar == nil)
    return;
  [self.list enumerateObjectsUsingBlock:^(InfinitPeerTransaction* transaction,
                                          NSUInteger row, 
                                          BOOL* stop)
  {
    if ([transaction.other_user isEqual:user])
    {
      InfinitTransactionCellView* cell =
        [self.table_view viewAtColumn:0 row:row makeIfNecessary:NO];
      if (cell == nil)
        return;
      [cell loadAvatarImage:user.avatar];
      *stop = YES;
    }
  }];
}

//- View Handling ----------------------------------------------------------------------------------

- (CGFloat)height
{
  if (self.list.count == 0)
    return 278.0f;
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
  [self.delegate transactionsViewResizeToHeight:self.height];
}

- (void)markTransactionsRead
{
  InfinitPeerTransactionManager* manager = [InfinitPeerTransactionManager sharedInstance];
  for (InfinitPeerTransaction* transaction in self.list)
  {
    NSUInteger active = [manager transferringTransactionsWithUser:transaction.other_user];
    NSUInteger unread = [manager unreadTransactionsWithUser:transaction.other_user];;
    if ((active == 0 && unread == 1) || (active == 1 && unread == 0))
      [manager markTransactionRead:transaction];
  }
}

- (void)closeToolTips
{
  [self.tooltip close];
}

#pragma mark - Button Handling

- (IBAction)tutorialButtonClicked:(id)sender
{
  NSString* name = InfinitOnboardingWindowController.className;
  _onboarding_window = [[InfinitOnboardingWindowController alloc] initWithWindowNibName:name];
  self.onboarding_window.delegate = self;
  [self.onboarding_window showWindow:self];
}

#pragma mark - Onboarding Protocol

- (void)onboardingWindowDidClose:(InfinitOnboardingWindowController*)sender
{
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(100 * NSEC_PER_MSEC)),
                 dispatch_get_main_queue(), ^
  {
    _onboarding_window = nil;
  });
}

@end
