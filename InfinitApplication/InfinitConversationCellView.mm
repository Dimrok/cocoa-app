//
//  InfinitConversationCellView.mm
//  InfinitApplication
//
//  Created by Christopher Crone on 17/03/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitConversationCellView.h"
#import "InfinitConversationFileCellView.h"

#import <QuartzCore/QuartzCore.h>

#import "InfinitDownloadDestinationManager.h"

#import <Gap/InfinitDataSize.h>
#import <Gap/InfinitTime.h>
#import <Gap/InfinitUserManager.h>

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("OSX.ConversationCellView");

// WORKAROUND: Because 10.7 can't do maths
//- Message View -----------------------------------------------------------------------------------

@interface InfinitConversationMessageField : NSTextField
@end

@implementation InfinitConversationMessageField

- (NSSize)intrinsicContentSize
{
  if (![self.cell wraps])
    return [super intrinsicContentSize];
  
  NSRect frame = self.frame;
  
  CGFloat width = frame.size.width;
  
  // Make the frame very high, while keeping the width
  frame.size.height = CGFLOAT_MAX;
  
  // Calculate new height within the frame
  // with practically infinite height.
  CGFloat height = [self.cell cellSizeForBounds: frame].height;
  
  return NSMakeSize(width, height);
}

@end

//- Bubble View ------------------------------------------------------------------------------------

@interface InfinitConversationBubbleView : NSView

@property (nonatomic, readwrite) BOOL important;
@property (nonatomic, readwrite) BOOL clickable;
@property (nonatomic, readwrite) CGFloat hover;
@property (nonatomic, readwrite) id<InfinitConversationBubbleViewProtocol> delegate;
@property (nonatomic, readwrite) BOOL showing_list;

@end

@implementation InfinitConversationBubbleView
{
@private
  NSTrackingArea* _tracking_area;
}

- (void)drawRect:(NSRect)dirtyRect
{
  NSBezierPath* outter_ring;
  if (_showing_list)
  {
    outter_ring = [IAFunctions roundedTopBezierWithRect:self.bounds cornerRadius:5.0];
  }
  else
  {
    outter_ring = [NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:5.0 yRadius:5.0];
  }
  if (self.important)
  {
    [IA_GREY_COLOUR(255) set];
  }
  else
  {
    [IA_GREY_COLOUR(248 + (7 * _hover)) set];
  }
  [outter_ring fill];
  [IA_GREY_COLOUR(220) set];
  [outter_ring stroke];
}

- (void)setHover:(CGFloat)hover
{
  if (_hover == hover)
    return;
  _hover = hover;
  [self setNeedsDisplay:YES];
}

- (void)dealloc
{
  _tracking_area = nil;
}

- (void)createTrackingArea
{
  _tracking_area = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                options:(NSTrackingMouseEnteredAndExited |
                                                         NSTrackingActiveAlways)
                                                  owner:self
                                               userInfo:nil];
  
  [self addTrackingArea:_tracking_area];
  
  NSPoint mouse_loc = self.window.mouseLocationOutsideOfEventStream;
  mouse_loc = [self convertPoint:mouse_loc fromView:nil];
  if (NSPointInRect(mouse_loc, self.bounds))
    [self mouseEntered:nil];
  else
    [self mouseExited:nil];
}

- (void)updateTrackingAreas
{
  [self removeTrackingArea:_tracking_area];
  [self createTrackingArea];
  [super updateTrackingAreas];
}

- (void)mouseDown:(NSEvent*)event
{
  if (!self.clickable)
    return;
  [_delegate bubbleViewGotClick:self];
}

- (void)mouseEntered:(NSEvent*)theEvent
{
  if (!self.clickable)
    return;
  
  [_delegate bubbleViewGotHover:self];

  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
   {
     context.duration = 0.10;
     [self.animator setHover:1.0];
   }
                      completionHandler:^
   {
     _hover = 1.0;
   }];
}

