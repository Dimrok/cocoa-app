//
//  IASearchResultsViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/4/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAUserSearchViewController.h"

#import "InfinitSearchEmailCell.h"
#import "InfinitSearchRowModel.h"
#import "InfinitTokenAttachmentCell.h"
#import "InfinitMetricsManager.h"

#import <Gap/InfinitUserManager.h>
#import <Gap/NSString+email.h>

//- Search View Controller -------------------------------------------------------------------------

@interface IAUserSearchViewController ()

@property (nonatomic, readonly) NSMutableArray* search_results;

@property (nonatomic, readonly) NSUInteger last_device;
@property (nonatomic, readonly) NSUInteger last_user;

@end

@implementation IAUserSearchViewController
{
  // WORKAROUND: 10.7 doesn't allow weak references to certain classes (like NSViewController)
  __unsafe_unretained id<IAUserSearchViewProtocol> _delegate;

  NSUInteger _token_count;
  
  BOOL _no_results;
  
  CGFloat _row_height;
  NSInteger _max_rows_shown;
  
  InfinitSearchController* _search_controller;
  NSString* _last_search;
  NSInteger _hover_row;
  BOOL _metric_search_used;
  BOOL _search_email;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)init
{
  if (self = [super initWithNibName:self.className bundle:nil])
  {
    _hover_row = 0;
    _row_height = 38.0;
    _max_rows_shown = 4;
    _delegate = nil;
    _token_count = 0;
    _search_controller = [[InfinitSearchController alloc] initWithDelegate:self];
    _last_search = @"";
    _no_results = NO;
    _metric_search_used = NO;
    _search_email = NO;
    _search_results = [NSMutableArray array];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(avatarCallback:)
                                                 name:INFINIT_USER_AVATAR_NOTIFICATION
                                               object:nil];
  }
  
  return self;
}

- (void)setDelegate:(id<IAUserSearchViewProtocol>)delegate
{
  _delegate = delegate;
}

- (void)dealloc
{
  _search_controller = nil;
  self.table_view.delegate = nil;
  self.table_view.dataSource = nil;
  [NSNotificationCenter.defaultCenter removeObserver:self];
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  _search_field.objectValue = @[];
  _search_field.delegate = nil;
  _search_field = nil;
}

- (void)aboutToChangeView
{
  [_search_controller cancelCallbacks];
  [NSNotificationCenter.defaultCenter removeObserver:self];
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)awakeFromNib
{
  // WORKAROUND: Stop 15" Macbook Pro always rendering scroll bars
  // http://www.cocoabuilder.com/archive/cocoa/317591-can-hide-scrollbar-on-nstableview.html
  [self.table_view.enclosingScrollView setScrollerStyle:NSScrollerStyleOverlay];
  [self.table_view.enclosingScrollView.verticalScroller setControlSize:NSSmallControlSize];

  [self.table_view.enclosingScrollView.contentView setPostsBoundsChangedNotifications:YES];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(tableDidScroll:)
                                               name:NSViewBoundsDidChangeNotification
                                             object:self.table_view.enclosingScrollView.contentView];

  self.search_spinner.hidden = YES;
  [self.search_spinner setIndeterminate:YES];
  
  // WORKAROUND: Place holder text has been fixed in 10.9
  if ([IAFunctions osxVersion] >= INFINIT_OS_X_VERSION_10_9)
  {
    NSFont* search_font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica"
                                                                     traits:NSUnboldFontMask
                                                                     weight:3
                                                                       size:12.0];

    NSDictionary* search_attrs =
      [IAFunctions textStyleWithFont:search_font
                      paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                              colour:IA_GREY_COLOUR(164)
                              shadow:nil];
    NSString* placeholder_str = NSLocalizedString(@"Send by email or search your contacts...", nil);
    NSAttributedString* search_placeholder =
      [[NSAttributedString alloc] initWithString:placeholder_str attributes:search_attrs];
    [self.search_field.cell setPlaceholderAttributedString:search_placeholder];
  }
  NSMutableCharacterSet* tokenising_set = [NSMutableCharacterSet newlineCharacterSet];
  self.search_field.tokenizingCharacterSet = tokenising_set;
}

