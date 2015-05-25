//
//  InfinitConversationViewController.mm
//  InfinitApplication
//
//  Created by Christopher Crone on 17/03/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitConversationViewController.h"

#import <surface/gap/enums.hh>

#import "InfinitConversationElement.h"
#import "InfinitConversationCellView.h"
#import "InfinitConversationRowView.h"
#import "InfinitDownloadDestinationManager.h"
#import "InfinitMetricsManager.h"
#import "InfinitTooltipViewController.h"

#import <Gap/InfinitUser.h>
#import <Gap/InfinitPeerTransactionManager.h>
#import <Gap/InfinitUserManager.h>

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("OSX.ConversationViewController");

@interface InfinitConversationViewController () <NSTableViewDataSource,
                                                 NSTableViewDelegate,
                                                 InfinitConversationPersonViewProtocol,
                                                 InfinitConversationCellViewProtocol>

@property (nonatomic, weak) IBOutlet NSButton* back_button;
@property (nonatomic, weak) IBOutlet InfinitConversationPersonView* person_view;
@property (nonatomic, weak) IBOutlet NSScrollView* scroll_view;
@property (nonatomic, weak) IBOutlet NSTableView* table_view;
@property (nonatomic, weak) IBOutlet NSButton* transfer_button;

@property (atomic, readonly) NSMutableArray* elements;
@property (atomic, readonly) NSMutableArray* rows_with_progress;

@end

@implementation InfinitConversationViewController
{
@private
  __weak id<InfinitConversationViewProtocol> _delegate;

  CGFloat _max_table_height;
  NSTimer* _progress_timer;
  InfinitTooltipViewController* _tooltip;
  BOOL _changing;
  BOOL _initing;
}

#pragma mark - Init

- (id)initWithDelegate:(id<InfinitConversationViewProtocol>)delegate
               forUser:(InfinitUser*)user
{
  if (self = [super initWithNibName:self.className bundle:nil])
  {
    _delegate = delegate;
    _user = user;
    _max_table_height = 290.0;
    _changing = NO;
    _initing = YES;
    [self fillModel];
  }
  return self;
}

- (void)dealloc
{
  _delegate = nil;
  self.table_view.delegate = nil;
  self.table_view.dataSource = nil;
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  if (_progress_timer != nil)
  {
    [_progress_timer invalidate];
    _progress_timer = nil;
  }
}

- (void)fillModel
{
  NSArray* transactions =
    [[InfinitPeerTransactionManager sharedInstance] transactionsInvolvingUser:self.user];
  if (self.elements == nil)
    _elements = [NSMutableArray array];
  else
    [self.elements removeAllObjects];
  NSMutableArray* important_elements = [NSMutableArray array];
  for (InfinitPeerTransaction* transaction in transactions.reverseObjectEnumerator)
  {
    InfinitConversationElement* element =
      [InfinitConversationElement initWithTransaction:transaction];
    if (element.important)
      [important_elements addObject:element];
    else
      [self.elements addObject:element];
  }

  // Add important elements to end of list.
  [self.elements addObjectsFromArray:important_elements];
  InfinitConversationElement* spacer_element = [InfinitConversationElement initWithTransaction:nil];
  [self.elements addObject:spacer_element];
  [self.elements insertObject:spacer_element atIndex:0];
  _initing = NO;
}