- (void)mouseExited:(NSEvent*)theEvent
{
  if (!self.clickable)
    return;
  
  [_delegate bubbleViewGotUnHover:self];

  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
   {
     context.duration = 0.10;
     [self.animator setHover:0.0];
   }
                      completionHandler:^
   {
     _hover = 0.0;
   }];
}

+ (id)defaultAnimationForKey:(NSString*)key
{
  if ([key isEqualToString:@"hover"])
    return [CABasicAnimation animation];

  return [super defaultAnimationForKey:key];
}

@end

//- Conversation Cell View -------------------------------------------------------------------------

@implementation InfinitConversationCellView
{
@private
  // WORKAROUND: 10.7 doesn't allow weak references to certain classes (like NSViewController)
  __unsafe_unretained id<InfinitConversationCellViewProtocol> _delegate;
  InfinitConversationElement* _element;
  NSTrackingArea* _tracking_area;
  BOOL _hovered;
  BOOL _showing_files;
  NSTableView* _files_table;
  NSDictionary* _file_name_attrs;
  NSDictionary* _file_name_hover_attrs;
}

//- Initialisation ---------------------------------------------------------------------------------

- (void)dealloc
{
  _tracking_area = nil;
}

//- Properties -------------------------------------------------------------------------------------

+ (CGFloat)heightOfMessage:(NSString*)message
{
  if (message.length == 0)
    return 0.0;
  NSTextStorage* text_storage = [[NSTextStorage alloc] initWithString:message];
  NSSize text_area = NSMakeSize(200.0, FLT_MAX);
  NSTextContainer* text_container = [[NSTextContainer alloc] initWithContainerSize:text_area];
  NSLayoutManager* layout_manager = [[NSLayoutManager alloc] init];
  [layout_manager addTextContainer:text_container];
  [text_storage addLayoutManager:layout_manager];
  NSFont* font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica"
                                                            traits:NSUnboldFontMask
                                                            weight:0
                                                              size:12.0];
  [text_storage addAttribute:NSFontAttributeName value:font
                       range:NSMakeRange(0, [text_storage length])];
  [text_container setLineFragmentPadding:0.0];
  (void) [layout_manager glyphRangeForTextContainer:text_container];
  return [layout_manager usedRectForTextContainer:text_container].size.height + 7.0;
}

+ (CGFloat)heightOfFilesTable:(NSInteger)no_files
{
  return no_files * 35.0;
}

+ (BOOL)hasInformationField:(InfinitConversationElement*)element
{
  switch (element.transaction.status)
  {
    case gap_transaction_new:
    case gap_transaction_waiting_accept:
    case gap_transaction_waiting_data:
    case gap_transaction_cloud_buffered:
    case gap_transaction_connecting:
    case gap_transaction_transferring:
    case gap_transaction_paused:
    case gap_transaction_on_other_device:
    case gap_transaction_finished:
      if (element.transaction.from_device || element.transaction.to_device)
        return NO;
      return YES;

    default:
      return NO;
  }
}

+ (CGFloat)heightOfCellForElement:(InfinitConversationElement*)element
{
  if (element.spacer)
    return 10.0;
  CGFloat height = 86.0; // Size without message and file table.
  height += [InfinitConversationCellView heightOfMessage:element.transaction.message];
  if (element.showing_files)
    height += [InfinitConversationCellView heightOfFilesTable:element.transaction.files.count];
  if ([InfinitConversationCellView hasInformationField:element])
    height += 10;
  return height;
}

//- Mouse Tracking ---------------------------------------------------------------------------------

- (void)createTrackingArea
{
  _tracking_area = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                options:(NSTrackingMouseEnteredAndExited |
                                                         NSTrackingActiveAlways)
                                                  owner:self
                                               userInfo:nil];
  
  [self addTrackingArea:_tracking_area];
  
  NSPoint mouse_loc = self.window.mouseLocationOutsideOfEventStream;
  mouse_loc = [self convertPoint:mouse_loc fromView:nil];
  if (NSPointInRect(mouse_loc, self.bounds))
    [self mouseEntered:nil];
  else
    [self mouseExited:nil];
}

