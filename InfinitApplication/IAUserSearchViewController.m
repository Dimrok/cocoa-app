//
//  IASearchResultsViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/4/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAUserSearchViewController.h"

#import "IAAvatarManager.h"
#import "IASearchResultsCellView.h"

@interface IAUserSearchViewController ()
@end

//- Search Box View --------------------------------------------------------------------------------

@interface IASearchBoxView : NSView
@end

@implementation IASearchBoxView

- (void)drawRect:(NSRect)dirtyRect
{
    // White background
    NSBezierPath* white_bg = [NSBezierPath bezierPathWithRect:self.bounds];
    [TH_RGBCOLOR(255.0, 255.0, 255.0) set];
    [white_bg fill];
    
    // Grey Line
    NSRect grey_line_box = NSMakeRect(self.bounds.origin.x,
                                      self.bounds.origin.y + 1.0,
                                      self.bounds.size.width,
                                      1.0);
    NSBezierPath* grey_line = [NSBezierPath bezierPathWithOvalInRect:grey_line_box];
    [TH_RGBCOLOR(246.0, 246.0, 246.0) set];
    [grey_line fill];
}

- (NSSize)intrinsicContentSize
{
    return self.frame.size;
}

@end

//- Search Table Row View --------------------------------------------------------------------------

@interface IASearchResultsTableRowView : NSTableRowView
@end

@implementation IASearchResultsTableRowView
{
@private
    NSTrackingArea* _tracking_area;
}

- (void)dealloc
{
    _tracking_area = nil;
}

- (void)ensureTrackingArea
{
    if (_tracking_area == nil)
    {
        NSDictionary* dict = @{@"row": self};
        _tracking_area = [[NSTrackingArea alloc] initWithRect:NSZeroRect
                                                      options:(NSTrackingInVisibleRect |
                                                               NSTrackingActiveAlways |
                                                               NSTrackingMouseEnteredAndExited)
                                                        owner:[(NSTableView*)self.superview delegate]
                                                     userInfo:dict];
    }
}

- (void)updateTrackingAreas
{
    [super updateTrackingAreas];
    [self ensureTrackingArea];
    if (![[self trackingAreas] containsObject:_tracking_area])
    {
        [self addTrackingArea:_tracking_area];
    }
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Dark line
    NSRect dark_rect = NSMakeRect(self.bounds.origin.x,
                                  self.bounds.origin.y + self.bounds.size.height - 1.0,
                                  self.bounds.size.width,
                                  1.0);
    NSBezierPath* dark_line = [NSBezierPath bezierPathWithRect:dark_rect];
    [TH_RGBCOLOR(209.0, 209.0, 209.0) set];
    [dark_line fill];
    
    // White line
    NSRect white_rect = NSMakeRect(self.bounds.origin.x,
                                   self.bounds.origin.y + self.bounds.size.height - 2.0,
                                   self.bounds.size.width,
                                   1.0);
    NSBezierPath* white_line = [NSBezierPath bezierPathWithRect:white_rect];
    [TH_RGBCOLOR(255.0, 255.0, 255.0) set];
    [white_line fill];
    
    if (self.selected)
    {
        // Background
        NSRect bg_rect = NSMakeRect(self.bounds.origin.x,
                                    self.bounds.origin.y,
                                    self.bounds.size.width,
                                    self.bounds.size.height - 2.0);
        NSBezierPath* bg_path = [NSBezierPath bezierPathWithRect:bg_rect];
        [TH_RGBCOLOR(255.0, 255.0, 255.0) set];
        [bg_path fill];
    }
    else
    {
        // Background
        NSRect bg_rect = NSMakeRect(self.bounds.origin.x,
                                    self.bounds.origin.y,
                                    self.bounds.size.width,
                                    self.bounds.size.height - 2.0);
        NSBezierPath* bg_path = [NSBezierPath bezierPathWithRect:bg_rect];
        [TH_RGBCOLOR(246.0, 246.0, 246.0) set];
        [bg_path fill];
    }
}

@end