- (void)configurePersonView
{
  [self.person_view setDelegate:self];
  NSFont* font = [NSFont fontWithName:@"Helvetica" size:12.0];
  NSMutableParagraphStyle* para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
  para.alignment = NSCenterTextAlignment;
  NSDictionary* attrs = [IAFunctions textStyleWithFont:font
                                        paragraphStyle:para
                                                colour:IA_GREY_COLOUR(32)
                                                shadow:nil];
  if (self.user.deleted)
  {
    NSString* deleted_str = [NSString stringWithFormat:@"%@ (%@)",
                             self.user.fullname, NSLocalizedString(@"deleted", nil)];
    self.person_view.fullname.attributedStringValue =
      [[NSAttributedString alloc] initWithString:deleted_str attributes:attrs];
  }
  else
  {
    self.person_view.fullname.attributedStringValue =
      [[NSAttributedString alloc] initWithString:self.user.fullname attributes:attrs];
  }
  CGFloat width = [self.person_view.fullname.attributedStringValue size].width;
  if (width > 250)
    width = 250;
  self.person_view.fullname_width.constant = width;
  if (self.user.ghost || self.user.deleted)
  {
    self.person_view.online_status.hidden = YES;
  }
  else if (self.user.status)
  {
    self.person_view.online_status.image = [IAFunctions imageNamed:@"icon-status-online"];
    self.person_view.online_status.hidden = NO;
    self.person_view.online_status.toolTip = NSLocalizedString(@"Online", nil);
  }
  else
  {
    self.person_view.online_status.image = [IAFunctions imageNamed:@"conversation-icon-status-offline"];
    self.person_view.online_status.hidden = NO;
    self.person_view.online_status.toolTip = NSLocalizedString(@"Offline", nil);
  }
}

- (void)awakeFromNib
{
  // WORKAROUND: Stop 15" Macbook Pro always rendering scroll bars
  // http://www.cocoabuilder.com/archive/cocoa/317591-can-hide-scrollbar-on-nstableview.html
  [self.table_view.enclosingScrollView setScrollerStyle:NSScrollerStyleOverlay];
  [self.table_view.enclosingScrollView.verticalScroller setControlSize:NSSmallControlSize];
  if (_user.deleted)
  {
    self.transfer_button.enabled = NO;
    [self.transfer_button setToolTip:NSLocalizedString(@"User no longer on Infinit", nil)];
  }
  else
  {
    self.transfer_button.enabled = YES;
  }
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
  if (self.content_height_constraint.constant == [self tableHeight])
    return;
  
  CGFloat new_height = [self tableHeight];
  
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
   {
     context.duration = 0.15;
   }
                      completionHandler:^
   {
     [self.content_height_constraint.animator setConstant:new_height];
   }];
}

#pragma mark - Progress Handling

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
    [self.rows_with_progress removeAllObjects];
  
  NSUInteger row = 0; // Start with the bottom transaction and work up
  for (InfinitConversationElement* element in _elements)
  {
    if (!element.spacer && element.transaction.status == gap_transaction_transferring)
    {
      [self.rows_with_progress addObject:@(row)];
    }
    row++;
  }

  if (self.rows_with_progress.count > 0)
    [self setUpdatorRunning:YES];
  else
    [self setUpdatorRunning:NO];
}