- (void)updateTrackingAreas
{
  [self removeTrackingArea:_tracking_area];
  [self createTrackingArea];
  [super updateTrackingAreas];
}

- (void)mouseEntered:(NSEvent*)theEvent
{
  _hovered = YES;
}

- (void)mouseExited:(NSEvent*)theEvent
{
  _hovered = NO;
}

//- Avatar Received Callback -----------------------------------------------------------------------

- (void)avatarReceivedCallback:(NSNotification*)notification
{
  if (_element == nil)
    return;

  NSNumber* id_ = notification.userInfo[kInfinitUserId];
  InfinitUser* user = [[InfinitUserManager sharedInstance] userWithId:id_];
  if ([user isEqual:_element.transaction.sender])
  {
    NSImage* avatar_image = user.avatar;
    [self updateAvatarWithImage:avatar_image];
  }
}

- (void)drawRect:(NSRect)dirtyRect
{
  [super drawRect:dirtyRect];
  
  // Drawing code here.
}

//- Configure Cell View ----------------------------------------------------------------------------

- (void)updateAvatarWithImage:(NSImage*)avatar_image
{
  self.avatar.image = [IAFunctions makeRoundAvatar:avatar_image
                                    ofDiameter:24.0
                         withBorderOfThickness:0.0
                                      inColour:IA_GREY_COLOUR(208.0)
                             andShadowOfRadius:0.0];
  [self.avatar setNeedsDisplay:YES];
}

- (void)configureAcceptRejectButtons
{
  self.accept_button.hand_cursor = YES;
  self.accept_button.hover_image = [IAFunctions imageNamed:@"conversation-icon-accept"];
  self.accept_button.hover_image = [IAFunctions imageNamed:@"conversation-icon-accept-hover"];
  self.reject_button.hand_cursor = YES;
  self.reject_button.hover_image = [IAFunctions imageNamed:@"conversation-icon-reject"];
  self.reject_button.hover_image = [IAFunctions imageNamed:@"conversation-icon-reject-hover"];
  [self.accept_button setToolTip:NSLocalizedString(@"Accept", nil)];
  [self.reject_button setToolTip:NSLocalizedString(@"Decline", nil)];
}

- (void)setTransactionStatusButtonToStaticImage:(NSString*)image_name
{
  self.accept_button.hidden = YES;
  self.reject_button.hidden = YES;
  self.progress.hidden = YES;
  [self.transaction_status_button.cell setImageDimsWhenDisabled:NO];
  self.transaction_status_button.enabled = NO;
  self.transaction_status_button.hidden = NO;
  self.transaction_status_button.hand_cursor = NO;
  self.transaction_status_button.normal_image = [IAFunctions imageNamed:image_name];
  self.transaction_status_button.hover_image = [IAFunctions imageNamed:image_name];
  self.transaction_status_button.image = [IAFunctions imageNamed:image_name];
}

- (void)setTransactionStatusButtonToCancel
{
  self.accept_button.hidden = YES;
  self.reject_button.hidden = YES;
  self.progress.hidden = YES;
  self.transaction_status_button.enabled = YES;
  self.transaction_status_button.hidden = NO;
  self.transaction_status_button.hand_cursor = YES;
  self.transaction_status_button.normal_image = [IAFunctions imageNamed:@"conversation-icon-reject"];
  self.transaction_status_button.hover_image =
    [IAFunctions imageNamed:@"conversation-icon-reject-hover"];
  [self.transaction_status_button setToolTip:NSLocalizedString(@"Cancel", nil)];
}

