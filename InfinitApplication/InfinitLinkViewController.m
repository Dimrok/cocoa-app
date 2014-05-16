//
//  InfinitLinkViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 13/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitLinkViewController.h"

@interface InfinitLinkViewController ()

@end

@implementation InfinitLinkViewController
{
@private
  id<InfinitLinkViewProtocol> _delegate;
  NSMutableArray* _list;

  CGFloat _row_height;
  NSInteger _max_rows;

  // Progress handling.
  NSTimer* _progress_timer;
  NSMutableArray* _rows_with_progress;
}

//- Init -------------------------------------------------------------------------------------------

- (id)initWithDelegate:(id<InfinitLinkViewProtocol>)delegate
           andLinkList:(NSArray*)list
{
  if (self = [super initWithNibName:self.className bundle:nil])
  {
    _delegate = delegate;
    _list = [NSMutableArray arrayWithArray:list];
    _max_rows = 4;
    _row_height = 72.0;
  }
  return self;
}

- (void)dealloc
{
  _progress_timer = nil;
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

  for (InfinitLinkTransaction* link in _list)
  {
    if (link.status == gap_transaction_transferring)
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
      InfinitLinkCellView* cell = [self.table_view viewAtColumn:0 row:row
                                                makeIfNecessary:NO];
      InfinitLinkTransaction* link = _list[row];
      cell.progress = link.progress.doubleValue;
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
  [cell setupCellWithLink:_list[row] andDelegate:self];
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
  CGFloat height = self.table_view.numberOfRows * _row_height;
  if (height > _max_rows * _row_height)
    return _max_rows * _row_height;
  else
    return height;
}

- (void)setChanging:(BOOL)changing
{
  _changing = changing;
  if (changing)
    [_progress_timer invalidate];
  else
    [self updateListOfRowsWithProgress];
}

//- Cell Protocol ----------------------------------------------------------------------------------

- (void)linkCell:(InfinitLinkCellView*)sender
gotCopyToClipboardForLink:(InfinitLinkTransaction*)link
{
  [_delegate linkGotCopiedToPasteBoard:link];
}

@end