//- Search View Controller -------------------------------------------------------------------------

@implementation IAUserSearchViewController
{
    id<IAUserSearchViewProtocol> _delegate;
    
    NSMutableArray* _search_results;
    
    BOOL _no_results;
    
    CGFloat _row_height;
    NSInteger _max_rows_shown;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)init
{
    if (self = [super initWithNibName:self.className bundle:nil])
    {
        _row_height = 45.0;
        _max_rows_shown = 5;
        _delegate = nil;
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
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (NSString*)description
{
    return @"[SearchResultsViewController]";
}

- (void)awakeFromNib
{
    [self.no_results_message setHidden:YES];
    self.search_field.tokenizingCharacterSet = [NSCharacterSet newlineCharacterSet];
}

- (void)loadView
{
    [super loadView];
    [self.view setFrameSize:NSMakeSize(self.view.frame.size.width,
                                       self.search_box_view.frame.size.height + [self tableHeight])];
}

//- Avatar Callback --------------------------------------------------------------------------------

- (void)avatarCallback:(NSNotification*)notification
{
    IAUser* user = [notification.userInfo objectForKey:@"user"];
    if (![_search_results containsObject:user])
        return;
    
    [self.table_view reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:[_search_results
                                                                            indexOfObject:user]]
                               columnIndexes:[NSIndexSet indexSetWithIndex:0]];
}

//- General Functions ------------------------------------------------------------------------------

- (void)addUser:(IAUser*)user
{
    if (user == nil)
        return;
    NSMutableArray* temp = [NSMutableArray arrayWithArray:self.search_field.objectValue];
    [temp addObject:user];
    [self.search_field setObjectValue:temp];
}

- (void)cursorAtEndOfSearchBox
{
    NSText* field_editor = self.search_field.currentEditor;
    [field_editor setSelectedRange:NSMakeRange(field_editor.string.length, 0)];
}

//- Search Functions -------------------------------------------------------------------------------

- (void)cancelLastSearchOperation
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)doDelayedSearch:(NSString*)search_string
{
    [self performSelector:@selector(doSearchNow:)
               withObject:search_string
               afterDelay:0.5];
}

- (void)doSearchNow:(NSString*)search_string
{
    [self cancelLastSearchOperation];
    if ([IAFunctions stringIsValidEmail:search_string]) // Search using using email address
    {
        NSMutableDictionary* data = [NSMutableDictionary dictionaryWithObject:search_string
                                                                       forKey:@"entered_email"];
        [[IAGapState instance] getUserIdfromEmail:search_string
                                  performSelector:@selector(searchUserEmailCallback:)
                                         onObject:self
                                         withData:data];
    }
    else // Normal search
    {
        [[IAGapState instance] searchUsers:search_string
                           performSelector:@selector(searchResultsCallback:)
                                  onObject:self];
    }
}

- (void)searchUserEmailCallback:(IAGapOperationResult*)result
{
    if (!result.success)
    {
        IALog(@"%@ WARNING: Searching for email address failed", self);
        _search_results = nil;
        return;
    }
    
    NSDictionary* data = result.data;
    NSString* user_id = (NSString*)[data objectForKey:@"user_id"];
    if (![user_id isEqualToString:@""])
    {
        IAUser* user = [IAUser userWithId:user_id];
        _search_results = [NSMutableArray arrayWithObject:user];
    }
    else
    {
        _search_results = [NSMutableArray array];
    }
    [self updateResultsTable];
}

- (void)searchResultsCallback:(IAGapOperationResult*)results
{
    if (!results.success)
    {
        IALog(@"%@ WARNING: Searching for users failed with error: %d", self, results.status);
        _search_results = nil;
        return;
    }
    _search_results = [NSMutableArray arrayWithArray:results.data];
    [self updateResultsTable];
}

//- Search Field -----------------------------------------------------------------------------------

- (NSString*)trimTrailingWhitespace:(NSString*)str
{
    NSInteger i = 0;
    while (i < str.length &&
           [[NSCharacterSet whitespaceCharacterSet] characterIsMember:[str characterAtIndex:i]])
    {
        i++;
    }
    return [str substringFromIndex:i];
}