- (void)loadView
{
  [super loadView];
  _no_results = NO;
  [self updateResultsTable];
}

//- General Functions ------------------------------------------------------------------------------

- (void)setLink_mode:(BOOL)link_mode
{
  _link_mode = link_mode;
  [self.search_spinner stopAnimation:nil];
  self.search_spinner.hidden = YES;
  self.search_field.enabled = !_link_mode;
  self.link_icon.hidden = !_link_mode;
  self.link_text.hidden = !_link_mode;
  self.search_box_view.link_mode = _link_mode;
  self.search_field.hidden = _link_mode;
  self.search_label.hidden = _link_mode;
  self.table_view.hidden = _link_mode;
  CGFloat height = NSHeight(self.search_box_view.frame);
  if (!_link_mode)
    height += [self tableHeight];
  [_delegate searchView:self changedToHeight:height];
  if (!_link_mode)
    [self fixClipView];
}

- (void)addUser:(InfinitUser*)user
{
  if (user == nil)
    return;
  NSMutableArray* temp = [NSMutableArray arrayWithArray:self.search_field.objectValue];
  if ([temp.lastObject isKindOfClass:NSString.class])
    [temp removeObject:temp.lastObject];

  InfinitSearchRowModel* model = [InfinitSearchRowModel rowModelWithUser:user];

  for (InfinitSearchRowModel* other in self.search_results)
  {
    if ([other.user isEqual:user])
    {
      model = other;
      break;
    }
  }
  model.selected = YES;
  [temp addObject:model];
  [self.search_field setObjectValue:temp];
  [_delegate searchViewInputsChanged:self];
  _token_count = [self.search_field.objectValue count];
  // WORKAROUND: Don't want token highlighted on drag and drop.
  [self performSelector:@selector(cursorAtEndOfSearchBox) withObject:nil afterDelay:0.2];
}

- (void)removeUser:(InfinitUser*)user
{
  NSMutableArray* recipients = [NSMutableArray arrayWithArray:self.search_field.objectValue];
  for (InfinitSearchRowModel* element in recipients)
  {
    if ([element.user isEqualTo:user])
    {
      [recipients removeObject:element];
      element.selected = NO;
      break;
    }
  }

  self.search_field.objectValue = recipients;
  [_delegate searchViewInputsChanged:self];
}

- (void)fixClipView
{
  // WORKAROUND for clipping of tokens
  if (self.search_field.subviews.count == 0)
    return;
  NSView* clip_view = self.search_field.subviews[0];
  if ([self.search_field.objectValue count] == 0 ||
      [[self.search_field.objectValue objectAtIndex:0] isKindOfClass:NSString.class])
  {
    [self.search_field setFrame:NSMakeRect(35.0, 13.0, 265.0, 18.0)];
    [clip_view setFrame:NSMakeRect(0.0, 0.0, clip_view.frame.size.width, 18.0)];
  }
  else
  {
    [self.search_field setFrame:NSMakeRect(35.0, 9.0, 265.0, 26.0)];
    [clip_view setFrame:NSMakeRect(0.0, 0.0, clip_view.frame.size.width, 26.0)];
  }
}

- (void)addElement:(InfinitSearchRowModel*)model
{
  if (model == nil)
    return;
  if ([self.search_field.objectValue count] > 9)
    return;
  NSMutableArray* temp = [NSMutableArray arrayWithArray:self.search_field.objectValue];
  if ([temp.lastObject isKindOfClass:NSString.class])
    [temp removeObject:temp.lastObject];
  [temp addObject:model];

  NSUInteger row = [self.search_results indexOfObject:model];
  if (row != NSNotFound)
    model.selected = YES;
  [self.search_field setObjectValue:temp];

  if (temp.count == 0)
    [self handleInputFieldChange];

  [self fixClipView];
  [_delegate searchViewInputsChanged:self];
  [self clearResults];
}

- (void)removeElement:(InfinitSearchRowModel*)model
{
  if (model == nil)
    return;
  NSMutableArray* temp = [NSMutableArray arrayWithArray:self.search_field.objectValue];
  NSUInteger row = [self.search_results indexOfObject:model];
  if (row != NSNotFound)
    model.selected = NO;
  [temp removeObject:model];
  [self.search_field setObjectValue:temp];
  [self fixClipView];
  if ([self.search_field.objectValue count] == 0)
    [_search_controller emptyResults];
  else
    [_delegate searchViewInputsChanged:self];
}

