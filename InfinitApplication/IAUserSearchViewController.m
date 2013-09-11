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

@interface IAUserSearchViewController ()
@end

//- Search Box View --------------------------------------------------------------------------------

@interface IASearchBoxView : NSView
@end

@implementation IASearchBoxView

- (void)drawRect:(NSRect)dirtyRect
{
    // White background
    NSBezierPath* white_bg = [IAFunctions roundedTopBezierWithRect:self.bounds cornerRadius:6.0];
    [IA_GREY_COLOUR(255.0) set];
    [white_bg fill];
}

- (NSSize)intrinsicContentSize
{
    return self.bounds.size;
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
        _tracking_area = [[NSTrackingArea alloc] initWithRect:NSZeroRect
                                                      options:(NSTrackingInVisibleRect |
                                                               NSTrackingActiveAlways |
                                                               NSTrackingMouseEnteredAndExited)
                                                        owner:self
                                                     userInfo:nil];
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

- (void)mouseEntered:(NSEvent*)theEvent
{
    // xxx Should find a cleaner way to do this
    id superview = [self superview];
    if (superview != nil && [superview isKindOfClass:[NSTableView class]])
    {
        if (self.window == [[NSApplication sharedApplication] keyWindow])
        {
            NSInteger row = [(NSTableView*)[self superview] rowForView:self];
            [(NSTableView*)[self superview] beginUpdates];
            [(NSTableView*)[self superview] selectRowIndexes:[NSIndexSet indexSetWithIndex:row]
                                        byExtendingSelection:NO];
            [(NSTableView*)[self superview] endUpdates];
        }
    }
}

- (void)mouseExited:(NSEvent*)theEvent
{
    // xxx Should find a cleaner way to do this
    id superview = [self superview];
    if (superview != nil && [superview isKindOfClass:[NSTableView class]])
    {
        if (self.window == [[NSApplication sharedApplication] keyWindow])
        {
            NSInteger row = [(NSTableView*)[self superview] rowForView:self];
            [(NSTableView*)[self superview] beginUpdates];
            [(NSTableView*)[self superview] deselectRow:row];
            [(NSTableView*)[self superview] endUpdates];
        }
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
                                  self.bounds.origin.y + 1.0,
                                  self.bounds.size.width,
                                  1.0);
    NSBezierPath* dark_line = [NSBezierPath bezierPathWithRect:dark_rect];
    [IA_GREY_COLOUR(235.0) set];
    [dark_line fill];
    
    // White line
    NSRect white_rect = NSMakeRect(self.bounds.origin.x,
                                   self.bounds.origin.y + 2.0,
                                   self.bounds.size.width,
                                   1.0);
    NSBezierPath* white_line = [NSBezierPath bezierPathWithRect:white_rect];
    [IA_GREY_COLOUR(255.0) set];
    [white_line fill];
    
    if (self.selected)
    {
        // Background
        NSRect bg_rect = NSMakeRect(self.bounds.origin.x,
                                    self.bounds.origin.y + 2.0,
                                    self.bounds.size.width,
                                    self.bounds.size.height - 2.0);
        NSBezierPath* bg_path = [NSBezierPath bezierPathWithRect:bg_rect];
        [IA_RGBA_COLOUR(242.0, 253.0, 255.0, 0.75) set];
        [bg_path fill];
    }
    else
    {
        // Background
        NSRect bg_rect = NSMakeRect(self.bounds.origin.x,
                                    self.bounds.origin.y + 2.0,
                                    self.bounds.size.width,
                                    self.bounds.size.height - 2.0);
        NSBezierPath* bg_path = [NSBezierPath bezierPathWithRect:bg_rect];
        [IA_GREY_COLOUR(255.0) set];
        [bg_path fill];
    }
}

@end

//- Search View Controller -------------------------------------------------------------------------

@implementation IAUserSearchViewController
{
    id<IAUserSearchViewProtocol> _delegate;
    
    NSMutableArray* _search_results;
    NSUInteger _token_count;
    
    BOOL _no_results;
    NSAttributedString* _no_result_str;
    NSAttributedString* _no_email_str;
    
    CGFloat _row_height;
    NSInteger _max_rows_shown;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)init
{
    if (self = [super initWithNibName:self.className bundle:nil])
    {
        _row_height = 45.0;
        _max_rows_shown = 3;
        _delegate = nil;
        _token_count = 0;
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(avatarCallback:)
                                                   name:IA_AVATAR_MANAGER_AVATAR_FETCHED
                                                 object:nil];
        NSMutableParagraphStyle* para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        para.alignment = NSCenterTextAlignment;
        NSDictionary* no_result_style = [IAFunctions textStyleWithFont:[NSFont systemFontOfSize:12.0]
                                                        paragraphStyle:para
                                                                colour:IA_GREY_COLOUR(32.0)
                                                                shadow:nil];
        _no_result_str = [[NSAttributedString alloc] initWithString:
                          NSLocalizedString(@"User not on Infinit...", @"user not on infinit")
                                                         attributes:no_result_style];
        _no_email_str = [[NSAttributedString alloc] initWithString:
                         NSLocalizedString(@"Invite this person to Infinit...", @"invite this person")
                                                        attributes:no_result_style];
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

- (void)awakeFromNib
{
    // Workaround for 15" Macbook Pro always rendering scroll bars
    // http://www.cocoabuilder.com/archive/cocoa/317591-can-hide-scrollbar-on-nstableview.html
    [self.table_view.enclosingScrollView setScrollerStyle:NSScrollerStyleOverlay];
    self.no_results_message.attributedStringValue = _no_result_str;
}

- (void)loadView
{
    [super loadView];
    [self.no_results_message setHidden:YES];
    self.search_field.tokenizingCharacterSet = [NSCharacterSet newlineCharacterSet];
    [self initialiseSendButton];
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

- (void)initialiseSendButton
{
    NSMutableParagraphStyle* style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    style.alignment = NSCenterTextAlignment;
    NSShadow* shadow = [IAFunctions shadowWithOffset:NSMakeSize(0.0, -1.0)
                                          blurRadius:1.0
                                               color:[NSColor blackColor]];
    
    NSDictionary* button_style = [IAFunctions textStyleWithFont:[NSFont boldSystemFontOfSize:13.0]
                                                 paragraphStyle:style
                                                         colour:[NSColor whiteColor]
                                                         shadow:shadow];
    self.send_button.attributedTitle = [[NSAttributedString alloc]
                                        initWithString:NSLocalizedString(@"SEND", @"send")
                                        attributes:button_style];
}

- (void)addUser:(IAUser*)user
{
    if (user == nil)
        return;
    NSMutableArray* temp = [NSMutableArray arrayWithArray:self.search_field.objectValue];
    if ([temp.lastObject isKindOfClass:NSString.class])
    {
        [temp removeObject:temp.lastObject];
    }
    [temp addObject:user];
    [self.search_field setObjectValue:temp];
    [_delegate searchViewInputsChanged:self];
}

- (void)cursorAtEndOfSearchBox
{
    [self.search_field.currentEditor moveToEndOfLine:nil];
}

- (NSArray*)recipientList
{
    return self.search_field.objectValue;
}

- (void)removeSendButton
{
    CGFloat button_width = self.send_button.frame.size.width - 15.0;
    [self.send_button removeFromSuperview];
    [self.search_field_width setConstant:(self.search_field_width.constant + button_width)];
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
               afterDelay:0.3];
    if (!self.search_image.animates)
    {
        self.search_image.image = [IAFunctions imageNamed:@"loading"];
        self.search_image.animates = YES;
    }
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
    NSNumber* user_id = [data objectForKey:@"user_id"];
    if (user_id.unsignedIntValue != 0)
    {
        IAUser* user = [IAUserManager userWithId:user_id];
        if ([user isEqual:[[IAGapState instance] self_user]])
            _search_results = [NSMutableArray array];
        else
            _search_results = [NSMutableArray arrayWithObject:user];
    }
    else
    {
        _search_results = [NSMutableArray array];
    }
    if (self.search_image.animates)
    {
        self.search_image.animates = NO;
        self.search_image.image = [IAFunctions imageNamed:@"icon-search"];
    }
    self.no_results_message.attributedStringValue = _no_email_str;
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
    _search_results = [NSMutableArray arrayWithArray:[results.data sortedArrayUsingSelector:
                                                      @selector(compare:)]];
    for (IAUser* user in _search_results)
    {
        if ([user isEqual:[[IAGapState instance] self_user]])
        {
            [_search_results removeObject:user];
            break;
        }
    }
    self.search_image.animates = NO;
    self.search_image.image = [IAFunctions imageNamed:@"icon-search"];
    self.no_results_message.attributedStringValue = _no_result_str;
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
    if (control != self.search_field)
        return;
    
    [self cancelLastSearchOperation];
    NSArray* tokens = self.search_field.objectValue;
    
    NSString* search_string;
    if ([tokens.lastObject isKindOfClass:NSString.class])
        search_string = [self trimTrailingWhitespace:tokens.lastObject];
    else
        search_string = @"";
    
    if (search_string.length > 0)
    {
        [self doDelayedSearch:search_string];
        if ([IAFunctions stringIsValidEmail:search_string])
            [_delegate searchViewInputsChanged:self];
    }
    else
    {
        [self clearResults];
    }
    
    if (tokens.count < _token_count || tokens.count == 0)
    {
        [_delegate searchViewInputsChanged:self];
        _token_count = tokens.count;
    }
}

- (BOOL)control:(NSControl*)control
       textView:(NSTextView*)textView
doCommandBySelector:(SEL)commandSelector
{
    if (control != self.search_field)
        return NO;
    
    if (commandSelector == @selector(insertNewline:))
    {
        NSInteger row = self.table_view.selectedRow;
        if (row > -1 && row < _search_results.count)
        {
            [self addUser:[_search_results objectAtIndex:row]];
            [self clearResults];
        }
        
        [_delegate searchViewInputsChanged:self];
        
        NSArray* tokens = self.search_field.objectValue;
        if (tokens.count == _token_count)
        {
            [_delegate searchViewGotEnterPress:self];
            return YES;
        }
        _token_count = tokens.count;
        return NO;
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
        [self clearResults];
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
    // XXX Limit number of people that can be added to 10 for now. Should tell the user.
    if (index > 9)
        return [NSArray array];
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
    return editingString;
}

- (NSString*)tokenField:(NSTokenField*)tokenField
displayStringForRepresentedObject:(id)representedObject
{
    if ([representedObject isKindOfClass:NSString.class] &&
        [IAFunctions stringIsValidEmail:representedObject])
    {
        [self cursorAtEndOfSearchBox];
        return representedObject;
    }
    else if ([representedObject isKindOfClass:IAUser.class])
    {
        [self cursorAtEndOfSearchBox];
        return [(IAUser*)representedObject fullname];
    }
    return nil;
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

//- Table Drawing Functions ------------------------------------------------------------------------

- (void)clearResults
{
    [self.no_results_message setHidden:YES];
    [self.view setFrameSize:self.search_box_view.frame.size];
    [_delegate searchView:self
              changedSize:self.view.frame.size
         withActiveSearch:NO];
    _search_results = nil;
    self.search_image.animates = NO;
    self.search_image.image = [IAFunctions imageNamed:@"icon-search"];
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
    if (user == nil)
        return nil;
    
    IASearchResultsCellView* cell = [tableView makeViewWithIdentifier:@"user_search_cell"
                                                                owner:self];
    [cell setDelegate:self];
    [cell setUserFullname:user.fullname];
    [cell setUserFavourite:user.is_favourite];
    NSImage* avatar = [IAFunctions makeRoundAvatar:[IAAvatarManager getAvatarForUser:user
                                                                     andLoadIfNeeded:YES]
                                        ofDiameter:25
                             withBorderOfThickness:0.0
                                          inColour:IA_GREY_COLOUR(255.0)
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
    
    [self addUser:_search_results[row]];
    
    [self.view.window makeFirstResponder:self.search_field];
    [self cursorAtEndOfSearchBox];
    [_delegate searchViewInputsChanged:self];
    [self clearResults];
}

- (void)moveTableSelectionBy:(NSInteger)displacement
{
    if (_search_results.count == 0)
        return;
    NSInteger row = self.table_view.selectedRow;
    NSInteger current_pos = row + displacement;
    if (current_pos < 0)
        current_pos = _search_results.count - 1;
    else if (current_pos > _search_results.count - 1)
        current_pos = 0;
    [self.table_view selectRowIndexes:[NSIndexSet indexSetWithIndex:current_pos]
                 byExtendingSelection:NO];
    [self.table_view scrollRowToVisible:current_pos];
}

//- Button Handling --------------------------------------------------------------------------------

- (IBAction)sendButtonClicked:(NSButton*)sender
{
    [_delegate searchViewHadSendButtonClick:self];
}

//- Search Result Cell Protocol --------------------------------------------------------------------

- (void)searchResultCellWantsAddFavourite:(IASearchResultsCellView*)sender
{
    NSUInteger row = [self.table_view rowForView:sender];
    IAUser* user = [_search_results objectAtIndex:row];
    [_delegate searchView:self
        wantsAddFavourite:user];
}

- (void)searchResultCellWantsRemoveFavourite:(IASearchResultsCellView*)sender;
{
    NSUInteger row = [self.table_view rowForView:sender];
    IAUser* user = [_search_results objectAtIndex:row];
    [_delegate searchView:self
     wantsRemoveFavourite:user];
}

@end
