//
//  InfinitLinkViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 13/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitLinkViewController.h"

#import "IAHoverButton.h"
#import "InfinitMetricsManager.h"
#import "InfinitOnboardingWindowController.h"
#import "InfinitTooltipViewController.h"

#import <Gap/InfinitColor.h>
#import <Gap/InfinitConnectionManager.h>
#import <Gap/InfinitLinkTransactionManager.h>

@interface InfinitLinkViewController () <InfinitLinkCellProtocol,
                                         InfinitOnboardingWindowProtocol,
                                         NSTableViewDataSource,
                                         NSTableViewDelegate>

@property (nonatomic, weak) IBOutlet NSTableView* table_view;
@property (nonatomic, weak) IBOutlet IAHoverButton* tutorial_button;

@property (nonatomic, unsafe_unretained) id<InfinitLinkViewProtocol> delegate;
@property (atomic, readonly) NSMutableArray* list;
@property (nonatomic, readonly) BOOL me_status;
@property (nonatomic, readonly) InfinitOnboardingWindowController* onboarding_window;
@property (nonatomic, readonly) NSTimer* progress_timer;
@property (nonatomic, readonly) NSMutableArray* rows_with_progress;
@property (nonatomic, readonly) BOOL scrolling;
@property (nonatomic, readonly)  InfinitTooltipViewController* tooltip_controller;

@end

static dispatch_once_t _awake_token = 0;
static NSString* _delete_link_message;
static NSInteger _max_rows = 4;
static CGFloat _row_height = 72.0f;

@implementation InfinitLinkViewController

#pragma mark - Init

- (id)initWithDelegate:(id<InfinitLinkViewProtocol>)delegate
{
  if (self = [super initWithNibName:self.className bundle:nil])
  {
    _delegate = delegate;
    _delete_link_message = NSLocalizedString(@"Click again to delete", nil);
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(connectionStatusChanged:)
                                                 name:INFINIT_CONNECTION_STATUS_CHANGE
                                               object:nil];
    _me_status = [InfinitConnectionManager sharedInstance].connected;
    [self updateModel];
  }
  return self;
}

- (void)dealloc
{
  self.table_view.delegate = nil;
  self.table_view.dataSource = nil;
  _delegate = nil;
  if (self.progress_timer != nil)
  {
    [self.progress_timer invalidate];
    _progress_timer = nil;
  }
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
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
  });
}

- (void)updateModel
{
  _list = [[InfinitLinkTransactionManager sharedInstance].transactions mutableCopy];
  [self.table_view reloadData];
  [self updateListOfRowsWithProgress];
}

- (void)scrollToTop
{
  [self.table_view scrollRowToVisible:0];
}

- (void)connectionStatusChanged:(NSNotification*)notification
{
  [self.table_view reloadData];
  InfinitConnectionStatus* connection_status = notification.object;
  _me_status = connection_status.status;
}

#pragma mark - Scroll Handling

- (void)tableDidScroll:(NSNotification*)notification
{
  if (!self.scrolling)
  {
    _scrolling = YES;
    for (NSUInteger i = 0; i < self.table_view.numberOfRows; i++)
    {
      NSTableCellView* cell = [self.table_view viewAtColumn:0 row:i makeIfNecessary:NO];
      if ([cell isKindOfClass:InfinitLinkCellView.class])
        [(InfinitLinkCellView*)cell hideControls];
    }
  }
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(scrollDone) object:nil];
  [self performSelector:@selector(scrollDone) withObject:nil afterDelay:0.2f];
}

- (void)scrollDone
{
  _scrolling = NO;
  for (NSUInteger i = 0; i < self.table_view.numberOfRows; i++)
  {
    [[self.table_view viewAtColumn:0 row:i makeIfNecessary:NO] checkMouseInside];
  }
}

#pragma mark - Transaction Updates

- (void)linkAdded:(InfinitLinkTransaction*)link
{
  @synchronized(self)
  {
    [self.table_view beginUpdates];
    [self.list insertObject:link atIndex:0];
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
    [self updateListOfRowsWithProgress];
  }
}

- (BOOL)ignoredStatus:(gap_TransactionStatus)status
{
  switch (status)
  {
    case gap_transaction_canceled:
    case gap_transaction_deleted:
    case gap_transaction_failed:
      return YES;

    default:
      return NO;
  }
}

- (void)linkUpdated:(InfinitLinkTransaction*)link
{
  @synchronized(self)
  {
    [self.list enumerateObjectsUsingBlock:^(InfinitLinkTransaction* existing,
                                            NSUInteger row,
                                            BOOL* stop)
    {
      if (existing.id_.unsignedIntegerValue == link.id_.unsignedIntegerValue)
      {
        if ([self ignoredStatus:link.status])
        {
          [self.table_view beginUpdates];
          [self.list removeObject:link];
          [self.table_view removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:row]
                                 withAnimation:NSTableViewAnimationSlideRight];
          if (self.list.count == 0)
          {
            [self.table_view insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:0]
                                   withAnimation:NSTableViewAnimationSlideRight];
          }
          [self.table_view endUpdates];
          [self.delegate linksViewResizeToHeight:self.height];
        }
        else
        {
          [self.table_view beginUpdates];
          [self.list replaceObjectAtIndex:row withObject:link];
          [self.table_view reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row]
                                     columnIndexes:[NSIndexSet indexSetWithIndex:0]];
          [self.table_view endUpdates];
        }
        *stop = YES;
      }
    }];
    [self updateListOfRowsWithProgress];
  }
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

  if (self.me_status)
  {
    [self.list enumerateObjectsUsingBlock:^(InfinitLinkTransaction* link,
                                            NSUInteger row, 
                                            BOOL* stop)
    {
      if (link.status == gap_transaction_transferring)
        [_rows_with_progress addObject:[NSNumber numberWithUnsignedInteger:row]];
    }];
  }

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
      InfinitLinkCellView* cell = [self.table_view viewAtColumn:0 row:row makeIfNecessary:NO];
      InfinitLinkTransaction* link = _list[row];
      cell.progress = link.progress;
    }
  }
}