- (void)cursorAtEndOfSearchBox
{
  // WORKAROUND: Because NSTokenField doesn't do moveToEndOfLine
  [[self.search_field currentEditor] moveToEndOfLine:nil];
  [self fixClipView];
}

- (NSArray*)recipientList
{
  return self.search_field.objectValue;
}

//- Search Functions -------------------------------------------------------------------------------

- (void)searchLoading:(BOOL)loading
{
  self.search_label.hidden = loading;
  self.search_spinner.hidden = !loading;
  if (loading)
    [self.search_spinner startAnimation:nil];
  else
    [self.search_spinner stopAnimation:nil];
}

- (void)cancelLastSearchOperation
{
  [_search_controller cancelRunningSearches];
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)doDelayedSearch:(NSString*)search_string
{
  [self performSelector:@selector(doSearchNow:)
             withObject:search_string
             afterDelay:0.2f];
  [self searchLoading:YES];
}

- (void)doSearchNow:(NSString*)search_string
{
  [self cancelLastSearchOperation];
  [_search_controller searchWithString:search_string];
}

//- Search Field -----------------------------------------------------------------------------------

- (NSString*)trimLeadingWhitespace:(NSString*)str
{
  NSInteger i = 0;
  while (i < str.length &&
         [[NSCharacterSet whitespaceCharacterSet] characterIsMember:[str characterAtIndex:i]])
  {
    i++;
  }
  return [str substringFromIndex:i];
}

- (NSString*)currentSearchString
{
  NSArray* tokens = self.search_field.objectValue;

  NSString* search_string;
  if ([tokens.lastObject isKindOfClass:NSString.class])
    search_string = [self trimLeadingWhitespace:tokens.lastObject];
  else
    search_string = @"";
  return search_string;
}

- (void)tokenFieldWillBecomeFirstResponder:(OEXTokenField*)tokenField
{
  id object = self.search_field.objectValue;
  if ([object isEqual:@""] || [object isEqual:@[]])
  {
    [_search_controller emptyResults];
  }
}

- (void)controlTextDidChange:(NSNotification*)notification
{
  NSControl* control = notification.object;
  if (control != self.search_field)
    return;
  [self handleInputFieldChange];
}

- (void)handleInputFieldChange
{
  [self cancelLastSearchOperation];

  if (!_metric_search_used)
  {
    _metric_search_used = YES;
    [InfinitMetricsManager sendMetric:INFINIT_METRIC_SEND_INPUT];
  }

  NSString* search_string = [self currentSearchString];

  if (search_string.isEmail && [_last_search isEqualToString:search_string])
  {
    InfinitSearchRowModel* model = [InfinitSearchRowModel rowModelWithEmail:search_string];
    [self addElement:model];
    _last_search = @"";
    return;
  }

  if (search_string.length > 0)
  {
    if (search_string.isEmail)
    {
      _search_email = YES;
      [self searchLoading:NO];
      [self updateResultsTable];
      [_delegate searchViewInputsChanged:self];
    }
    else
    {
      _search_email = NO;
      [self doDelayedSearch:search_string];
    }
  }
  else
  {
    [_search_controller emptyResults];
    [self searchLoading:NO];
    [self updateResultsTable];
    [self fixClipView];
  }

  NSArray* tokens = self.search_field.objectValue;
  if (tokens.count < _token_count || tokens.count == 0)
  {
    [_delegate searchViewInputsChanged:self];
    _token_count = tokens.count;
  }
  _last_search = search_string;
}

- (BOOL)control:(NSControl*)control
       textView:(NSTextView*)textView
