//
//  InfinitLinkViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 13/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitLinkViewController.h"
#import "InfinitTooltipViewController.h"

#import "InfinitMetricsManager.h"

#import <surface/gap/enums.hh>

@interface InfinitLinkViewController ()

@end

@implementation InfinitLinkViewController
{
@private
  // WORKAROUND: 10.7 doesn't allow weak references to certain classes (like NSViewController)
  __unsafe_unretained id<InfinitLinkViewProtocol> _delegate;
  NSMutableArray* _list;

  CGFloat _row_height;
  NSInteger _max_rows;

  // Progress handling.
  NSTimer* _progress_timer;
  NSMutableArray* _rows_with_progress;

  gap_UserStatus _me_status;

  InfinitTooltipViewController* _tooltip_controller;
  NSString * _delete_link_message;
}

//- Init -------------------------------------------------------------------------------------------

- (id)initWithDelegate:(id<InfinitLinkViewProtocol>)delegate
           andLinkList:(NSArray*)list
         andSelfStatus:(gap_UserStatus)status
{
  if (self = [super initWithNibName:self.className bundle:nil])
  {
    _delegate = delegate;
    _list = [NSMutableArray arrayWithArray:list];
    _max_rows = 4;
    _row_height = 72.0;
    _me_status = status;
    _tooltip_controller = nil;
    _delete_link_message = NSLocalizedString(@"Click again to delete", nil);
  }
  return self;
}

- (void)dealloc
{
  self.table_view.delegate = nil;
  self.table_view.dataSource = nil;
  _delegate = nil;
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
}

- (void)updateModelWithList:(NSArray*)list
{
  _list = [NSMutableArray arrayWithArray:list];
  [self.table_view reloadData];
  [self updateListOfRowsWithProgress];
}

- (void)selfStatusChanged:(gap_UserStatus)status
{
  [self.table_view reloadData];
  _me_status = status;
}

//- Link Updated -----------------------------------------------------------------------------------

- (void)linkAdded:(InfinitLinkTransaction*)link
{
  [_list insertObject:link atIndex:0];
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
  [self updateListOfRowsWithProgress];
}

- (void)linkUpdated:(InfinitLinkTransaction*)link
{
  NSUInteger row = 0;
  for (InfinitLinkTransaction* existing in _list)
  {
    if (existing.id_.unsignedIntegerValue == link.id_.unsignedIntegerValue)
    {
      if (link.status == gap_transaction_failed ||
          link.status == gap_transaction_canceled ||
          link.status == gap_transaction_deleted)
      {
        [self.table_view beginUpdates];
        [_list removeObject:link];
        [self.table_view removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:row]
                               withAnimation:NSTableViewAnimationSlideRight];
        if (_list.count == 0)
        {
          [self.table_view insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:0]
                                 withAnimation:NSTableViewAnimationSlideRight];
        }
        [self.table_view endUpdates];
        [_delegate linksViewResizeToHeight:self.height];
      }
      else
      {
        [_list replaceObjectAtIndex:row withObject:link];
        [self.table_view beginUpdates];
        [self.table_view reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row]
                                   columnIndexes:[NSIndexSet indexSetWithIndex:0]];
        [self.table_view endUpdates];
      }
      break;
    }
    row++;
  }
  [self updateListOfRowsWithProgress];
}

//- Progress Handling ------------------------------------------------------------------------------

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
  if (_list.count == 0)
    return;

  if (_rows_with_progress == nil)
    _rows_with_progress = [NSMutableArray array];
  else
    [_rows_with_progress removeAllObjects];

  NSUInteger row = 0;

  if (_me_status == gap_user_status_online)
    {
    for (InfinitLinkTransaction* link in _list)
    {
      if (link.status == gap_transaction_transferring)
      {
        [_rows_with_progress addObject:[NSNumber numberWithUnsignedInteger:row]];
      }
      row++;
    }
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
      InfinitLinkCellView* cell = [self.table_view viewAtColumn:0 row:row makeIfNecessary:NO];
      InfinitLinkTransaction* link = _list[row];
      cell.progress = link.progress;
    }
  }
}