- (void)onTransactionModeChangeIsNew:(BOOL)is_new
{
  // If progress hasn't run until the end.
  if ((_element.transaction.status == gap_transaction_finished ||
      _element.transaction.status == gap_transaction_cloud_buffered) &&
      is_new && _progress.doubleValue < 1.0)
  {
    [self updateProgress];
    return;
  }

  self.bubble_view.important = _element.important;
  self.time_indicator.stringValue =
  [InfinitTime relativeDateOf:_element.transaction.mtime longerFormat:NO];

  switch (_element.transaction.status)
  {
    case gap_transaction_waiting_data:
      [self setTransactionStatusButtonToCancel];
      [self.progress setIndeterminate:NO];
      self.progress.doubleValue = _element.transaction.progress;
      self.progress.hidden = NO;
      self.information.stringValue = NSLocalizedString(@"Waiting for user to be online...", nil);
      self.information.hidden = NO;
      break;
    case gap_transaction_canceled:
      [self setTransactionStatusButtonToStaticImage:@"conversation-icon-canceled"];
      [self.transaction_status_button setToolTip:NSLocalizedString(@"Canceled", nil)];
      self.information.hidden = YES;
      break;
    case gap_transaction_cloud_buffered:
      if (_element.transaction.sender.is_self)
      {
        [self setTransactionStatusButtonToCancel];
        self.information.stringValue = NSLocalizedString(@"Uploaded. Waiting to be downloaded...", nil);
        self.information.hidden = NO;
      }
      break;
    case gap_transaction_failed:
      [self setTransactionStatusButtonToStaticImage:@"conversation-icon-error"];
      [self.transaction_status_button setToolTip:NSLocalizedString(@"Failed", nil)];
      self.information.hidden = YES;
      break;
    case gap_transaction_finished:
      [self setTransactionStatusButtonToStaticImage:@"conversation-icon-finished"];
      [self.transaction_status_button setToolTip:NSLocalizedString(@"Finished", nil)];
      if (!_element.transaction.from_device && !_element.transaction.to_device)
      {
        self.information.stringValue = NSLocalizedString(@"Finished on another device.", nil);
        self.information.hidden = NO;
      }
      else
      {
        self.information.hidden = YES;
      }
      break;
    case gap_transaction_new:
    case gap_transaction_connecting:
      [self setTransactionStatusButtonToCancel];
      [self.progress setIndeterminate:YES];
      self.progress.hidden = NO;
      self.information.stringValue = [self dataTransferredForTransaction:_element.transaction];
      self.information.hidden = NO;
      break;
    case gap_transaction_rejected:
      [self setTransactionStatusButtonToStaticImage:@"conversation-icon-canceled"];
      [self.transaction_status_button setToolTip:NSLocalizedString(@"Canceled", nil)];
      self.information.hidden = YES;
      break;
    case gap_transaction_transferring:
      [self setTransactionStatusButtonToCancel];
      [self.progress setIndeterminate:NO];
      self.progress.hidden = NO;
      self.progress.doubleValue = _element.transaction.progress;
      self.time_indicator.stringValue =
        [InfinitTime timeRemainingFrom:_element.transaction.time_remaining];
      self.information.stringValue = [self dataTransferredForTransaction:_element.transaction];
      self.information.hidden = NO;
      break;
    case gap_transaction_paused:
      [self setTransactionStatusButtonToCancel];
      [self.progress setIndeterminate:NO];
      self.progress.hidden = NO;
      self.progress.doubleValue = _element.transaction.progress;
      self.time_indicator.stringValue = @"";
      self.information.stringValue = NSLocalizedString(@"Transfer paused", nil);
      self.information.hidden = NO;
      break;
    case gap_transaction_waiting_accept:
      if (_element.transaction.receivable)
      {
        [self configureAcceptRejectButtons];
        self.accept_button.hidden = NO;
        self.reject_button.hidden = NO;
        self.transaction_status_button.hidden = YES;
        self.information.stringValue =
        [InfinitDataSize fileSizeStringFrom:_element.transaction.size];
      }
      else
      {
        [self setTransactionStatusButtonToCancel];
        if (_element.transaction.recipient.is_self)
          self.information.stringValue = NSLocalizedString(@"Accept on another device.", nil);
        else
          self.information.stringValue = NSLocalizedString(@"Waiting for user to accept...", nil);
      }
      self.information.hidden = NO;
      break;
    case gap_transaction_on_other_device:
      [self setTransactionStatusButtonToCancel];
      self.progress.hidden = YES;
      self.information.stringValue = NSLocalizedString(@"Transfer on another device...", nil);
      self.information.hidden = NO;
      break;

    default:
      ELLE_WARN("%s: unknown transaction status: %s",
                self.description.UTF8String, _element.transaction.status_text);
      break;
  }
  if (_element.transaction.files.count == 1)
  {
    if (_element.transaction.to_device &&
        _element.transaction.status == gap_transaction_finished)
    {
      self.bubble_view.clickable = YES;
    }
    else
    {
      self.bubble_view.clickable = NO;
    }
  }
  else
  {
    self.bubble_view.clickable = YES;
  }
}

