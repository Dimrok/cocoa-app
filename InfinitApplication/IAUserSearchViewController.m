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

@implementation IASearchBoxView

- (BOOL)isOpaque
{
    return NO;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // White background
    NSBezierPath* white_bg = [IAFunctions roundedTopBezierWithRect:self.bounds cornerRadius:6.0];
    [IA_GREY_COLOUR(255.0) set];
    [white_bg fill];
    if (_no_results)
    {
        NSBezierPath* line = [NSBezierPath bezierPathWithRect:NSMakeRect(0.0, 0.0,
                                                                         NSWidth(self.bounds), 1.0)];
        [IA_GREY_COLOUR(235.0) set];
        [line fill];
    }
}

- (void)setNoResults:(BOOL)no_results
{
    _no_results = no_results;
    [self setNeedsDisplay:YES];
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

- (BOOL)isOpaque
{
    return NO;
}

- (BOOL)isFlipped
{
    return NO;
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
                                  NSHeight(self.bounds) - 1.0,
                                  NSWidth(self.bounds),
                                  1.0);
    NSBezierPath* dark_line = [NSBezierPath bezierPathWithRect:dark_rect];
    [IA_GREY_COLOUR(235.0) set];
    [dark_line fill];
    
    if (self.selected)
    {
        // Background
        NSRect bg_rect = NSMakeRect(self.bounds.origin.x,
                                    self.bounds.origin.y,
                                    NSWidth(self.bounds),
                                    NSHeight(self.bounds) - 1.0);
        NSBezierPath* bg_path = [NSBezierPath bezierPathWithRect:bg_rect];
        [IA_RGBA_COLOUR(242.0, 253.0, 255.0, 0.75) set];
        [bg_path fill];
    }
    else
    {
        // Background
        NSRect bg_rect = NSMakeRect(self.bounds.origin.x,
                                    self.bounds.origin.y,
                                    NSWidth(self.bounds),
                                    NSHeight(self.bounds) - 1.0);
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
    NSAttributedString* _add_file_str;
    NSAttributedString* _invite_msg_str;
    NSAttributedString* _no_result_msg_str;
    
    CGFloat _row_height;
    NSInteger _max_rows_shown;
    
    NSImage* _static_image;
    NSImage* _loading_iamge;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)init
{
    if (self = [super initWithNibName:self.className bundle:nil])
    {
        _row_height = 42.0;
        _max_rows_shown = 3;
        _delegate = nil;
        _token_count = 0;
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(avatarCallback:)
                                                   name:IA_AVATAR_MANAGER_AVATAR_FETCHED
                                                 object:nil];
        NSMutableParagraphStyle* para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        para.alignment = NSCenterTextAlignment;

        NSFont* no_result_msg_font = [[NSFontManager sharedFontManager]
                                      fontWithFamily:@"Helvetica"
                                              traits:NSUnboldFontMask
                                              weight:5
                                                size:12.0];
        NSDictionary* no_result_msg_style = [IAFunctions textStyleWithFont:no_result_msg_font
                                                            paragraphStyle:para
                                                                    colour:IA_GREY_COLOUR(32.0)
                                                                    shadow:nil];
        _no_result_msg_str = [[NSAttributedString alloc] initWithString:
                              NSLocalizedString(@"No results. Send to an email instead!",
                                                @"no results. send to an email instead!")
                                                         attributes:no_result_msg_style];
        _invite_msg_str = [[NSAttributedString alloc] initWithString:
                           NSLocalizedString(@"Click send to invite your friend!",
                                             @"Click send to invite your friend!")
                                                        attributes:no_result_msg_style];
        _add_file_str = [[NSAttributedString alloc] initWithString:
                         NSLocalizedString(@"Add a file to invite your friend.",
                                           @"add a file to invite your friend.")
                                                        attributes:no_result_msg_style];
        _static_image = [IAFunctions imageNamed:@"icon-search"];
        _loading_iamge = [IAFunctions imageNamed:@"loading"];
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
    [self.table_view.enclosingScrollView.verticalScroller setControlSize:NSSmallControlSize];

    self.no_results_message.attributedStringValue = _no_result_msg_str;
}

- (void)loadView
{
    [super loadView];
    [self setNoResultsHidden:YES];
    self.search_field.tokenizingCharacterSet = [NSCharacterSet newlineCharacterSet];
    [self initialiseSendButton];
    [self.view setFrameSize:NSMakeSize(NSWidth(self.view.frame),
                                       NSHeight(self.search_box_view.frame) + [self tableHeight])];
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

- (void)checkInputs
{
    if ([_delegate searchViewWantsIfGotFile:self])
    {
        if ([self.no_results_message.stringValue isEqualToString:_add_file_str.string])
            self.no_results_message.attributedStringValue = _invite_msg_str;
    }
    else
    {
        if ([self.no_results_message.stringValue isEqualToString:_invite_msg_str.string])
            self.no_results_message.attributedStringValue = _add_file_str;
    }
}

- (void)setNoResultsHidden:(BOOL)hidden
{
    [self.no_results_message setHidden:hidden];
}

- (void)initialiseSendButton
{
    NSMutableParagraphStyle* style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    style.alignment = NSCenterTextAlignment;
    NSShadow* shadow = [IAFunctions shadowWithOffset:NSMakeSize(0.0, -1.0)
                                          blurRadius:1.0
                                              colour:[NSColor blackColor]];
    
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
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
     {
         context.duration = 0.15;
         [self.send_button.animator setAlphaValue:0.0];
     }
                        completionHandler:^
     {
         CGFloat button_width = NSWidth(self.send_button.frame) - 15.0;
         [self.send_button removeFromSuperview];
         [self.search_field_width setConstant:(self.search_field_width.constant + button_width)];
     }];
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
        self.search_image.image = _loading_iamge;
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
    NSString* search_string;
    NSArray* tokens = self.search_field.objectValue;
    if ([tokens.lastObject isKindOfClass:NSString.class])
        search_string = [self trimTrailingWhitespace:tokens.lastObject];
    else
        search_string = @"";
    
    if (search_string.length == 0)
    {
        [self clearResults];
        return;
    }
    
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
        self.search_image.image = _static_image;
    }
    if ([_delegate searchViewWantsIfGotFile:self])
        self.no_results_message.attributedStringValue = _invite_msg_str;
    else
        self.no_results_message.attributedStringValue = _add_file_str;
    [self updateResultsTable];
}