doCommandBySelector:(SEL)commandSelector
{
  if (control != self.search_field)
    return NO;

  if (commandSelector == @selector(deleteBackward:))
  {
    NSRange range = self.search_field.currentEditor.selectedRange;
    if (range.location == 0 || range.location > [self.search_field.objectValue count])
      return NO;
    id obj = [self.search_field.objectValue objectAtIndex:(range.location - 1)];
    if ([obj isKindOfClass:InfinitSearchRowModel.class])
    {
      [self removeElement:obj];
      return YES;
    }
    else
    {
      return NO;
    }
  }
  else if (commandSelector == @selector(insertNewline:))
  {
    NSInteger row = _hover_row;
    if (_search_email)
    {
      NSString* search_string = [self currentSearchString];
      if (search_string.isEmail)
      {
        InfinitSearchRowModel* model = [InfinitSearchRowModel rowModelWithEmail:search_string];
        [self addElement:model];
        // WORKAROUND: can only move the cursor once the token is in place so put a delay of 0.
        [self performSelector:@selector(cursorAtEndOfSearchBox) withObject:nil afterDelay:0];
      }
    }
    else if (row > -1 && row < _search_results.count)
    {
      InfinitSearchRowModel* model = _search_results[row];
      if (![self.search_field.objectValue containsObject:model])
        [self addElement:model];
      // WORKAROUND: can only move the cursor once the token is in place so put a delay of 0.
      [self performSelector:@selector(cursorAtEndOfSearchBox) withObject:nil afterDelay:0];
    }
    [_delegate searchViewInputsChanged:self];
    return YES;
  }
  else if (commandSelector == @selector(moveDown:))
  {
    [self moveTableSelectionBy:1];
    return YES;
  }
  else if (commandSelector == @selector(moveUp:))
  {
    [self moveTableSelectionBy:-1];
    return YES;
  }
  else if (commandSelector == @selector(insertTab:) || commandSelector == @selector(insertBacktab:))
  {
    NSInteger row = _hover_row;
    if (row > -1 && row < _search_results.count)
    {
      InfinitSearchRowModel* model = _search_results[row];
      if (![self.search_field.objectValue containsObject:model])
      {
        [self addElement:model];
      }
    }
    [_delegate searchViewWantsLoseFocus:self];
    [_delegate searchView:self changedToHeight:NSHeight(self.search_box_view.frame)];
    [self performSelector:@selector(fixClipView) withObject:nil afterDelay:0];
    return YES;
  }
  else if (commandSelector == @selector(cancelOperation:))
  {
    if ([_delegate searchViewGotEscapePressedShrink:self])
    {
      [_delegate searchView:self changedToHeight:NSHeight(self.search_box_view.frame)];
      [self searchLoading:NO];
      _no_results = NO;
      _search_results = nil;
      [self.search_field resignFirstResponder];
      [self fixClipView];
    }
    return YES;
  }
  return NO;
}

- (BOOL)tokenField:(NSTokenField*)tokenField
hasMenuForRepresentedObject:(id)representedObject
{
  return NO;
}

- (NSArray*)tokenField:(NSTokenField*)tokenField
      shouldAddObjects:(NSArray*)tokens
               atIndex:(NSUInteger)index
{
  // XXX Limit number of people that can be added to 10 for now. Should tell the user.
  if (index > 9)
    return [NSArray array];
  NSMutableSet* allowed_tokens = [NSMutableSet setWithArray:tokens];
  for (id new_token in tokens)
  {
    NSInteger count = 0;
    for (id token in self.search_field.objectValue)
    {
      if ([token isEqualTo:new_token] && ++count > 1)
        break;
    }
    if (count > 1)
      [allowed_tokens removeObject:new_token];
  }
  for (id object in allowed_tokens)
  {
    if (![object isKindOfClass:InfinitSearchRowModel.class] &&
        !([object isKindOfClass:NSString.class] && [object isEmail]))
    {
      [allowed_tokens removeObject:object];
    }
  }
  return allowed_tokens.allObjects;
}

- (NSString*)tokenField:(NSTokenField*)tokenField
displayStringForRepresentedObject:(id)representedObject
{
  if ([representedObject isKindOfClass:InfinitSearchRowModel.class])
  {
    return [representedObject fullname];
  }
  else if ([representedObject isKindOfClass:NSString.class])
  {
    return representedObject;
  }
  else
  {
    return nil;
  }
}

- (NSTokenStyle)tokenField:(NSTokenField*)tokenField
 styleForRepresentedObject:(id)representedObject
{
  if ([representedObject isKindOfClass:NSString.class] && ![representedObject isEmail])
    return NSPlainTextTokenStyle;
  else
    return NSDefaultTokenStyle;
}

