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

//- Search View Element ----------------------------------------------------------------------------

@interface InfinitSearchElement : NSObject

@property (nonatomic, readwrite) NSImage* avatar;
@property (nonatomic, readwrite) NSString* email;
@property (nonatomic, readwrite) NSString* fullname;
@property (nonatomic, readwrite) IAUser* user;

@end

@implementation InfinitSearchElement

@synthesize avatar = _avatar;
@synthesize email = _email;
@synthesize fullname = _fullname;
@synthesize user = _user;

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
    }
    return self;
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
    NSImage* _loading_image;
    
    InfinitSearchController* _search_controller;
    NSString* _last_search;
    
    BOOL _more_clicked;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)init
{
    if (self = [super initWithNibName:self.className bundle:nil])
    {
        _row_height = 55.0;
        _max_rows_shown = 4;
        _delegate = nil;
        _token_count = 0;
        _more_clicked = NO;
        NSMutableParagraphStyle* para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        para.alignment = NSCenterTextAlignment;

        NSFont* no_result_msg_font = [[NSFontManager sharedFontManager]
                                      fontWithFamily:@"Helvetica"
                                              traits:NSUnboldFontMask
                                              weight:5
                                                size:13.0];
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
        _loading_image = [IAFunctions imageNamed:@"loading"];
        
        _search_controller = [[InfinitSearchController alloc] initWithDelegate:self];
        _last_search = @"";
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
    // WORKAROUND: Stop 15" Macbook Pro always rendering scroll bars
    // http://www.cocoabuilder.com/archive/cocoa/317591-can-hide-scrollbar-on-nstableview.html
    [self.table_view.enclosingScrollView setScrollerStyle:NSScrollerStyleOverlay];
    [self.table_view.enclosingScrollView.verticalScroller setControlSize:NSSmallControlSize];
    
    // WORKAROUND: Place holder text has been fixed in 10.9
    if ([IAFunctions osxVersion] == INFINIT_OS_X_VERSION_10_9)
    {
        NSFont* search_font = [[NSFontManager sharedFontManager]fontWithFamily:@"Helvetica"
                                                                        traits:NSUnboldFontMask
                                                                        weight:3
                                                                          size:13.0];
        NSDictionary* search_attrs = [IAFunctions textStyleWithFont:search_font
                                                     paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                                             colour:IA_GREY_COLOUR(32.0)
                                                             shadow:nil];
        NSString* placeholder_str = NSLocalizedString(@"Enter a name or email...",
                                                      @"Enter a name or email...");
        NSAttributedString* search_placeholder = [[NSAttributedString alloc]
                                                  initWithString:placeholder_str
                                                      attributes:search_attrs];
        [self.search_field.cell setPlaceholderAttributedString:search_placeholder];
    }

    self.no_results_message.attributedStringValue = _no_result_msg_str;
}

- (void)loadView
{
    [super loadView];
    [self setNoResultsHidden:YES];
    self.search_field.tokenizingCharacterSet = [NSCharacterSet newlineCharacterSet];
    [self initialisedMoreButton];
    [self.view setFrameSize:NSMakeSize(NSWidth(self.view.frame),
                                       NSHeight(self.search_box_view.frame) + [self tableHeight])];
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
    // WORKAROUND: message rendering behind scroll view on 10.9
    if ([IAFunctions osxVersion] == INFINIT_OS_X_VERSION_10_9)
        [self.table_view.enclosingScrollView setHidden:!hidden];
}

- (void)initialisedMoreButton
{
    NSMutableParagraphStyle* style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    style.alignment = NSCenterTextAlignment;
    NSFont* more_font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica"
                                                                        traits:NSUnboldFontMask
                                                                        weight:0
                                                                          size:13.0];
    NSDictionary* normal_attrs = [IAFunctions textStyleWithFont:more_font
                                                 paragraphStyle:style
                                                         colour:IA_GREY_COLOUR(179.0)
                                                         shadow:nil];
    NSDictionary* hover_attrs = [IAFunctions textStyleWithFont:more_font
                                                paragraphStyle:style
                                                        colour:IA_RGB_COLOUR(11.0, 117.0, 162)
                                                        shadow:nil];
    
    self.more_button.attributedTitle = [[NSAttributedString alloc]
                                        initWithString:NSLocalizedString(@"more", @"more")
                                        attributes:normal_attrs];
    [self.more_button setNormalTextAttributes:normal_attrs];
    [self.more_button setHoverTextAttributes:hover_attrs];
    self.more_button.hand_cursor = YES;
}

- (void)addUser:(IAUser*)user
{
    if (user == nil)
        return;
    NSMutableArray* temp = [NSMutableArray arrayWithArray:self.search_field.objectValue];
    if ([temp.lastObject isKindOfClass:NSString.class])
        [temp removeObject:temp.lastObject];
    
    [temp addObject:user];
    [self.search_field setObjectValue:temp];
    [_delegate searchViewInputsChanged:self];
}

- (void)addElement:(InfinitSearchElement*)element
{
    if (element == nil)
        return;
    NSMutableArray* temp = [NSMutableArray arrayWithArray:self.search_field.objectValue];
    if ([temp.lastObject isKindOfClass:NSString.class])
        [temp removeObject:temp.lastObject];
    
    if (element.user != nil)
        [temp addObject:element.user];
    else
        [temp addObject:element.email];

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
        self.search_image.image = _loading_image;
        self.search_image.animates = YES;
    }
}

