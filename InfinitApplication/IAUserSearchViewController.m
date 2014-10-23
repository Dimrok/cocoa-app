//
//  IASearchResultsViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/4/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Gap/IAUserManager.h>

#import "IAUserSearchViewController.h"
#import "IAAvatarManager.h"
#import "InfinitTokenAttachmentCell.h"
#import "InfinitFeatureManager.h"

//- Search View Element ----------------------------------------------------------------------------

@implementation InfinitSearchElement

- (id)initWithAvatar:(NSImage*)avatar
               email:(NSString*)email
            fullname:(NSString*)fullname
                user:(IAUser*)user
{
  if (self = [super init])
  {
    _avatar = avatar;
    _email = email;
    _fullname = fullname;
    _user = user;
    _hover = NO;
  }
  return self;
}

- (BOOL)isEqual:(id)object
{
  if ([object isKindOfClass:InfinitSearchElement.class])
  {
    if ([_user isEqual:[object user]])
      return YES;
    else if (_email.length > 0 && [_email isEqualToString:[object email]])
      return YES;
  }
  return NO;
}

- (NSString*)description
{
  return [NSString stringWithFormat:@"<InfinitSearchElement %p> fullname: %@\nuser: %@\nemail: %@",
          self,
          _fullname,
          _user,
          _email];
}

@end

//- Search Box View --------------------------------------------------------------------------------

@implementation IASearchBoxView

- (BOOL)isOpaque
{
  return YES;
}

- (BOOL)isFlipped
{
  return NO;
}

- (void)drawRect:(NSRect)dirtyRect
{
  if (_link_mode)
    [IA_GREY_COLOUR(248) set];
  else
    [IA_GREY_COLOUR(255) set];
  NSRectFill(self.bounds);
  NSRect line = NSMakeRect(0.0, 0.0, NSWidth(self.bounds), 1.0);
  [IA_GREY_COLOUR(229) set];
  NSRectFill(line);
}

- (NSSize)intrinsicContentSize
{
  return self.frame.size;
}

- (void)setLink_mode:(BOOL)link_mode
{
  _link_mode = link_mode;
  [self setNeedsDisplay:YES];
}

@end

//- Search View Controller -------------------------------------------------------------------------