- (NSArray*)tokenField:(NSTokenField*)tokenField
    readFromPasteboard:(NSPasteboard*)pboard
{
  NSMutableArray* res = [NSMutableArray array];
  for (id obj in pboard.pasteboardItems)
  {
    if ([obj isKindOfClass:NSString.class])
      [res addObject:obj];
  }
  return res;
}

- (BOOL)tokenField:(NSTokenField*)tokenField
writeRepresentedObjects:(NSArray*)objects
      toPasteboard:(NSPasteboard*)pboard
{
  return NO;
}

//- Table Drawing Functions ------------------------------------------------------------------------

- (void)clearResults
{
  [self searchLoading:NO];
  _no_results = NO;
  _search_results = nil;
  [_delegate searchView:self changedToHeight:NSHeight(self.search_box_view.frame)];

  // WORKAROUND: Centre placeholder text when field is empty.
  if ([self.search_field.objectValue count] == 0)
    [self.view.window makeFirstResponder:self.search_field];
}

- (void)updateResultsTable
{
  if (_search_results.count == 0 && self.currentSearchString.length > 0 && !_search_email) // No results so show message
  {
    _no_results = YES;
    [self.table_view reloadData];
    [_delegate searchView:self changedToHeight:self.height];
    return;
  }
  _hover_row = 0;
  if (_search_results.count > 0)
  {
    for (InfinitSearchRowModel* other in self.search_results)
      other.hover = NO;
    InfinitSearchRowModel* model = self.search_results[0];
    model.hover = YES;
  }
  _no_results = NO;
  [self.table_view reloadData];
  [self.table_view scrollRowToVisible:0];
  [_delegate searchView:self changedToHeight:self.height];
}

- (CGFloat)height
{
  return NSHeight(self.search_box_view.frame) + [self tableHeight];
}

- (void)showResults
{
  [_delegate searchView:self changedToHeight:self.height];
}

- (CGFloat)tableHeight
{
  if (_no_results && !_search_email)
    return 153.0;

  NSUInteger count = _search_email ? 1 : _search_results.count;
  CGFloat total_height = count * _row_height;
  CGFloat max_height = _row_height * _max_rows_shown;
  if (total_height > max_height)
    return max_height;
  else
    return total_height;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView*)tableView
{
  if (_search_email || _no_results)
    return 1;
  else
    return _search_results.count;
}

- (CGFloat)tableView:(NSTableView*)tableView
         heightOfRow:(NSInteger)row
{
  if (_no_results)
    return 153.0;
  return _row_height;
}

- (NSView*)tableView:(NSTableView*)tableView
  viewForTableColumn:(NSTableColumn*)tableColumn
                 row:(NSInteger)row
{
  if (_search_email)
  {
    InfinitSearchEmailCell* cell = [tableView makeViewWithIdentifier:@"infinit_search_email_cell"
                                                               owner:self];
    cell.email = [self currentSearchString];
    return cell;
  }
  else if (_no_results)
  {
    InfinitSearchNoResultsCellView* cell =
      [tableView makeViewWithIdentifier:@"infinit_no_results_search" owner:self];
    return cell;
  }
  else
  {
    InfinitSearchRowModel* model = _search_results[row];
    if (model == nil)
      return nil;
    
    InfinitSearchResultCell* cell = [tableView makeViewWithIdentifier:@"infinit_search_cell"
                                                                owner:self];
    cell.delegate = self;
    cell.model = model;
    cell.hover = model.hover;
    if (row == self.last_device || row == self.last_user)
      cell.line = YES;
    else
      cell.line = NO;
    return cell;
  }
}

//- User Interactions With Table -------------------------------------------------------------------

- (void)setHover:(BOOL)hover
          forRow:(NSInteger)row
{
  if (_search_results.count == 0)
    return;
  InfinitSearchRowModel* model = self.search_results[row];
  model.hover = hover;
  InfinitSearchResultCell* cell = [self.table_view viewAtColumn:0 row:row makeIfNecessary:NO];
  cell.hover = hover;
}