- (void)showFiles
{
  self.file_list_icon.image = [NSImage imageNamed:@"conversation-icon-hide-files"];
  NSInteger file_count = _element.transaction.files.count;
  CGFloat bubble_height = self.bubble_height.constant;
  self.bubble_view.showing_list = YES;
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
   {
     self.bubble_height.constant = bubble_height;
   }
                      completionHandler:^
   {
     self.table_height.constant = [InfinitConversationCellView heightOfFilesTable:file_count];
     self.bubble_height.constant = bubble_height;
   }];
  [_files_table reloadData];
}

- (void)hideFiles
{
  self.file_list_icon.image = [NSImage imageNamed:@"conversation-icon-show-files"];
  
  CGFloat bubble_height = self.bubble_height.constant;
  self.bubble_view.showing_list = NO;
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
   {
     self.bubble_height.constant = bubble_height;
   }
                      completionHandler:^
   {
     self.table_height.constant = 0.0;
     self.bubble_height.constant = bubble_height;
   }];
}

- (void)setupCellForElement:(InfinitConversationElement*)element
               withDelegate:(id<InfinitConversationCellViewProtocol>)delegate
{
  _element = element;
  _delegate = delegate;
  self.bubble_view.delegate = self;
  InfinitPeerTransaction* transaction = element.transaction;
  self.table_height.constant = 0.0;
  if (transaction.files.count == 1)
  {
    self.file_name.stringValue = transaction.files[0];
    if (transaction.directory)
    {
      self.file_icon.image = [[NSWorkspace sharedWorkspace] iconForFileType:@"public.directory"];
    }
    else
    {
      self.file_icon.image =
        [[NSWorkspace sharedWorkspace] iconForFileType:[transaction.files[0] pathExtension]];
    }
    
    NSMutableParagraphStyle* para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    para.alignment = NSLeftTextAlignment;
    para.lineBreakMode = NSLineBreakByTruncatingMiddle;
    
    NSFont* font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica-Light"
                                                              traits:NSUnboldFontMask
                                                              weight:1
                                                                size:12.0];
    
    _file_name_attrs = [IAFunctions textStyleWithFont:font
                                       paragraphStyle:para
                                               colour:IA_GREY_COLOUR(60.0)
                                               shadow:nil];
    _file_name_hover_attrs = [IAFunctions textStyleWithFont:font
                                             paragraphStyle:para
                                                     colour:IA_RGB_COLOUR(102.0, 174.0, 211.0)
                                                     shadow:nil];
    self.file_list_icon.hidden = YES;
  }
  else
  {
    NSString* file_str = NSLocalizedString(@"files", nil);
    self.file_name.stringValue = [NSString stringWithFormat:@"%ld %@", transaction.files.count, file_str];
    self.file_icon.image = [[NSWorkspace sharedWorkspace] iconForFileType:@"public.directory"];
    self.file_list_icon.hidden = NO;
    NSRect table_frame = NSMakeRect(0.0, 0.0,
                                    NSWidth(self.table_container.frame),
                                    NSHeight(self.table_container.frame));
    _files_table = [[NSTableView alloc] initWithFrame:table_frame];
    NSTableColumn* col = [[NSTableColumn alloc] initWithIdentifier:@"Col1"];
    col.width = NSWidth(self.table_container.frame);
    [_files_table addTableColumn:col];
    _files_table.delegate = self;
    _files_table.dataSource = self;
    _files_table.headerView = nil;
    _files_table.backgroundColor = IA_GREY_COLOUR(248.0);
    _files_table.allowsColumnReordering = NO;
    _files_table.allowsColumnResizing = NO;
    _files_table.allowsEmptySelection = YES;
    _files_table.intercellSpacing = NSMakeSize(0.0, 0.0);
    [_files_table.enclosingScrollView setFocusRingType:NSFocusRingTypeNone];
    [_files_table reloadData];
    self.table_container.verticalScrollElasticity = NSScrollElasticityNone;
    self.table_container.documentView = _files_table;
    self.table_container.hasVerticalScroller = NO;
    self.table_container.hasHorizontalScroller = NO;
    [_files_table setAction:@selector(fileTableClicked:)];
  }
  if (transaction.message.length > 0)
  {
    self.message_icon.hidden = NO;
    self.message.hidden = NO;
    self.message.stringValue = transaction.message;
    self.bubble_height.constant = 44.0 + [InfinitConversationCellView heightOfMessage:transaction.message];
    self.message_height.constant = [InfinitConversationCellView heightOfMessage:transaction.message];
  }
  else
  {
    self.message_icon.hidden = YES;
    self.message.hidden = YES;
    self.message_height.constant = 0.0;
  }
  NSImage* avatar_image = transaction.sender.avatar;
  [self updateAvatarWithImage:avatar_image];
  if (_element.showing_files)
      [self showFiles];
  [self onTransactionModeChangeIsNew:NO];
}