- (void)updateProgress
{
  if (_changing)
    return;

  for (NSNumber* row in self.rows_with_progress)
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

#pragma mark - Table Handling

- (CGFloat)tableHeight
{
  if ((self.elements.count - 2) * 86.0 >= _max_table_height)
  {
    return _max_table_height;
  }
  else
  {
    CGFloat height = 0.0;
    for (InfinitConversationElement* element in self.elements)
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
  return [InfinitConversationCellView heightOfCellForElement:self.elements[row]];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView*)tableView
{
  return self.elements.count;
}

- (NSView*)tableView:(NSTableView*)tableView
  viewForTableColumn:(NSTableColumn*)tableColumn
                 row:(NSInteger)row
{
  InfinitConversationElement* element = self.elements[row];

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

#pragma mark - Button Handling

- (void)backToNotificationView
{
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
   {
     context.duration = 0.15;
     [self.content_height_constraint.animator setConstant:0.0];
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
     [self.content_height_constraint.animator setConstant:0.0];
     [self.table_view removeFromSuperview];
   }
                      completionHandler:^
   {
     [_delegate conversationView:self wantsTransferForUser:self.user];
     [InfinitMetricsManager sendMetric:INFINIT_METRIC_CONVERSATION_SEND];
   }];
}

- (NSInteger)_rowForTransaction:(InfinitPeerTransaction*)transaction
{
  NSInteger row = 0;
  for (InfinitConversationElement* element in self.elements)
  {
    if (element.transaction.id_.unsignedIntValue == transaction.id_.unsignedIntValue)
      break;
    row++;
  }
  if (row == self.elements.count)
    return -1;
  else
    return row;
}

- (IBAction)conversationCellViewTopButtonClicked:(NSButton*)sender
{
  NSUInteger row = [self.table_view rowForView:sender];
  InfinitConversationElement* element = self.elements[row];
  if (element.transaction.status == gap_transaction_waiting_accept)
  {
    [[InfinitDownloadDestinationManager sharedInstance] ensureDownloadDestination];
    NSError* error = nil;
    BOOL success = [[InfinitPeerTransactionManager sharedInstance] acceptTransaction:element.transaction
                                                                           withError:nil];
    if (!success || error)
    {
      NSAlert* alert = nil;
      if (error)
      {
        alert = [NSAlert alertWithError:error];
      }
      else
      {
        NSString* message =
          NSLocalizedString(@"Unable to accept the transaction. "
                            "Please check you have sufficient free space", nil);
        alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Unable to accept", nil)
                                defaultButton:NSLocalizedString(@"OK", nil)
                              alternateButton:nil
                                  otherButton:nil
                    informativeTextWithFormat:@"%@", message];
      }
      [alert runModal];
    }
    [InfinitMetricsManager sendMetric:INFINIT_METRIC_CONVERSATION_ACCEPT];
  }
  else if (element.transaction.status == gap_transaction_paused)
  {
    [[InfinitPeerTransactionManager sharedInstance] resumeTransaction:element.transaction];
  }
  else
  {
    [[InfinitPeerTransactionManager sharedInstance] pauseTransaction:element.transaction];
  }
}

- (IBAction)conversationCellViewWantsCancel:(NSButton*)sender
{
  NSUInteger row = [self.table_view rowForView:sender];
  InfinitConversationElement* element = self.elements[row];

  if (element.transaction.done && element.transaction.status != gap_transaction_cloud_buffered)
    return;
  [[InfinitPeerTransactionManager sharedInstance] cancelTransaction:element.transaction];
  [InfinitMetricsManager sendMetric:INFINIT_METRIC_CONVERSATION_CANCEL];
}

- (IBAction)conversationCellViewBottomButtonClicked:(NSButton*)sender
{
  NSUInteger row = [self.table_view rowForView:sender];
  InfinitConversationElement* element = _elements[row];

  if (element.transaction.status == gap_transaction_waiting_accept)
  {
    [[InfinitPeerTransactionManager sharedInstance] rejectTransaction:element.transaction];
    [InfinitMetricsManager sendMetric:INFINIT_METRIC_CONVERSATION_REJECT];
  }
  else
  {
    [self conversationCellViewWantsCancel:sender];
  }
}

#pragma mark - Person View Protocol

- (void)conversationPersonViewGotClick:(InfinitConversationPersonView*)sender
{
  [self backToNotificationView];
}

#pragma mark - Conversation Cell View Protocol

- (void)conversationCellViewWantsShowFiles:(InfinitConversationCellView*)sender
{
  NSInteger row = [self.table_view rowForView:sender];
  InfinitConversationElement* element = self.elements[row];
  element.showing_files = YES;
  [sender showFiles];
  [self.table_view noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:row]];
  [self resizeContentView];
  if (row == self.elements.count - 2)
  {
    [self performSelector:@selector(scrollAfterRowAdd)
               withObject:nil
               afterDelay:0.2];
  }
}

- (void)conversationCellViewWantsHideFiles:(InfinitConversationCellView*)sender
{
  NSInteger row = [self.table_view rowForView:sender];
  InfinitConversationElement* element = self.elements[row];
  element.showing_files = NO;
  [sender hideFiles];
  [self.table_view noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:row]];
  [self resizeContentView];
}

- (void)conversationCellBubbleViewGotClicked:(InfinitConversationCellView*)sender
{
}

#pragma mark - Transaction Handling

- (void)scrollAfterRowAdd
{
  [self.table_view scrollRowToVisible:(self.table_view.numberOfRows - 1)];
}