- (void)searchResultsCallback:(IAGapOperationResult*)results
{
    NSString* search_string;
    NSArray* tokens = self.search_field.objectValue;
    if ([tokens.lastObject isKindOfClass:NSString.class])
        search_string = [self trimTrailingWhitespace:tokens.lastObject];
    else
        search_string = @"";
    
    if (search_string.length == 0)
    {
        [self clearResults];
        return;
    }
    
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
    self.search_image.image = _static_image;
    self.no_results_message.attributedStringValue = _no_result_msg_str;
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
        if (_search_results.count > 0)
        {
            NSInteger row = self.table_view.selectedRow;
            if (row > -1 && row < _search_results.count)
            {
                [self addUser:[_search_results objectAtIndex:row]];
                [self clearResults];
            }
        }
        else
        {
            [_delegate searchViewWantsLoseFocus:self];
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
    [self setNoResultsHidden:YES];
    _search_results = nil;
    self.search_image.animates = NO;
    self.search_image.image = _static_image;
    [self.search_box_view setNoResults:NO];
    [_delegate searchView:self
          changedToHeight:NSHeight(self.search_box_view.frame)];
}

- (void)updateResultsTable
{
    CGFloat new_height;
    if (_search_results.count == 0) // No results so show message
    {
        [self.table_view reloadData];
        [self setNoResultsHidden:NO];
        new_height = NSHeight(self.search_box_view.frame) + NSHeight(self.no_results_message.frame)
            + 20.0;
        [self.search_box_view setNoResults:YES];
    }
    else
    {
        [self.table_view reloadData];
        [self setNoResultsHidden:YES];
        new_height = NSHeight(self.search_box_view.frame) + [self tableHeight];
        [self.search_box_view setNoResults:NO];
    }
    [_delegate searchView:self
          changedToHeight:new_height];
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
    [self.table_view scrollRowToVisible:current_pos];
    [self.table_view selectRowIndexes:[NSIndexSet indexSetWithIndex:current_pos]
                 byExtendingSelection:NO];
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