//- File Table Handling ----------------------------------------------------------------------------

- (BOOL)selectionShouldChangeInTableView:(NSTableView*)tableView
{
  return NO;
}

- (CGFloat)tableView:(NSTableView*)table_view
         heightOfRow:(NSInteger)row
{
  return 35.0;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView*)tableView
{
  return _element.transaction.files.count;
}

- (NSView*)tableView:(NSTableView*)tableView
  viewForTableColumn:(NSTableColumn*)tableColumn
                 row:(NSInteger)row
{
  NSRect rect = NSMakeRect(0.0, 0.0,
                           NSWidth(self.table_container.frame),
                           35.0);
  InfinitConversationFileCellView* cell;
  cell = [[InfinitConversationFileCellView alloc] initWithFrame:rect onLeft:_element.on_left];
  if (_element.transaction.to_device && _element.transaction.status == gap_transaction_finished)
    cell.clickable = YES;
  else
    cell.clickable = NO;
  [cell setFileName:_element.transaction.files[row]];
  return cell;
}

- (NSTableRowView*)tableView:(NSTableView*)tableView
               rowViewForRow:(NSInteger)row
{
  NSTableRowView* row_view = [tableView rowViewAtRow:row makeIfNecessary:YES];
  if (row_view == nil)
    row_view = [[NSTableRowView alloc] initWithFrame:NSZeroRect];
  return row_view;
}

- (void)fileTableClicked:(NSTableView*)sender
{
  if (_files_table == sender)
  {
    if (_element.transaction.to_device && _element.transaction.files.count > 1 &&
        _element.transaction.status == gap_transaction_finished)
    {
      InfinitConversationFileCellView* cell = [_files_table viewAtColumn:0
                                                                     row:_files_table.clickedRow
                                                         makeIfNecessary:NO];
      [self showFileInFinder:cell.file_name.stringValue];
    }
  }
}