- (void)transactionAdded:(NSNotification*)notification
{
  if (_changing)
    return;

  NSNumber* id_ = notification.userInfo[kInfinitTransactionId];
  InfinitPeerTransaction* transaction =
    [[InfinitPeerTransactionManager sharedInstance] transactionWithId:id_];

  if (![transaction.other_user isEqual:self.user])
    return;
  
  InfinitConversationElement* element = [InfinitConversationElement initWithTransaction:transaction];
  [self.table_view beginUpdates];
  NSUInteger list_bottom = self.elements.count - 1;
  [self.elements insertObject:element atIndex:list_bottom];
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

- (void)transactionUpdated:(NSNotification*)notification
{
  if (_changing)
    return;

  NSNumber* id_ = notification.userInfo[kInfinitTransactionId];
  InfinitPeerTransaction* transaction =
    [[InfinitPeerTransactionManager sharedInstance] transactionWithId:id_];

  if (![transaction.other_user isEqual:_user])
    return;
  
  NSUInteger count = 0;
  for (InfinitConversationElement* element in self.elements)
  {
    if ([element.transaction isEqual:transaction])
      break;
    count++;
  }
  
  if (count >= self.elements.count)
    return;
  
  InfinitConversationCellView* cell = [self.table_view viewAtColumn:0 row:count makeIfNecessary:NO];
  if (cell == nil)
    return;
  
  [cell onTransactionModeChangeIsNew:YES];
  [self.table_view noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:count]];
  
  [self updateListOfRowsWithProgress];
  
  if (count == self.elements.count - 2)
    [self.table_view scrollRowToVisible:(self.elements.count - 1)];
  else
    [self.table_view scrollRowToVisible:count];
}

#pragma mark - User Handling

- (void)userUpdated:(NSNotification*)notification
{
  NSNumber* id_ = notification.userInfo[kInfinitUserId];
  if (![self.user.id_ isEqual:id_])
    return;
  
  [self configurePersonView];
}

- (void)userDeleted:(NSNotification*)notification
{
  NSNumber* id_ = notification.userInfo[kInfinitUserId];
  if (![self.user.id_ isEqual:id_])
    return;
  [self configurePersonView];
  self.transfer_button.enabled = NO;
  [self.transfer_button setToolTip:NSLocalizedString(@"User no longer on Infinit", nil)];
}

#pragma mark - Avatar Handling

- (void)avatarReceivedCallback:(NSNotification*)notification
{
  NSNumber* id_ = notification.userInfo[kInfinitUserId];
  if (![self.user.id_ isEqual:id_])
    return;
  InfinitUser* user = [[InfinitUserManager sharedInstance] userWithId:id_];
  for (NSInteger index = 0; index < self.elements.count; index++)
  {
    InfinitConversationElement* element = _elements[index];
    if (!element.spacer && [element.transaction.sender isEqual:user])
    {
      InfinitConversationCellView* cell =
        [self.table_view viewAtColumn:0 row:index makeIfNecessary:NO];
      if (cell != nil)
        [cell updateAvatarWithImage:user.avatar];
    }
  }
}

#pragma mark - IAViewController

- (BOOL)closeOnFocusLost
{
  return YES;
}

- (void)viewActive
{
  if (!_initing)
    [self fillModel];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(avatarReceivedCallback:)
                                               name:INFINIT_USER_AVATAR_NOTIFICATION
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(userUpdated:)
                                               name:INFINIT_USER_STATUS_NOTIFICATION
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(userDeleted:)
                                               name:INFINIT_USER_DELETED_NOTIFICATION
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(transactionAdded:)
                                               name:INFINIT_NEW_PEER_TRANSACTION_NOTIFICATION
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(transactionUpdated:)
                                               name:INFINIT_PEER_TRANSACTION_STATUS_NOTIFICATION
                                             object:nil];
  [[InfinitPeerTransactionManager sharedInstance] markTransactionsWithUserRead:self.user];
}

- (void)aboutToChangeView
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  _changing = YES;
  [_tooltip close];
  [_progress_timer invalidate];
  _progress_timer = nil;
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  [self setUpdatorRunning:NO];
}

@end