- (void)doSearchNow:(NSString*)search_string
{
    [self cancelLastSearchOperation];
    [_search_controller searchString:search_string];
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

- (void)controlTextDidChange:(NSNotification*)aNotification
{
    NSControl* control = aNotification.object;
    if (control != self.search_field)
        return;
    
    [self cancelLastSearchOperation];
    NSArray* tokens = self.search_field.objectValue;
    
    NSString* search_string;
    if ([tokens.lastObject isKindOfClass:NSString.class])
        search_string = [self trimLeadingWhitespace:tokens.lastObject];
    else
        search_string = @"";
    
    if (search_string.length > 0)
    {
        if (search_string.length < _last_search.length)
            [self clearResults];
        [self doDelayedSearch:search_string];
        if ([IAFunctions stringIsValidEmail:search_string])
            [_delegate searchViewInputsChanged:self];
    }
    else
    {
        [_search_controller clearResults];
        [self clearResults];
    }
    
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
    
    if (commandSelector == @selector(insertNewline:))
    {
        NSInteger row = self.table_view.selectedRow;
        if (row > -1 && row < _search_results.count)
        {
            InfinitSearchElement* element = _search_results[row];
            [self addElement:element];
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
                InfinitSearchElement* element = _search_results[row];
                [self addElement:element];
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
        [self.table_view selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
        [self.table_view scrollRowToVisible:0];
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
    InfinitSearchElement* element = _search_results[row];
    if (element == nil)
        return nil;
    
    IASearchResultsCellView* cell;
    if (element.user == nil)
    {
        cell = [tableView makeViewWithIdentifier:@"nonuser_search_cell"
                                           owner:self];
    }
    else
    {
        cell = [tableView makeViewWithIdentifier:@"infinit_user_search_cell"
                                           owner:self];
    }
    [cell setDelegate:self];
    [cell setUserFullname:element.fullname];
    if (element.user != nil)
    {
        [cell setUserFavourite:element.user.is_favourite];
        [cell setUserHandle:element.user.handle];
    }
    else
    {
        [cell setUserEmail:element.email];
    }
    
    NSImage* avatar = [IAFunctions makeRoundAvatar:element.avatar
                                        ofDiameter:30.0
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
    
    InfinitSearchElement* element = _search_results[row];
    [self addElement:element];
    
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

- (void)removeMoreButton
{
    CGFloat button_width = NSWidth(self.more_button.frame) - 15.0;
    [self.more_button removeFromSuperview];
    [self.search_field_width setConstant:(self.search_field_width.constant + button_width)];
}

- (void)showMoreButton:(BOOL)show
{
    if (!show && !_more_clicked)
        [self removeMoreButton];
}

- (IBAction)moreButtonClicked:(NSButton*)sender
{
    [self removeMoreButton];
    _more_clicked = YES;
    [_delegate searchViewHadMoreButtonClick:self];
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
    
    if (search_string.length == 0)
    {
        [_search_controller clearResults];
        [self clearResults];
        return;
    }
    
    _search_results = [NSMutableArray array];
    
    for (InfinitSearchPersonResult* person in sender.result_list)
    {
        InfinitSearchElement* element;
        if (person.infinit_user != nil)
        {
            element = [[InfinitSearchElement alloc] initWithAvatar:person.avatar
                                                             email:nil
                                                          fullname:person.fullname
                                                              user:person.infinit_user];
            [_search_results addObject:element];
            
        }
        else
        {
            element = [[InfinitSearchElement alloc] initWithAvatar:person.avatar
                                                             email:person.emails[0]
                                                          fullname:person.fullname
                                                              user:nil];
            if ([_delegate searchViewWantsIfGotFile:self])
                self.no_results_message.attributedStringValue = _invite_msg_str;
            else
                self.no_results_message.attributedStringValue = _add_file_str;
        }
    }
    
    if (self.search_image.animates)
    {
        self.search_image.animates = NO;
        self.search_image.image = _static_image;
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
    
    if (search_string.length == 0)
    {
        [_search_controller clearResults];
        [self clearResults];
        return;
    }
    self.search_image.animates = NO;
    self.search_image.image = _static_image;
    self.no_results_message.attributedStringValue = _no_result_msg_str;
    
    _search_results = [NSMutableArray array];

    for (InfinitSearchPersonResult* person in sender.result_list)
    {
        if (person.infinit_user != nil) // User is on Infinit
        {
            InfinitSearchElement* element = [[InfinitSearchElement alloc]
                                             initWithAvatar:person.avatar
                                                      email:nil
                                                   fullname:person.fullname
                                                       user:person.infinit_user];
            if ([tokens indexOfObject:element.user] == NSNotFound)
                [_search_results addObject:element];
        }
        else // Address book user
        {
            for (NSString* email in person.emails)
            {
                InfinitSearchElement* element = [[InfinitSearchElement alloc]
                                                 initWithAvatar:person.avatar
                                                          email:email
                                                       fullname:person.fullname
                                                           user:nil];
                if ([tokens indexOfObject:element.email] == NSNotFound)
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

- (void)searchResultCellWantsAddFavourite:(IASearchResultsCellView*)sender
{
    NSUInteger row = [self.table_view rowForView:sender];
    InfinitSearchElement* element = [_search_results objectAtIndex:row];
    if (element.user == nil)
        return;
    [_delegate searchView:self wantsAddFavourite:element.user];
}

- (void)searchResultCellWantsRemoveFavourite:(IASearchResultsCellView*)sender;
{
    NSUInteger row = [self.table_view rowForView:sender];
    InfinitSearchElement* element = [_search_results objectAtIndex:row];
    if (element.user == nil)
        return;
    [_delegate searchView:self wantsRemoveFavourite:element.user];
}

@end