//- Table Handling ---------------------------------------------------------------------------------

- (BOOL)tableView:(NSTableView*)tableView
  shouldSelectRow:(NSInteger)row
{
  return NO;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView*)tableView
{
  if (_list.count == 0)
    return 1;
  else
    return _list.count;
}

- (NSView*)tableView:(NSTableView*)tableView
  viewForTableColumn:(NSTableColumn*)tableColumn
                 row:(NSInteger)row
{
  if (_list.count == 0)
    return [self.table_view makeViewWithIdentifier:@"no_link_cell" owner:self];

  InfinitLinkCellView* cell = [self.table_view makeViewWithIdentifier:@"link_cell" owner:self];
  [cell setupCellWithLink:_list[row] andDelegate:self withOnlineStatus:_me_status];
  return cell;
}

//- View Handling ----------------------------------------------------------------------------------

- (NSUInteger)linksRunning
{
  NSUInteger res = 0;
  for (InfinitLinkTransaction* transaction in _list)
  {
    if (transaction.status == gap_transaction_transferring)
      res++;
  }
  return res;
}

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
  [_delegate linksViewResizeToHeight:self.height];
}

//- Cell Protocol ----------------------------------------------------------------------------------

- (void)linkCell:(InfinitLinkCellView*)sender
gotCancelForLink:(InfinitLinkTransaction*)link
{
  [_progress_timer invalidate];
  NSInteger row = [self.table_view rowForView:sender];
  [self.table_view beginUpdates];
  [_list removeObject:link];
  [self.table_view removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:row]
                         withAnimation:NSTableViewAnimationSlideRight];
  if (_list.count == 0)
  {
    [self.table_view insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:0]
                           withAnimation:NSTableViewAnimationSlideRight];
  }
  [self.table_view endUpdates];
  [_delegate cancelLink:link];
  [_delegate linksViewResizeToHeight:self.height];
  [self updateListOfRowsWithProgress];
}

- (void)linkCell:(InfinitLinkCellView*)sender
gotCopyToClipboardForLink:(InfinitLinkTransaction*)link
{
  [_delegate copyLinkToPasteBoard:link];
}

- (void)linkCell:(InfinitLinkCellView*)sender
gotDeleteForLink:(InfinitLinkTransaction*)link
{
  if (sender.delete_clicks < 2)
  {
    if (_tooltip_controller == nil)
      _tooltip_controller = [[InfinitTooltipViewController alloc] init];
    [_tooltip_controller showPopoverForView:sender.delete_link
                         withArrowDirection:INPopoverArrowDirectionLeft
                                withMessage:_delete_link_message
                           withPopAnimation:NO
                                    forTime:5.0];
  }
  else
  {
    [_tooltip_controller close];
    NSUInteger row = [self.table_view rowForView:sender];
    [self.table_view beginUpdates];
    [_list removeObject:link];
    [self.table_view removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:row]
                           withAnimation:NSTableViewAnimationSlideRight];
    [self.table_view endUpdates];
    [_delegate deleteLink:link];
    [_delegate linksViewResizeToHeight:self.height];
    if (_list.count == 0)
      [self.table_view reloadData];
    [self updateListOfRowsWithProgress];
    [InfinitMetricsManager sendMetric:INFINIT_METRIC_MAIN_DELETE_LINK];
  }
}

- (void)linkCellLostMouseHover:(InfinitLinkCellView*)sender
{
  [_tooltip_controller close];
  if (_list.count == 0)
    return;
  NSUInteger row = [self.table_view rowForView:sender];
  for (NSUInteger i = 0; i < self.table_view.numberOfRows; i++)
  {
    if (i != row)
    {
      [[self.table_view viewAtColumn:0 row:i makeIfNecessary:NO] hideControls];
    }
  }
}

@end