- (void)controlTextDidChange:(NSNotification*)aNotification
{
    NSControl* control = aNotification.object;
    if (control == self.search_field)
    {
        [self cancelLastSearchOperation];
        NSArray* tokens = self.search_field.objectValue;
        NSString* search_string;
        if ([tokens.lastObject isKindOfClass:[NSString class]])
            search_string = [self trimTrailingWhitespace:tokens.lastObject];
        else
            search_string = @"";
        if (search_string.length > 0)
            [self doDelayedSearch:search_string];
        else
            [self clearResults];
    }
}

- (BOOL)control:(NSControl*)control
       textView:(NSTextView*)textView
doCommandBySelector:(SEL)commandSelector
{
    if (control != self.search_field)
        return NO;
    
    if (commandSelector == @selector(moveDown:))
    {
        [self moveTableSelectionBy:1];
        return YES;
    }
    else if (commandSelector == @selector(moveUp:))
    {
        [self moveTableSelectionBy:-1];
        return YES;
    }
    else if (commandSelector == @selector(insertTab:))
    {
        [_delegate searchViewWantsLoseFocus:self];
        return YES;
    }
    return NO;
}

- (BOOL)tokenField:(NSTokenField*)tokenField
hasMenuForRepresentedObject:(id)representedObject
{
    return NO;
}

- (NSTokenStyle)tokenField:(NSTokenField*)tokenField
 styleForRepresentedObject:(id)representedObject
{
    if ([representedObject isKindOfClass:[IAUser class]])
        return NSRoundedTokenStyle;
    if ([representedObject isKindOfClass:[NSString class]] &&
        [IAFunctions stringIsValidEmail:representedObject])
    {
        return NSRoundedTokenStyle;
    }
    
    return NSPlainTextTokenStyle;
}

- (NSArray*)tokenField:(NSTokenField*)tokenField
      shouldAddObjects:(NSArray*)tokens
               atIndex:(NSUInteger)index
{
    NSMutableArray* allowed_tokens = [NSMutableArray arrayWithArray:tokens];
    for (id new_token in allowed_tokens)
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
        if (![object isKindOfClass:[IAUser class]] &&
            !([object isKindOfClass:[NSString class]] && [IAFunctions stringIsValidEmail:object]))
        {
            [allowed_tokens removeObject:object];
        }
    }
    return allowed_tokens;
}

- (NSString*)tokenField:(NSTokenField*)tokenField
editingStringForRepresentedObject:(id)representedObject
{
    return nil;
}

- (id)tokenField:(NSTokenField*)tokenField
representedObjectForEditingString:(NSString*)editingString
{
    NSInteger row = self.table_view.selectedRow;
    if (row > -1 || row < _search_results.count)
        return [_search_results objectAtIndex:row];
    else
        return editingString;
}

- (NSString*)tokenField:(NSTokenField*)tokenField
displayStringForRepresentedObject:(id)representedObject
{
    if ([representedObject isKindOfClass:[NSString class]] &&
        [IAFunctions stringIsValidEmail:representedObject])
    {
        return representedObject;
    }
    else if ([representedObject isKindOfClass:[IAUser class]])
    {
        return [(IAUser*)representedObject fullname];
    }
    return nil;
}

//- Table Drawing Functions ------------------------------------------------------------------------

- (void)clearResults
{
    [self.no_results_message setHidden:YES];
    [self.view setFrameSize:self.search_box_view.frame.size];
    [_delegate searchView:self
              changedSize:self.view.frame.size
         withActiveSearch:NO];
    _search_results = nil;
}

