//
//  InfinitConversationViewController.mm
//  InfinitApplication
//
//  Created by Christopher Crone on 17/03/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitConversationViewController.h"

#import "IAAvatarManager.h"
#import "InfinitConversationElement.h"
#import "InfinitConversationCellView.h"
#import "InfinitMetricsManager.h"

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("OSX.ConversationViewController");

//- Conversation Row View --------------------------------------------------------------------------

@interface InfinitConversationRowView : NSTableRowView
@end

@implementation InfinitConversationRowView

- (BOOL)isOpaque
{
  return YES;
}

@end

//- Conversation View Controller -------------------------------------------------------------------

@interface InfinitConversationViewController ()
@end

@implementation InfinitConversationViewController
{
@private
  id<InfinitConversationViewProtocol> _delegate;
    
  NSMutableArray* _elements;
  IAUser* _user;
  CGFloat _max_table_height;
  NSTimer* _progress_timer;
  NSMutableArray* _rows_with_progress;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithDelegate:(id<InfinitConversationViewProtocol>)delegate
               forUser:(IAUser*)user
      withTransactions:(NSArray*)transactions
{
  if (self = [super initWithNibName:self.className bundle:nil])
  {
    _delegate = delegate;
    _elements = [NSMutableArray arrayWithArray:[self sortTransactionList:transactions]];
    _user = user;
    _max_table_height = 320.0;
    _rows_with_progress = [[NSMutableArray alloc] init];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(avatarReceivedCallback:)
                                               name:IA_AVATAR_MANAGER_AVATAR_FETCHED
                                             object:nil];
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

- (NSArray*)sortTransactionList:(NSArray*)list
{
  NSSortDescriptor* ascending = [NSSortDescriptor sortDescriptorWithKey:nil
                                                              ascending:YES
                                                               selector:@selector(compare:)];
  NSArray* sorted_transactions =
    [list sortedArrayUsingDescriptors:[NSArray arrayWithObject:ascending]];
  NSMutableArray* element_list = [[NSMutableArray alloc] init];
  NSMutableArray* important_elements = [[NSMutableArray alloc] init];

  for (IATransaction* transaction in sorted_transactions)
  {
    InfinitConversationElement* element =
      [[InfinitConversationElement alloc] initWithTransaction:transaction];
    if (element.important)
    {
      [important_elements addObject:element];
    }
    else
    {
      [element_list addObject:element];
    }
  }
  // Add important elements to end of list.
  [element_list addObjectsFromArray:important_elements];
  InfinitConversationElement* spacer_element =
    [[InfinitConversationElement alloc] initWithTransaction:nil];
  [element_list addObject:spacer_element];
  [element_list insertObject:spacer_element atIndex:0];
  return element_list;
}

- (void)configurePersonView
{
  [self.person_view setDelegate:self];
  self.person_view.fullname.stringValue = _user.fullname;
  CGFloat width = [self.person_view.fullname.attributedStringValue size].width;
  self.person_view.fullname_width.constant = width;
  if (_user.status == gap_user_status_online)
  {
    self.person_view.online_status.image = [IAFunctions imageNamed:@"icon-status-online"];
  }
  else
  {
    self.person_view.online_status.image = [IAFunctions imageNamed:@"conversation-icon-status-offline"];
  }
  self.person_view.online_status.hidden = NO;
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
  ELLE_TRACE("%s: loadview for: %s", self.description.UTF8String, _user.fullname.UTF8String);
  [super loadView];
  [self configurePersonView];
  [self.table_view reloadData];
  [self resizeContentView];
  [self.table_view scrollRowToVisible:(self.table_view.numberOfRows - 1)];
  [self updateListOfRowsWithProgress];
}

//- View Functions ---------------------------------------------------------------------------------

- (void)resizeContentView
{
  if (self.content_height_constraint.constant == NSHeight(self.person_view.frame) + [self tableHeight])
    return;
  
  CGFloat new_height = NSHeight(self.person_view.frame) + [self tableHeight];
  
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
   {
     context.duration = 0.15;
   }
                      completionHandler:^
   {
     [self.content_height_constraint.animator setConstant:new_height];
   }];
}

//- Progress Update Functions ----------------------------------------------------------------------

- (void)setUpdatorRunning:(BOOL)is_running
{
	if (is_running && _progress_timer == nil)
		_progress_timer = [NSTimer scheduledTimerWithTimeInterval:1.5
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
  
  NSUInteger row = 0; // Start with the bottom transaction and work up
  for (InfinitConversationElement* element in _elements)
  {
    if (!element.spacer &&
        element.transaction.view_mode == TRANSACTION_VIEW_RUNNING)
    {
      [_rows_with_progress addObject:[NSNumber numberWithUnsignedInteger:row]];
    }
    row++;
  }
  
  if (_rows_with_progress.count > 0)
    [self setUpdatorRunning:YES];
  else
    [self setUpdatorRunning:NO];
}

- (void)updateProgress
{
  for (NSNumber* row in _rows_with_progress)
  {
    if (row.integerValue < _elements.count)
    {
      InfinitConversationCellView* cell = [self.table_view viewAtColumn:0
                                                                    row:row.unsignedIntegerValue
                                                        makeIfNecessary:NO];
      [cell updateProgress];
    }
  }
}

//- Table Handling ---------------------------------------------------------------------------------

- (CGFloat)tableHeight
{
  if (_elements.count * 86.0 >= _max_table_height)
  {
    return _max_table_height;
  }
  else
  {
    CGFloat height = 0.0;
    for (InfinitConversationElement* element in _elements)
    {
      height += [InfinitConversationCellView heightOfCellForElement:element];
    }
    if (height < _max_table_height)
      return height;
    else
      return _max_table_height;
  }
}

- (CGFloat)tableView:(NSTableView*)table_view
         heightOfRow:(NSInteger)row
{
  return [InfinitConversationCellView heightOfCellForElement:_elements[row]];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView*)tableView
{
  return _elements.count;
}

- (NSView*)tableView:(NSTableView*)tableView
  viewForTableColumn:(NSTableColumn*)tableColumn
                 row:(NSInteger)row
{
  InfinitConversationElement* element = _elements[row];

  if (element.spacer)
    return [self.table_view makeViewWithIdentifier:@"conversation_view_spacer" owner:self];

  InfinitConversationCellView* cell;
  
  NSString* left_right_select;
  if (element.on_left)
    left_right_select = @"left";
  else
    left_right_select = @"right";
  NSString* identifier_str = [NSString stringWithFormat:@"conversation_view_%@", left_right_select];
  
  cell = [self.table_view makeViewWithIdentifier:identifier_str owner:self];
  [cell setupCellForElement:element withDelegate:self];
  // WORKAROUND: Ensure that we don't reuse cells.
  cell.identifier = nil;
  return cell;
}

- (NSTableRowView*)tableView:(NSTableView*)tableView
               rowViewForRow:(NSInteger)row
{
  InfinitConversationRowView* row_view = [self.table_view rowViewAtRow:row makeIfNecessary:YES];
  if (row_view == nil)
    row_view = [[InfinitConversationRowView alloc] initWithFrame:NSZeroRect];
  return row_view;
}

//- Button Handling --------------------------------------------------------------------------------

- (void)backToNotificationView
{
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
   {
     context.duration = 0.15;
     [self.content_height_constraint.animator setConstant:NSHeight(self.person_view.frame)];
   }
                      completionHandler:^
   {
     [_delegate conversationViewWantsBack:self];
   }];
}

- (IBAction)backButtonClicked:(NSButton*)sender
{
  [self backToNotificationView];
}

- (IBAction)transferButtonClicked:(NSButton*)sender
{
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
   {
     context.duration = 0.15;
     [self.content_height_constraint.animator setConstant:44.0];
     [self.table_view removeFromSuperview];
   }
                      completionHandler:^
   {
     [_delegate conversationView:self wantsTransferForUser:_user];
     [InfinitMetricsManager sendMetric:INFINIT_METRIC_CONVERSATION_SEND];
   }];
}