@implementation IAUserSearchViewController
{
  // WORKAROUND: 10.7 doesn't allow weak references to certain classes (like NSViewController)
  __unsafe_unretained id<IAUserSearchViewProtocol> _delegate;
  
  NSMutableArray* _search_results;
  NSUInteger _token_count;
  
  BOOL _no_results;
  
  CGFloat _row_height;
  NSInteger _max_rows_shown;
  
  InfinitSearchController* _search_controller;
  NSString* _last_search;
  NSInteger _hover_row;
  BOOL _allow_search_infinit;
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
    _allow_search_infinit = YES;
//    if ([[[[InfinitFeatureManager sharedInstance] features] objectForKey:@"search_on_infinit"] isEqualToString:@"1"])
//      _allow_search_infinit = YES;
//    else
//      _allow_search_infinit = NO;
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(avatarCallback:)
                                               name:IA_AVATAR_MANAGER_AVATAR_FETCHED
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

- (void)addUser:(IAUser*)user
{
  if (user == nil)
    return;
  NSMutableArray* temp = [NSMutableArray arrayWithArray:self.search_field.objectValue];
  if ([temp.lastObject isKindOfClass:NSString.class])
    [temp removeObject:temp.lastObject];

  InfinitSearchElement* element;
  for (InfinitSearchElement* other in _search_results)
  {
    if ([other.user isEqual:user])
    {
      element = other;
      break;
    }
  }
  element.selected = YES;
  [temp addObject:element];
  [self.search_field setObjectValue:temp];
  [_delegate searchViewInputsChanged:self];
  _token_count = [self.search_field.objectValue count];
  // WORKAROUND: Don't want token highlighted on drag and drop.
  [self performSelector:@selector(cursorAtEndOfSearchBox) withObject:nil afterDelay:0.2];
}

- (void)removeUser:(IAUser*)user
{
  NSMutableArray* recipients = [NSMutableArray arrayWithArray:self.search_field.objectValue];
  for (InfinitSearchElement* element in recipients)
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

- (void)addElement:(InfinitSearchElement*)element
{
  if (element == nil)
    return;
  if ([self.search_field.objectValue count] > 9)
    return;
  NSMutableArray* temp = [NSMutableArray arrayWithArray:self.search_field.objectValue];
  if ([temp.lastObject isKindOfClass:NSString.class])
    [temp removeObject:temp.lastObject];
  [temp addObject:element];

  NSUInteger row = [_search_results indexOfObject:element];
  if (row != NSNotFound)
  {
    element.selected = YES;
  }
  [self.search_field setObjectValue:temp];

  if (temp.count == 0)
    [self handleInputFieldChange];

  [self fixClipView];
  [_delegate searchViewInputsChanged:self];
  [self clearResults];
}

- (void)removeElement:(InfinitSearchElement*)element
{
  if (element == nil)
    return;
  NSMutableArray* temp = [NSMutableArray arrayWithArray:self.search_field.objectValue];
  NSUInteger row = [_search_results indexOfObject:element];
  if (row != NSNotFound)
  {
    element.selected = NO;
  }
  [temp removeObject:element];
  [self.search_field setObjectValue:temp];
  [self fixClipView];
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
             afterDelay:0.2];
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

- (void)controlTextDidChange:(NSNotification*)aNotification
{
  NSControl* control = aNotification.object;
  if (control != self.search_field)
    return;
  [self handleInputFieldChange];
}

- (void)handleInputFieldChange
{
  [self cancelLastSearchOperation];

  NSString* search_string = [self currentSearchString];

  if ([IAFunctions stringIsValidEmail:search_string] && [_last_search isEqualToString:search_string])
  {
    InfinitSearchElement* element =
      [[InfinitSearchElement alloc] initWithAvatar:[IAFunctions makeAvatarFor:@"@"]
                                             email:search_string
                                          fullname:search_string
                                              user:nil];
    [self addElement:element];
    _last_search = @"";
    return;
  }

  if (search_string.length > 0)
  {
    if (search_string.length < _last_search.length || _last_search.length == 0)
      [self clearResults];
    if ([IAFunctions stringIsValidEmail:search_string])
    {
      [self clearResults];
      [_delegate searchView:self changedToHeight:NSHeight(self.search_box_view.frame)];
      [_delegate searchViewInputsChanged:self];
    }
    else
    {
      [self doDelayedSearch:search_string];
    }
  }
  else
  {
    [self clearResults];
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
    if ([obj isKindOfClass:InfinitSearchElement.class])
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
    if (row > -1 && row < _search_results.count)
    {
      InfinitSearchElement* element = _search_results[row];
      if (![self.search_field.objectValue containsObject:element])
        [self addElement:element];
      // WORKAROUND: can only move the cursor once the token is in place so put a delay of 0.
      [self performSelector:@selector(cursorAtEndOfSearchBox) withObject:nil afterDelay:0];
    }
    else if (_search_results.count == 0)
    {
      NSString* search_string = [self currentSearchString];
      if ([IAFunctions stringIsValidEmail:search_string])
      {
        InfinitSearchElement* element =
          [[InfinitSearchElement alloc] initWithAvatar:[IAFunctions makeAvatarFor:@"@"]
                                                 email:search_string
                                              fullname:search_string
                                                  user:nil];
        [self addElement:element];
        // WORKAROUND: can only move the cursor once the token is in place so put a delay of 0.
        [self performSelector:@selector(cursorAtEndOfSearchBox) withObject:nil afterDelay:0];
      }
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
      InfinitSearchElement* element = _search_results[row];
      if (![self.search_field.objectValue containsObject:element])
        [self addElement:element];
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
      [self clearResults];
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
    if (![object isKindOfClass:[InfinitSearchElement class]] &&
        !([object isKindOfClass:[NSString class]] && [IAFunctions stringIsValidEmail:object]))
    {
      [allowed_tokens removeObject:object];
    }
  }
  return allowed_tokens.allObjects;
}

- (NSString*)tokenField:(NSTokenField*)tokenField
displayStringForRepresentedObject:(id)representedObject
{
  if ([representedObject isKindOfClass:InfinitSearchElement.class])
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
  if ([representedObject isKindOfClass:NSString.class] && ![IAFunctions stringIsValidEmail:representedObject])
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
  if (self.currentSearchString.length == 0)
    [_delegate searchView:self changedToHeight:NSHeight(self.search_box_view.frame)];

  // WORKAROUND: Centre placeholder text when field is empty.
  if ([self.search_field.objectValue count] == 0)
    [self.view.window makeFirstResponder:self.search_field];
}

- (void)updateResultsTable
{
  if (_search_results.count == 0 && self.currentSearchString.length > 0) // No results so show message
  {
    _no_results = YES;
    [self.table_view reloadData];
    [_delegate searchView:self changedToHeight:self.height];
    return;
  }
  _hover_row = 0;
  if (_search_results.count > 0)
  {
    for (InfinitSearchElement* other in _search_results)
      other.hover = NO;
    InfinitSearchElement* element = _search_results[0];
    element.hover = YES;
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
  if (_search_results.count == 0 && _no_results)
  {
    if (_search_controller.include_infinit_results)
      return 108.0;
    else
      return 153.0;
  }
  CGFloat total_height = _search_results.count * _row_height;
  CGFloat max_height = _row_height * _max_rows_shown;
  if (total_height > max_height)
    return max_height;
  else
    return total_height;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView*)tableView
{
  if (_search_results.count == 0 && _no_results)
    return 1;
  else
    return _search_results.count;
}

- (CGFloat)tableView:(NSTableView*)tableView
         heightOfRow:(NSInteger)row
{
  if (_search_results.count == 0 && _no_results)
  {
    if (_search_controller.include_infinit_results)
      return 108.0;
    else
      return 153.0;
  }
  return _row_height;
}

- (NSView*)tableView:(NSTableView*)tableView
  viewForTableColumn:(NSTableColumn*)tableColumn
                 row:(NSInteger)row
{
  if (_search_results.count == 0 && _no_results)
  {
    InfinitSearchNoResultsCellView* cell;
    if (_search_controller.include_infinit_results || !_allow_search_infinit)
    {
      cell = [tableView makeViewWithIdentifier:@"infinit_no_results_b" owner:self];
    }
    else
    {
      cell = [tableView makeViewWithIdentifier:@"infinit_no_results_a" owner:self];
      cell.search_string = [self currentSearchString];
    }

    cell.delegate = self;
    return cell;
  }
  else
  {
    InfinitSearchElement* element = _search_results[row];
    if (element == nil)
      return nil;
    
    IASearchResultsCellView* cell = [tableView makeViewWithIdentifier:@"infinit_search_cell"
                                                                owner:self];
    [cell setDelegate:self];

    if (element.user != nil)
      [cell setUserFullname:element.fullname withEmail:@""];
    else
      [cell setUserFullname:element.fullname withEmail:element.email];
    
    NSImage* avatar = [IAFunctions makeRoundAvatar:element.avatar
                                        ofDiameter:24.0
                             withBorderOfThickness:0.0
                                          inColour:IA_GREY_COLOUR(255.0)
                                 andShadowOfRadius:0.0];
    [cell setUserAvatar:avatar];
    cell.hover = element.hover;
    return cell;
  }
}

//- User Interactions With Table -------------------------------------------------------------------

- (void)setHover:(BOOL)hover
          forRow:(NSInteger)row
{
  if (_search_results.count == 0)
    return;
  InfinitSearchElement* element = _search_results[row];
  element.hover = hover;
  IASearchResultsCellView* cell = [self.table_view viewAtColumn:0 row:row makeIfNecessary:NO];
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
  if (_search_results.count == 0)
    return;
  InfinitSearchElement* element = _search_results[row];
  if (![self.search_field.objectValue containsObject:element])
    [self addElement:element];

  [self.view.window makeFirstResponder:self.search_field];
  [self cursorAtEndOfSearchBox];
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
    InfinitSearchElement* element =
      [[InfinitSearchElement alloc] initWithAvatar:person.avatar
                                             email:nil
                                          fullname:person.fullname
                                              user:person.infinit_user];
    _search_results = [NSMutableArray arrayWithObject:element];
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
  
  if (search_string.length == 0)
  {
    [_search_controller clearResults];
    return;
  }
  
  _search_results = [NSMutableArray array];
  
  for (InfinitSearchPersonResult* person in _search_controller.result_list)
  {
    if (person.infinit_user != nil)
    {
      InfinitSearchElement* element =
        [[InfinitSearchElement alloc] initWithAvatar:person.avatar
                                               email:nil
                                            fullname:person.fullname
                                                user:person.infinit_user];
      [_search_results addObject:element];
    }
    else // Address book user
    {
      for (NSString* email in person.emails)
      {
        InfinitSearchElement* element =
          [[InfinitSearchElement alloc] initWithAvatar:person.avatar
                                                 email:email
                                              fullname:person.fullname
                                                  user:nil];
        [_search_results addObject:element];
      }
    }
  }
  [self updateResultsTable];
}

- (void)searchController:(InfinitSearchController*)sender
      gotUpdateForPerson:(InfinitSearchPersonResult*)person
{
  NSInteger index = 0;
  for (InfinitSearchElement* element in _search_results)
  {
    if (element.user == person.infinit_user)
    {
      element.avatar = person.avatar;
      break;
    }
    index++;
  }
  [self.table_view reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:index]
                             columnIndexes:[NSIndexSet indexSetWithIndex:0]];
}

//- Search Result Cell Protocol --------------------------------------------------------------------

- (void)searchResultCell:(IASearchResultsCellView*)sender
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
      InfinitSearchElement* element = _search_results[row];
      if (element.hover)
      {
        [self setHover:NO forRow:row];
        return;
      }
    }
    _hover_row = [self.table_view rowForView:sender];
    [self setHover:YES forRow:_hover_row];
  }
}