- (void)tableDidScroll:(NSNotification*)notification
{
  if (!CGCursorIsVisible() || _search_results.count == 0)
    return;
  NSPoint mouse_loc = self.table_view.window.mouseLocationOutsideOfEventStream;
  mouse_loc = [self.table_view convertPoint:mouse_loc fromView:nil];
  NSInteger row = [self.table_view rowAtPoint:mouse_loc];
  if (row != -1)
  {
    _hover_row = row;

    [self setHover:YES forRow:row];
    for (NSInteger i = 0; i < _search_results.count; i++)
    {
      if (i != row)
        [self setHover:NO forRow:i];
    }
  }
}

- (BOOL)tableView:(NSTableView*)aTableView
  shouldSelectRow:(NSInteger)row
{
  return NO;
}

- (void)actionForRow:(NSUInteger)row
{
  if (_search_results.count == 0 && !_search_email)
    return;
  InfinitSearchRowModel* model = nil;
  if (_search_email)
    model = [InfinitSearchRowModel rowModelWithEmail:[self currentSearchString]];
  else
    model = self.search_results[row];

  if (model == nil)
    return;
  if (![self.search_field.objectValue containsObject:model])
    [self addElement:model];
  [self.view.window makeFirstResponder:self.search_field];
  [self cursorAtEndOfSearchBox];
  [self clearResults];
}

- (IBAction)tableViewAction:(NSTableView*)sender
{
  NSInteger row = self.table_view.clickedRow;
  if (row < 0 || row > _search_results.count - 1)
    return;
  [self actionForRow:row];
}

- (void)scrollRowToCentre:(NSInteger)row
                withAnimation:(BOOL)animate
{
  NSRect row_rect = [self.table_view rectOfRow:row];
  NSRect view_rect = self.table_view.superview.frame;
  NSPoint scroll_origin = row_rect.origin;
  scroll_origin.y = scroll_origin.y + (row_rect.size.height - view_rect.size.height) / 2;
  if (scroll_origin.y < 0)
    scroll_origin.y = 0;
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context)
   {
     if (animate)
       context.duration = 0.1;
     else
       context.duration = 0.0;
     [[self.table_view.superview animator] setBoundsOrigin:scroll_origin];
   }
                      completionHandler:^
   {
     if (row - 1 > -1)
       [self setHover:NO forRow:(row - 1)];
     else
       [self setHover:NO forRow:(_search_results.count - 1)];
     if (row + 1 < _search_results.count)
       [self setHover:NO forRow:(row + 1)];
     else
       [self setHover:NO forRow:0];
     [self setHover:YES forRow:row];
   }];
}

- (void)moveTableSelectionBy:(NSInteger)displacement
{
  if (_search_results.count == 0)
    return;
  NSInteger row = _hover_row;
  NSInteger new_pos = row + displacement;
  if (new_pos < 0)
    new_pos = _search_results.count - 1;
  else if (new_pos > _search_results.count - 1)
    new_pos = 0;
  _hover_row = new_pos;
  [self scrollRowToCentre:new_pos withAnimation:YES];
}

//- Search Controller Protocol ---------------------------------------------------------------------

- (void)searchControllerGotEmailResult:(InfinitSearchController*)sender
{
  NSString* search_string;
  NSArray* tokens = self.search_field.objectValue;
  if ([tokens.lastObject isKindOfClass:NSString.class])
    search_string = [self trimLeadingWhitespace:tokens.lastObject];
  else
    search_string = @"";
  
  [self searchLoading:NO];
  
  if (search_string.length == 0)
  {
    [_search_controller clearResults];
    return;
  }
  
  _search_results = [NSMutableArray array];
  
  if (!_search_controller.result_list.count == 0)
  {
    InfinitSearchPersonResult* person = _search_controller.result_list[0];
    InfinitSearchRowModel* model = [InfinitSearchRowModel rowModelWithSearchPersonResult:person];
    _search_results = [NSMutableArray arrayWithObject:model];
  }
  [self updateResultsTable];
}