- (IBAction)conversationCellViewWantsAccept:(NSButton*)sender
{
  NSUInteger row = [self.table_view rowForView:sender];
  InfinitConversationElement* element = _elements[row];
  [_delegate conversationView:self
       wantsAcceptTransaction:element.transaction];
  [InfinitMetricsManager sendMetric:INFINIT_METRIC_CONVERSATION_ACCEPT];
}

- (BOOL)transactionCancellable:(IATransactionViewMode)view_mode
{
  switch (view_mode)
  {
    case TRANSACTION_VIEW_ACCEPTED:
    case TRANSACTION_VIEW_ACCEPTED_WAITING_ONLINE:
    case TRANSACTION_VIEW_PAUSE_AUTO:
    case TRANSACTION_VIEW_PAUSE_USER:
    case TRANSACTION_VIEW_PENDING_SEND:
    case TRANSACTION_VIEW_PREPARING:
    case TRANSACTION_VIEW_RUNNING:
    case TRANSACTION_VIEW_WAITING_ACCEPT:
    case TRANSACTION_VIEW_WAITING_ONLINE:
    case TRANSACTION_VIEW_WAITING_REGISTER:
      return YES;
      
    default:
      return NO;
  }
}

- (IBAction)conversationCellViewWantsCancel:(NSButton*)sender
{
  NSUInteger row = [self.table_view rowForView:sender];
  InfinitConversationElement* element = _elements[row];
  
  if (![self transactionCancellable:element.transaction.view_mode])
    return;
  
  [_delegate conversationView:self
       wantsCancelTransaction:element.transaction];
  [InfinitMetricsManager sendMetric:INFINIT_METRIC_CONVERSATION_CANCEL];
}

