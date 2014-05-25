//
//  InfinitConversationViewController.mm
//  InfinitApplication
//
//  Created by Christopher Crone on 17/03/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitConversationViewController.h"

#import <surface/gap/enums.hh>

#import "IAAvatarManager.h"
#import "InfinitConversationElement.h"
#import "InfinitConversationCellView.h"
#import "InfinitMetricsManager.h"
#import "InfinitTooltipViewController.h"

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
  InfinitTooltipViewController* _tooltip;
  BOOL _changing;
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
    _max_table_height = 290.0;
    _rows_with_progress = [[NSMutableArray alloc] init];
    _changing = NO;
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
  if ([_delegate onboardingState:self] == INFINIT_ONBOARDING_RECEIVE_ACTION_DONE)
  {
    [_delegate setOnboardingState:INFINIT_ONBOARDING_RECEIVE_CONVERSATION_VIEW_DONE];
  }
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
  NSFont* font = [NSFont fontWithName:@"Helvetica" size:12.0];
  NSMutableParagraphStyle* para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
  para.alignment = NSCenterTextAlignment;
  NSDictionary* attrs = [IAFunctions textStyleWithFont:font
                                        paragraphStyle:para
                                                colour:IA_GREY_COLOUR(32)
                                                shadow:nil];
  if (_user.deleted)
  {
    NSString* deleted_str = [NSString stringWithFormat:@"%@ (%@)",
                             _user.fullname, NSLocalizedString(@"deleted", nil)];
    self.person_view.fullname.attributedStringValue =
      [[NSAttributedString alloc] initWithString:deleted_str attributes:attrs];
  }
  else
  {
    self.person_view.fullname.attributedStringValue =
      [[NSAttributedString alloc] initWithString:_user.fullname attributes:attrs];
  }
  CGFloat width = [self.person_view.fullname.attributedStringValue size].width;
  if (width > 250)
    width = 250;
  self.person_view.fullname_width.constant = width;
  if (_user.ghost || _user.deleted)
  {
    self.person_view.online_status.hidden = YES;
  }
  else if (_user.status == gap_user_status_online)
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
  if ([[_delegate receiveOnboardingTransaction:self] other_user] == _user)
  {
    if ([_delegate onboardingState:self] == INFINIT_ONBOARDING_RECEIVE_IN_CONVERSATION_VIEW ||
        [_delegate onboardingState:self] == INFINIT_ONBOARDING_RECEIVE_CLICKED_ICON ||
        [_delegate onboardingState:self] == INFINIT_ONBOARDING_RECEIVE_NO_ACTION)
    {
      [_delegate setOnboardingState:INFINIT_ONBOARDING_RECEIVE_IN_CONVERSATION_VIEW];
      [self performSelector:@selector(delayedStartOnboarding) withObject:nil afterDelay:0.5];
    }
  }
  else if ([[_delegate sendOnboardingTransaction:self] other_user] == _user)
  {
    if ([_delegate onboardingState:self] == INFINIT_ONBOARDING_SEND_FILE_SENT)
    {
      [_delegate setOnboardingState:INFINIT_ONBOARDING_DONE];
      [self performSelector:@selector(delayedStatusOnboarding) withObject:nil afterDelay:0.5];
    }
  }
  [self updateListOfRowsWithProgress];
}

- (void)delayedStartOnboarding
{
  NSInteger row = [self _rowForTransaction:[_delegate receiveOnboardingTransaction:self]];
  if (row == -1)
    return;

  if (_tooltip == nil)
    _tooltip = [[InfinitTooltipViewController alloc] init];
  InfinitConversationCellView* cell = [self.table_view viewAtColumn:0 row:row makeIfNecessary:NO];
  NSString* message = NSLocalizedString(@"Click here to accept", nil);
  [_tooltip showPopoverForView:cell.accept_button
            withArrowDirection:INPopoverArrowDirectionLeft
                   withMessage:message
              withPopAnimation:YES
                       forTime:5.0];
}