- (void)updateResultsTable
{
    NSSize new_size = NSZeroSize;
    if (_search_results.count == 0) // No results so show message
    {
        [self.no_results_message setHidden:NO];
        new_size = NSMakeSize(self.view.frame.size.width,
                              self.search_box_view.frame.size.height +
                                self.no_results_message.frame.size.height + 10.0);
    }
    else
    {
        [self.no_results_message setHidden:YES];
        new_size = NSMakeSize(self.view.frame.size.width,
                              self.search_box_view.frame.size.height + [self tableHeight]);
    }
    [_delegate searchView:self
              changedSize:new_size
         withActiveSearch:YES];
    [self.table_view reloadData];
}

- (CGFloat)tableHeight
{
    CGFloat total_height = _search_results.count * _row_height;
    CGFloat max_height = _row_height * _max_rows_shown;
    if (total_height > max_height)
        return max_height;
    else
        return total_height;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView*)tableView
{
    return _search_results.count;
}

- (CGFloat)tableView:(NSTableView*)tableView
         heightOfRow:(NSInteger)row
{
    return _row_height;
}

- (NSView*)tableView:(NSTableView*)tableView
  viewForTableColumn:(NSTableColumn*)tableColumn
                 row:(NSInteger)row
{    
    IAUser* user = [_search_results objectAtIndex:row];
    if (user == nil || [user.user_id isEqualToString:@""])
        return nil;
    
    IASearchResultsCellView* cell = [tableView makeViewWithIdentifier:@"user_search_cell"
                                                                owner:self];
    [cell setUserFullname:user.fullname];
    [cell setUserFavourite:NO]; // XXX check if user is favourite
    NSImage* avatar = [IAFunctions makeRoundAvatar:[IAAvatarManager getAvatarForUser:user
                                                                     andLoadIfNeeded:YES]
                                        ofDiameter:25
                             withBorderOfThickness:0.0
                                          inColour:TH_RGBCOLOR(255.0, 255.0, 255.0)
                                 andShadowOfRadius:0.0];
    [cell setUserAvatar:avatar];
    return cell;
}

- (NSTableRowView*)tableView:(NSTableView*)tableView
               rowViewForRow:(NSInteger)row
{
    IASearchResultsTableRowView* row_view = [tableView rowViewAtRow:row makeIfNecessary:YES];
    if (row_view == nil)
        row_view = [[IASearchResultsTableRowView alloc] initWithFrame:NSZeroRect];
    return row_view;
}

//- Mouse Hovering ---------------------------------------------------------------------------------

- (void)mouseEntered:(NSEvent*)theEvent
{
    NSDictionary* dict = theEvent.userData;
    if (![[dict objectForKey:@"row"] isKindOfClass:[IASearchResultsTableRowView class]])
        return;
    IASearchResultsTableRowView* row = [dict objectForKey:@"row"];
    [self.table_view selectRowIndexes:[NSIndexSet indexSetWithIndex:[self.table_view rowForView:row]]
                 byExtendingSelection:NO];
}

- (void)mouseExited:(NSEvent*)theEvent
{
}

- (void)mouseMoved:(NSEvent*)theEvent
{
}

- (void)cursorUpdate:(NSEvent*)event
{
}

//- User Interactions With Table -------------------------------------------------------------------

- (BOOL)tableView:(NSTableView*)aTableView
  shouldSelectRow:(NSInteger)row
{
    return YES;
}

- (IBAction)tableViewAction:(NSTableView*)sender
{
    NSInteger row = self.table_view.clickedRow;
    if (row < 0 || row > _search_results.count - 1)
        return;
    [self mouseSelectedUser];
}

- (void)mouseSelectedUser
{
    [self.view.window makeFirstResponder:self.search_field];
    [self controlTextDidChange:[NSNotification
                                notificationWithName:NSControlTextDidChangeNotification
                                              object:self.search_field]];
    [self cursorAtEndOfSearchBox];
}

- (void)moveTableSelectionBy:(NSInteger)displacement
{
    NSInteger row = self.table_view.selectedRow;
    if (row + displacement < 0 &&
        row + displacement >= _search_results.count - 1)
    {
        return;
    }
    [self.table_view selectRowIndexes:[NSIndexSet indexSetWithIndex:(row + displacement)]
                 byExtendingSelection:NO];
}

@end