- (IBAction)conversationCellViewWantsReject:(NSButton*)sender
{
  NSUInteger row = [self.table_view rowForView:sender];
  InfinitConversationElement* element = _elements[row];
  
  if (![self transactionCancellable:element.transaction.view_mode])
    return;

  [_delegate conversationView:self
       wantsRejectTransaction:element.transaction];
  [InfinitMetricsManager sendMetric:INFINIT_METRIC_CONVERSATION_REJECT];
}

//- Person View Protocol ---------------------------------------------------------------------------

- (void)conversationPersonViewGotClick:(InfinitConversationPersonView*)sender
{
  [self backToNotificationView];
}

//- Conversation Cell View Protocol ----------------------------------------------------------------

- (void)conversationCellViewWantsShowFiles:(InfinitConversationCellView*)sender
{
  NSInteger row = [self.table_view rowForView:sender];
  [_elements[row] setShowing_files:YES];
  [sender showFiles];
  [self.table_view noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:row]];
  [self resizeContentView];
  if (row == _elements.count - 2)
  {
    [self performSelector:@selector(scrollAfterRowAdd)
               withObject:nil
               afterDelay:0.15];
  }
}

- (void)conversationCellViewWantsHideFiles:(InfinitConversationCellView*)sender
{
  NSInteger row = [self.table_view rowForView:sender];
  [_elements[row] setShowing_files:NO];
  [sender hideFiles];
  [self.table_view noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:row]];
  [self resizeContentView];
}

//- Transaction Callbacks --------------------------------------------------------------------------

- (void)scrollAfterRowAdd
{
  [self.table_view scrollRowToVisible:(self.table_view.numberOfRows - 1)];
}

- (void)transactionAdded:(IATransaction*)transaction
{
  if (![transaction.other_user isEqual:_user])
    return;
  
  InfinitConversationElement* element =
    [[InfinitConversationElement alloc] initWithTransaction:transaction];
  [self.table_view beginUpdates];
  NSUInteger list_bottom = _elements.count - 1;
  [_elements insertObject:element atIndex:list_bottom];
  [self.table_view insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:list_bottom]
                         withAnimation:NSTableViewAnimationSlideDown];
  [self.table_view endUpdates];
  [self resizeContentView];
  
  // XXX Scrolling before row animation is complete doesn't scroll properly
  [self performSelector:@selector(scrollAfterRowAdd)
             withObject:nil
             afterDelay:0.2];
  
  [self updateListOfRowsWithProgress];
}

- (void)transactionUpdated:(IATransaction*)transaction
{
  if (![transaction.other_user isEqual:_user])
    return;
  
  NSUInteger count = 0;
  for (InfinitConversationElement* element in _elements)
  {
    if ([element.transaction.transaction_id isEqualToNumber:transaction.transaction_id])
      break;
    count++;
  }
  
  if (count >= _elements.count)
    return;
  
  InfinitConversationCellView* cell = [self.table_view viewAtColumn:0 row:count makeIfNecessary:NO];
  if (cell == nil)
    return;
  
  [cell onTransactionModeChange];
  
  [self updateListOfRowsWithProgress];
  
  if (count == _elements.count - 2)
    [self.table_view scrollRowToVisible:(_elements.count - 1)];
  else
    [self.table_view scrollRowToVisible:count];
}

//- User Callbacks ---------------------------------------------------------------------------------

- (void)userUpdated:(IAUser*)user
{
  if (![user isEqual:_user])
    return;
  
  [self configurePersonView];
}

//- Avatar Callbacks -------------------------------------------------------------------------------

- (void)avatarReceivedCallback:(NSNotification*)notification
{
  IAUser* user = [notification.userInfo objectForKey:@"user"];
  NSImage* image = [notification.userInfo objectForKey:@"avatar"];
  for (NSInteger index = 0; index < _elements.count; index++)
  {
    InfinitConversationElement* element = _elements[index];
    if (!element.spacer && element.transaction.sender == user)
    {
      InfinitConversationCellView* cell =
        [self.table_view viewAtColumn:0 row:index makeIfNecessary:NO];
      if (cell != nil)
        [cell updateAvatarWithImage:image];
    }
  }
}

//- Change View Handling ---------------------------------------------------------------------------

- (void)aboutToChangeView
{
  [self setUpdatorRunning:NO];
  [_delegate conversationView:self wantsMarkTransactionsReadForUser:_user];
}

@end