- (void)delayedStatusOnboarding
{
  NSInteger row = [self _rowForTransaction:[_delegate sendOnboardingTransaction:self]];
  if (row == -1)
    return;

  if (_tooltip == nil)
    _tooltip = [[InfinitTooltipViewController alloc] init];
  InfinitConversationCellView* cell = [self.table_view viewAtColumn:0 row:row makeIfNecessary:NO];
  NSString* message = NSLocalizedString(@"Hover here for the status", nil);
  [_tooltip showPopoverForView:cell.transaction_status_button
            withArrowDirection:INPopoverArrowDirectionRight
                   withMessage:message
              withPopAnimation:YES
                       forTime:5.0];
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
  if (_changing)
    return;

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
  if ((_elements.count - 2) * 86.0 >= _max_table_height)
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
     [self.content_height_constraint.animator setConstant:0.0];
   }
                      completionHandler:^
   {
     [_delegate conversationViewWantsBack:self];
   }];
}

- (IBAction)backButtonClicked:(NSButton*)sender
{
  if ([_delegate onboardingState:self] == INFINIT_ONBOARDING_RECEIVE_ACTION_DONE ||
      [_delegate onboardingState:self] == INFINIT_ONBOARDING_RECEIVE_CONVERSATION_VIEW_DONE ||
      [_delegate onboardingState:self] == INFINIT_ONBOARDING_RECEIVE_DONE)
  {
    [_delegate setOnboardingState:INFINIT_ONBOARDING_SEND_NO_FILES_NO_DESTINATION];
  }
  [self backToNotificationView];
}

- (IBAction)transferButtonClicked:(NSButton*)sender
{
  if ([_delegate onboardingState:self] == INFINIT_ONBOARDING_RECEIVE_ACTION_DONE ||
      [_delegate onboardingState:self] == INFINIT_ONBOARDING_RECEIVE_CONVERSATION_VIEW_DONE ||
      [_delegate onboardingState:self] == INFINIT_ONBOARDING_RECEIVE_DONE)
  {
    [_delegate setOnboardingState:INFINIT_ONBOARDING_SEND_NO_FILES_DESTINATION];
  }
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
   {
     context.duration = 0.15;
     [self.content_height_constraint.animator setConstant:0.0];
     [self.table_view removeFromSuperview];
   }
                      completionHandler:^
   {
     [_delegate conversationView:self wantsTransferForUser:_user];
     [InfinitMetricsManager sendMetric:INFINIT_METRIC_CONVERSATION_SEND];
   }];
}

- (NSInteger)_rowForTransaction:(IATransaction*)transaction
{
  NSInteger row = 0;
  for (InfinitConversationElement* element in _elements)
  {
    if (element.transaction.transaction_id.unsignedIntValue == transaction.transaction_id.unsignedIntValue)
      break;
    row++;
  }
  if (row == _elements.count)
    return -1;
  else
    return row;
}

- (void)delayedReceiveOnboardingDoneWithMessage:(NSString*)message
{
  NSUInteger row =
    [self _rowForTransaction:[_delegate receiveOnboardingTransaction:self]];
  if (row == -1)
    return;

  InfinitConversationCellView* cell = [self.table_view viewAtColumn:0 row:row makeIfNecessary:NO];
  [_tooltip showPopoverForView:cell.file_icon
            withArrowDirection:INPopoverArrowDirectionRight
                   withMessage:message
              withPopAnimation:YES
                       forTime:5.0];
}