//- Update Progress --------------------------------------------------------------------------------

- (NSString*)dataTransferredForTransaction:(InfinitPeerTransaction*)transaction
{
  NSNumber* transferred = [NSNumber numberWithDouble:(transaction.size.doubleValue * transaction.progress)];
  return [NSString stringWithFormat:@"%@/%@", [InfinitDataSize fileSizeStringFrom:transferred],
                                              [InfinitDataSize fileSizeStringFrom:transaction.size]];
}

- (void)updateProgress
{
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
   {
     context.duration = 1.5;
     [self.progress.animator setDoubleValue:_element.transaction.progress];
     [self.time_indicator.animator setStringValue:[InfinitTime timeRemainingFrom:_element.transaction.time_remaining]];
     [self.information.animator setStringValue:[self dataTransferredForTransaction:_element.transaction]];
   }
                      completionHandler:^
   {
     if (_element.transaction.progress == 1.0)
       [self onTransactionModeChangeIsNew:NO];
   }];
}

//- Bubble View Protocol ---------------------------------------------------------------------------

- (BOOL)pathExists:(NSString*)path
{
  if ([[NSFileManager defaultManager] fileExistsAtPath:path])
    return YES;
  return NO;
}

- (void)showFileInFinder:(NSString*)filename
{
  NSString* download_dir = [[InfinitDownloadDestinationManager sharedInstance] download_destination];
  NSMutableArray* file_urls = [NSMutableArray array];
  NSString* file_path = [download_dir stringByAppendingPathComponent:filename];
  if ([self pathExists:file_path])
  {
    [file_urls addObject:[[NSURL fileURLWithPath:file_path] absoluteURL]];
  }
  if (file_urls.count > 0)
  {
    [_delegate conversationCellBubbleViewGotClicked:self];
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:file_urls];
  }
}

- (void)bubbleViewGotClick:(InfinitConversationBubbleView*)sender
{
  if (_element.transaction.to_device &&
      _element.transaction.status == gap_transaction_finished &&
      _element.transaction.files.count == 1)
  {
    [self showFileInFinder:_element.transaction.files[0]];
  }
  else if (_element.transaction.files.count > 1 && _showing_files) // Multiple files
  {
    [_delegate conversationCellViewWantsHideFiles:self];
  }
  else if (_element.transaction.files.count > 1)
  {
    [_delegate conversationCellViewWantsShowFiles:self];
  }
  else
  {
    return;
  }
  _showing_files = !_showing_files;
}

- (void)bubbleViewGotHover:(InfinitConversationBubbleView*)sender
{
  InfinitPeerTransaction* transaction = _element.transaction;
  if (transaction.files.count == 1 &&
      transaction.to_device && transaction.status == gap_transaction_finished)
  {
    NSAttributedString* hover_string =
      [[NSAttributedString alloc] initWithString:self.file_name.stringValue
                                      attributes:_file_name_hover_attrs];
    self.file_name.attributedStringValue = hover_string;
  }
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
   {
     context.duration = 0.10;
     [self.file_list_icon.animator setAlphaValue:1.0];
   }
                      completionHandler:^
   {
     self.file_list_icon.alphaValue = 1.0;
   }];
}

- (void)bubbleViewGotUnHover:(InfinitConversationBubbleView*)sender
{
  InfinitPeerTransaction* transaction = _element.transaction;
  if (transaction.files.count == 1 &&
      transaction.to_device && transaction.status == gap_transaction_finished)
  {
    NSAttributedString* unhover_string =
    [[NSAttributedString alloc] initWithString:self.file_name.stringValue
                                    attributes:_file_name_attrs];
    self.file_name.attributedStringValue = unhover_string;
  }
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
   {
     context.duration = 0.10;
     [self.file_list_icon.animator setAlphaValue:0.0];
   }
                      completionHandler:^
   {
     self.file_list_icon.alphaValue = 0.0;
   }];
}


@end