- (void)searchControllerGotResults:(InfinitSearchController*)sender
{
  NSString* search_string;
  NSArray* tokens = self.search_field.objectValue;
  if ([tokens.lastObject isKindOfClass:NSString.class])
    search_string = [self trimLeadingWhitespace:tokens.lastObject];
  else
    search_string = @"";
  
  [self searchLoading:NO];

  if (self.search_results == nil)
    _search_results = [NSMutableArray array];
  else
    [self.search_results removeAllObjects];

  NSUInteger count = 0;
  _last_device = NSNotFound;
  _last_user = NSNotFound;
  for (InfinitSearchPersonResult* person in _search_controller.result_list)
  {
    if (person.device != nil)
      _last_device = count;
    if (person.infinit_user != nil)
    {
      InfinitSearchRowModel* model = [InfinitSearchRowModel rowModelWithSearchPersonResult:person];
      if (![self.recipientList containsObject:model])
      {
        _last_user = count;
        [self.search_results addObject:model];
      }
    }
    else // Address book user
    {
      for (NSInteger i = 0; i < person.emails.count; i++)
      {
        InfinitSearchRowModel* model = [InfinitSearchRowModel rowModelWithSearchPersonResult:person
                                                                                  emailIndex:i];
        if (![self.recipientList containsObject:model])
          [self.search_results addObject:model];
      }
    }
    count++;
  }
  if (self.last_device == 0)
    _last_device = 1;
  [self updateResultsTable];
}

- (void)searchController:(InfinitSearchController*)sender
      gotUpdateForPerson:(InfinitSearchPersonResult*)person
{
  NSInteger index = [self.search_results indexOfObject:person];
  if (index == NSNotFound)
    return;
  [self.table_view reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:index]
                             columnIndexes:[NSIndexSet indexSetWithIndex:0]];
}

//- Search Result Cell Protocol --------------------------------------------------------------------

- (void)searchResultCell:(InfinitSearchResultCell*)sender
                gotHover:(BOOL)hover
{
  NSRange range = [self.table_view rowsInRect:self.table_view.visibleRect];
  if (hover)
  {
    _hover_row = [self.table_view rowForView:sender];
    for (NSUInteger row = range.location; row < range.location + range.length; row++)
    {
      if (row != _hover_row)
        [self setHover:NO forRow:row];
    }
  }
  else
  {
    for (NSUInteger row = range.location; row < range.length; row++)
    {
      InfinitSearchRowModel* model = self.search_results[row];
      if (model.hover)
      {
        [self setHover:NO forRow:row];
        return;
      }
    }
    _hover_row = [self.table_view rowForView:sender];
    [self setHover:YES forRow:_hover_row];
  }
}

- (void)searchResultCellGotSelected:(InfinitSearchResultCell*)sender
{
  [self actionForRow:[self.table_view rowForView:sender]];
}

//- Pretty Tokens for Gaetan -----------------------------------------------------------------------

- (NSTextAttachmentCell*)tokenField:(OEXTokenField*)tokenField
 attachmentCellForRepresentedObject:(id)representedObject
{
  NSImage* avatar;
  NSString* name;
  if ([representedObject isKindOfClass:InfinitSearchRowModel.class])
  {
    avatar = [representedObject avatar];
    name = [representedObject fullname];
  }
  else
  {
    if ([representedObject isKindOfClass:NSString.class] && [representedObject isEmail])
      avatar = [IAFunctions makeAvatarFor:@"@"];
    else
      avatar = [IAFunctions makeAvatarFor:representedObject];
    name = representedObject;
  }
  InfinitTokenAttachmentCell* cell = [InfinitTokenAttachmentCell new];
  cell.stringValue = name;
  cell.avatar = avatar;
  return cell;
}

//- Avatar Callback --------------------------------------------------------------------------------

- (void)avatarCallback:(NSNotification*)notification
{
  NSNumber* id_ = notification.userInfo[kInfinitUserId];
  InfinitUser* user = [[InfinitUserManager sharedInstance] userWithId:id_];
  NSInteger row = 0;
  for (InfinitSearchRowModel* model in self.search_results)
  {
    if ([model.user isEqual:user])
    {
      if (row < self.table_view.numberOfRows)
      {
        [self.table_view reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row]
                                   columnIndexes:[NSIndexSet indexSetWithIndex:0]];
        return;
      }
    }
    row++;
  }
}

@end