- (void)searchResultCellGotSelected:(IASearchResultsCellView*)sender
{
  [self actionForRow:[self.table_view rowForView:sender]];
}

//- Pretty Tokens for Gaetan -----------------------------------------------------------------------

- (NSTextAttachmentCell*)tokenField:(OEXTokenField*)tokenField
 attachmentCellForRepresentedObject:(id)representedObject
{
  NSImage* avatar;
  NSString* name;
  if ([representedObject isKindOfClass:InfinitSearchElement.class])
  {
    avatar = [representedObject avatar];
    name = [representedObject fullname];
  }
  else
  {
    if ([IAFunctions stringIsValidEmail:representedObject])
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
  IAUser* user = [notification.userInfo objectForKey:@"user"];
  NSInteger row = 0;
  for (InfinitSearchElement* element in _search_results)
  {
    if ([element.user isEqual:user])
    {
      NSImage* image = [notification.userInfo objectForKey:@"avatar"];
      if (row < self.table_view.numberOfRows)
      {
        IASearchResultsCellView* cell =
          [self.table_view viewAtColumn:0 row:row makeIfNecessary:NO];
        if (image == nil || cell == nil)
          return;
        element.avatar = image;
        [cell setUserAvatar:[IAFunctions makeRoundAvatar:image
                                              ofDiameter:24.0
                                   withBorderOfThickness:0.0
                                                inColour:IA_GREY_COLOUR(255.0)
                                       andShadowOfRadius:0.0]];
        return;
      }
    }
    row++;
  }
}

//- No Results Cell Protocol -----------------------------------------------------------------------

- (void)cellWantsSearchInfinit:(InfinitSearchNoResultsCellView*)sender
{
  _search_controller.include_infinit_results = YES;
}

@end