- (IBAction)conversationCellViewWantsAccept:(NSButton*)sender
{
  NSUInteger row = [self.table_view rowForView:sender];
  InfinitConversationElement* element = _elements[row];
  [_delegate conversationView:self
       wantsAcceptTransaction:element.transaction];
  [InfinitMetricsManager sendMetric:INFINIT_METRIC_CONVERSATION_ACCEPT];
  if ([_delegate onboardingState:self] == INFINIT_ONBOARDING_RECEIVE_IN_CONVERSATION_VIEW &&
      [_delegate receiveOnboardingTransaction:self] == element.transaction)
  {
    [_delegate setOnboardingState:INFINIT_ONBOARDING_RECEIVE_ACTION_DONE];
    [_tooltip close];
    NSString* message = NSLocalizedString(@"Click here when it's done to open the file",
                                          nil);
    [self performSelector:@selector(delayedReceiveOnboardingDoneWithMessage:)
               withObject:message
               afterDelay:0.5];
  }
}

- (BOOL)transactionCancellable:(IATransactionViewMode)view_mode
{
  switch (view_mode)
  {
    case TRANSACTION_VIEW_PENDING_SEND:
    case TRANSACTION_VIEW_WAITING_ACCEPT:
    case TRANSACTION_VIEW_ACCEPTED_WAITING_ONLINE:
    case TRANSACTION_VIEW_PREPARING:
    case TRANSACTION_VIEW_RUNNING:
    case TRANSACTION_VIEW_CLOUD_BUFFERED:
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
  
  if ([_delegate onboardingState:self] == INFINIT_ONBOARDING_RECEIVE_ACTION_DONE &&
      [_delegate receiveOnboardingTransaction:self] == element.transaction)
  {
    [_tooltip close];
    NSString* message = NSLocalizedString(@"Wow, that was harsh!", nil);
    [self performSelector:@selector(delayedReceiveOnboardingDoneWithMessage:)
               withObject:message
               afterDelay:0.5];
  }
  
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
  if ([_delegate onboardingState:self] == INFINIT_ONBOARDING_RECEIVE_IN_CONVERSATION_VIEW &&
      [_delegate receiveOnboardingTransaction:self] == element.transaction)
  {
    [_delegate setOnboardingState:INFINIT_ONBOARDING_RECEIVE_ACTION_DONE];
    [_tooltip close];
    NSString* message = NSLocalizedString(@"Wow, that was harsh!", nil);
    [self performSelector:@selector(delayedReceiveOnboardingDoneWithMessage:)
               withObject:message
               afterDelay:0.5];
  }
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
               afterDelay:0.2];
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

- (void)conversationCellBubbleViewGotClicked:(InfinitConversationCellView*)sender
{
  NSInteger row = [self.table_view rowForView:sender];
  if ([_delegate onboardingState:self] == INFINIT_ONBOARDING_RECEIVE_ACTION_DONE &&
      [_delegate receiveOnboardingTransaction:self] == [_elements[row] transaction])
  {
    [_delegate setOnboardingState:INFINIT_ONBOARDING_RECEIVE_VIEW_DOWNLOAD];
  }
}

//- Transaction Callbacks --------------------------------------------------------------------------

- (void)scrollAfterRowAdd
{
  [self.table_view scrollRowToVisible:(self.table_view.numberOfRows - 1)];
}

- (void)transactionAdded:(IATransaction*)transaction
{
  if (_changing)
    return;

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
  if (_changing)
    return;

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
  
  [cell onTransactionModeChangeIsNew:YES];
  [self.table_view noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:count]];
  
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

- (void)userDeleted:(IAUser*)user
{
  if (![user isEqual:_user])
    return;
  [self configurePersonView];
  self.transfer_button.enabled = NO;
  [self.transfer_button setToolTip:NSLocalizedString(@"User no longer on Infinit", nil)];
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
  _changing = YES;
  [_tooltip close];
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  [self setUpdatorRunning:NO];
  [_delegate conversationView:self wantsMarkTransactionsReadForUser:_user];
  if ([_delegate onboardingState:self] == INFINIT_ONBOARDING_SEND_FILE_SENT)
  {
    [_delegate setOnboardingState:INFINIT_ONBOARDING_DONE];
  }
}

@end