#pragma mark - Table Handling

- (BOOL)tableView:(NSTableView*)tableView
  shouldSelectRow:(NSInteger)row
{
  return NO;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView*)tableView
{
  return self.list.count == 0 ? 1 : self.list.count;
}

- (CGFloat)tableView:(NSTableView*)tableView
         heightOfRow:(NSInteger)row
{
  return self.list.count == 0 ? 278.0f : _row_height;
}

- (NSView*)tableView:(NSTableView*)tableView
  viewForTableColumn:(NSTableColumn*)tableColumn
                 row:(NSInteger)row
{
  if (self.list.count == 0)
    return [self.table_view makeViewWithIdentifier:@"no_link_cell" owner:self];

  InfinitLinkCellView* cell = [self.table_view makeViewWithIdentifier:@"link_cell" owner:self];
  [cell setupCellWithLink:_list[row] andDelegate:self withOnlineStatus:_me_status];
  cell.identifier = nil;
  return cell;
}

#pragma mark - View Handling

- (NSUInteger)links_running
{
  NSUInteger res = 0;
  for (InfinitLinkTransaction* transaction in self.list)
  {
    if (transaction.status == gap_transaction_transferring)
      res++;
  }
  return res;
}

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
    [self.progress_timer invalidate];
    _progress_timer = nil;
  }
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)resizeView
{
  _scrolling = YES;
  [self.delegate linksViewResizeToHeight:self.height];
}

- (void)resizeComplete
{
  _scrolling = NO;
}

#pragma mark - Cell Protocol

- (void)linkCell:(InfinitLinkCellView*)sender
gotCancelForLink:(InfinitLinkTransaction*)link
{
  [self.progress_timer invalidate];
  NSInteger row = [self.table_view rowForView:sender];
  [self.table_view beginUpdates];
  [self.list removeObject:link];
  [self.table_view removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:row]
                         withAnimation:NSTableViewAnimationSlideRight];
  if (self.list.count == 0)
  {
    [self.table_view insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:0]
                           withAnimation:NSTableViewAnimationSlideRight];
  }
  [self.table_view endUpdates];
  [[InfinitLinkTransactionManager sharedInstance] cancelTransaction:link];
  [self.delegate linksViewResizeToHeight:self.height];
  [self updateListOfRowsWithProgress];
}

- (void)linkCell:(InfinitLinkCellView*)sender
gotCopyToClipboardForLink:(InfinitLinkTransaction*)link
{
  [self.delegate copyLinkToPasteBoard:link];
}

- (void)linkCell:(InfinitLinkCellView*)sender
gotDeleteForLink:(InfinitLinkTransaction*)link
{
  if (sender.delete_clicks < 2)
  {
    if (self.tooltip_controller == nil)
      _tooltip_controller = [[InfinitTooltipViewController alloc] init];
    [self.tooltip_controller showPopoverForView:sender.delete_link
                             withArrowDirection:INPopoverArrowDirectionLeft
                                    withMessage:_delete_link_message
                               withPopAnimation:NO
                                        forTime:5.0f];
  }
  else
  {
    [self.tooltip_controller close];
    NSUInteger row = [self.table_view rowForView:sender];
    [self.table_view beginUpdates];
    [self.list removeObject:link];
    [self.table_view removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:row]
                           withAnimation:NSTableViewAnimationSlideRight];
    [self.table_view endUpdates];
    [self.delegate linksViewResizeToHeight:self.height];
    if (self.list.count == 0)
      [self.table_view reloadData];
    [self updateListOfRowsWithProgress];
    [InfinitMetricsManager sendMetric:INFINIT_METRIC_MAIN_DELETE_LINK];
    [[InfinitLinkTransactionManager sharedInstance] deleteTransaction:link];
  }
}

- (void)linkCellLostMouseHover:(InfinitLinkCellView*)sender
{
  [self.tooltip_controller close];
  if (self.list.count == 0)
    return;
  NSUInteger row = [self.table_view rowForView:sender];
  for (NSUInteger i = 0; i < self.table_view.numberOfRows; i++)
  {
    if (i != row)
    {
      NSTableCellView* cell = [self.table_view viewAtColumn:0 row:i makeIfNecessary:NO];
      if ([cell isKindOfClass:InfinitLinkCellView.class])
        [(InfinitLinkCellView*)cell hideControls];
    }
  }
}

- (BOOL)userScrolling:(InfinitLinkCellView*)sender
{
  return _scrolling;
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
