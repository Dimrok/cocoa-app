//
//  InfinitCombinedSendViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 24/12/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "InfinitCombinedSendViewController.h"

#import "InfinitSendFileListCellView.h"

@interface InfinitCombinedSendViewController ()

@end

//- Combined Search View ---------------------------------------------------------------------------

@interface InfinitCombinedSendSearchView : NSView
@end

@implementation InfinitCombinedSendSearchView

- (void)drawRect:(NSRect)dirtyRect
{
    NSBezierPath* bg = [IAFunctions roundedTopBezierWithRect:self.bounds cornerRadius:6.0];
    [IA_GREY_COLOUR(255.0) set];
    [bg fill];
}

- (void)setFrame:(NSRect)frameRect
{
    [super setFrame:frameRect];
    [self invalidateIntrinsicContentSize];
    [self setNeedsDisplay:YES];
}

- (void)setFrameSize:(NSSize)newSize
{
    [super setFrameSize:newSize];
    [self invalidateIntrinsicContentSize];
    [self setNeedsDisplay:YES];
}

- (NSSize)intrinsicContentSize
{
    return self.bounds.size;
}

@end

//- Combined Send Main View ------------------------------------------------------------------------

@interface InfinitCombinedSendViewMainView : NSView
@end

@implementation InfinitCombinedSendViewMainView

- (BOOL)isOpaque
{
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Grey background
    [IA_GREY_COLOUR(248.0) set];
    NSRectFill(self.bounds);

    // Dark line below search
    NSBezierPath* first_dark_line =
        [NSBezierPath bezierPathWithRect:NSMakeRect(self.bounds.origin.x,
                                                    NSHeight(self.bounds) - 1.0,
                                                    NSWidth(self.bounds),
                                                    1.0)];
    [IA_GREY_COLOUR(235.0) set];
    [first_dark_line fill];
    
    // Note field goes here (100 px)
    
    // Dark line below note field
    NSBezierPath* second_dark_line =
        [NSBezierPath bezierPathWithRect:NSMakeRect(self.bounds.origin.x,
                                                    NSHeight(self.bounds) - 102.0,
                                                    NSWidth(self.bounds),
                                                    1.0)];
    [IA_GREY_COLOUR(235.0) set];
    [second_dark_line fill];
    
    // White line below note field
    NSBezierPath* white_line = [NSBezierPath bezierPathWithRect:
                                NSMakeRect(self.bounds.origin.x,
                                           NSHeight(self.bounds) - 103.0,
                                           NSWidth(self.bounds),
                                           1.0)];
    [IA_GREY_COLOUR(255.0) set];
    [white_line fill];
}

- (void)setFrame:(NSRect)frameRect
{
    [super setFrame:frameRect];
    [self invalidateIntrinsicContentSize];
    [self setNeedsDisplay:YES];
}

- (void)setFrameSize:(NSSize)newSize
{
    [super setFrameSize:newSize];
    [self invalidateIntrinsicContentSize];
    [self setNeedsDisplay:YES];
}

- (NSSize)intrinsicContentSize
{
    return self.bounds.size;
}

@end

//- File Table Row View ----------------------------------------------------------------------------

@interface InfinitSendFileListRowView : NSTableRowView
@end

@implementation InfinitSendFileListRowView

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
    // Grey background
    [IA_GREY_COLOUR(248.0) set];
    NSRectFill(self.bounds);
    
    // Dark grey line
    NSRect dark_grey_rect = NSMakeRect(self.bounds.origin.x,
                                   self.bounds.origin.y + 1.0,
                                   self.bounds.size.width,
                                   1.0);
    NSBezierPath* dark_grey_line = [NSBezierPath bezierPathWithRect:dark_grey_rect];
    [IA_GREY_COLOUR(235.0) set];
    [dark_grey_line fill];
    
    // White line
    NSRect white_rect = NSMakeRect(self.bounds.origin.x,
                                       self.bounds.origin.y,
                                       self.bounds.size.width,
                                       1.0);
    NSBezierPath* white_line = [NSBezierPath bezierPathWithRect:white_rect];
    [IA_GREY_COLOUR(255.0) set];
    [white_line fill];
}

@end

//- Combined Send View Controller ------------------------------------------------------------------

@implementation InfinitCombinedSendViewController
{
    id<InfinitCombinedSendViewProtocol> _delegate;
    
    IAUserSearchViewController* _user_search_controller;
    NSArray* _file_list;
    NSArray* _recipient_list;
    CGFloat _row_height;
    NSInteger _max_rows_shown;
    NSString* _message;
    
    BOOL _expanded_view;
    NSDictionary* _characters_attrs;
    NSDictionary* _file_count_attrs;
    NSUInteger _note_limit;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithDelegate:(id<InfinitCombinedSendViewProtocol>)delegate
   andSearchController:(IAUserSearchViewController*)search_controller
               focusOn:(InfinitCombinedSendViewFocus)focus
{
    if (self = [super initWithNibName:self.className bundle:nil])
    {
        _delegate = delegate;
        _user_search_controller = search_controller;
        [_user_search_controller setDelegate:self];
        _file_list = [_delegate combinedSendViewWantsFileList:self];
        _row_height = 45.0;
        _max_rows_shown = 3;
        _message = @"";
        _note_limit = 100;
        _expanded_view = NO;
        NSFont* small_font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica"
                                                                        traits:NSUnboldFontMask
                                                                        weight:0
                                                                          size:10.0];
        NSMutableParagraphStyle* right_aligned =
            [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        right_aligned.alignment = NSRightTextAlignment;
        _characters_attrs = [IAFunctions textStyleWithFont:small_font
                                            paragraphStyle:right_aligned
                                                    colour:IA_GREY_COLOUR(217.0)
                                                    shadow:nil];

        NSShadow* file_count_shadow = [IAFunctions shadowWithOffset:NSMakeSize(0.0, -1.0)
                                                         blurRadius:1.0
                                                             colour:IA_GREY_COLOUR(0.0)];
        
        _file_count_attrs = [IAFunctions textStyleWithFont:small_font
                                            paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                                    colour:IA_GREY_COLOUR(255.0)
                                                    shadow:file_count_shadow];
        [self performSelector:@selector(setFocus:)
                   withObject:[NSNumber numberWithInt:focus]
                   afterDelay:0.2];
    }
    return self;
}

- (BOOL)closeOnFocusLost
{
    return NO;
}

- (void)setupExpandedView
{
    NSFont* add_files_font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica"
                                                                        traits:NSUnboldFontMask
                                                                        weight:0
                                                                          size:13.0];
    NSMutableParagraphStyle* centred_style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    centred_style.alignment = NSCenterTextAlignment;
    NSDictionary* normal_attrs = [IAFunctions textStyleWithFont:add_files_font
                                                 paragraphStyle:centred_style
                                                         colour:IA_GREY_COLOUR(179.0)
                                                         shadow:nil];
    NSDictionary* hover_attrs = [IAFunctions textStyleWithFont:add_files_font
                                                paragraphStyle:centred_style
                                                        colour:IA_RGB_COLOUR(11.0, 117.0, 162)
                                                        shadow:nil];

    [self.add_files_button setNormalImage:[IAFunctions imageNamed:@"icon-files"]];
    [self.add_files_button setHoverImage:[IAFunctions imageNamed:@"icon-files-hover"]];
    [self.add_files_button setNormalTextAttributes:normal_attrs];
    [self.add_files_button setHoverTextAttributes:hover_attrs];
    
    self.add_files_button.hand_cursor = YES;
    
    NSString* add_files_str = [NSString stringWithFormat:@"%@", NSLocalizedString(@"Add files...",
                                                                                  @"add files...")];
    self.add_files_button.attributedTitle = [[NSAttributedString alloc] initWithString:add_files_str
                                                                            attributes:normal_attrs];
    
    NSString* characters_str = [NSString stringWithFormat:@"%lu %@", _note_limit,
                                NSLocalizedString(@"chars left", @"chars left")];
    self.characters_label.attributedStringValue =
    [[NSAttributedString alloc] initWithString:characters_str
                                    attributes:_characters_attrs];
    
    if ([IAFunctions osxVersion] == INFINIT_OS_X_VERSION_10_9)
    {
        NSFont* search_font = [[NSFontManager sharedFontManager]fontWithFamily:@"Helvetica"
                                                                        traits:NSUnboldFontMask
                                                                        weight:3
                                                                          size:13.0];
        NSDictionary* search_attrs = [IAFunctions textStyleWithFont:search_font
                                                     paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                                             colour:IA_GREY_COLOUR(209.0)
                                                             shadow:nil];
        NSString* placeholder_str = NSLocalizedString(@"Optional note...",
                                                      @"Optional note...");
        NSAttributedString* search_placeholder = [[NSAttributedString alloc]
                                                  initWithString:placeholder_str
                                                  attributes:search_attrs];
        [self.note_field.cell setPlaceholderAttributedString:search_placeholder];
    }
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
    [super loadView];

    [self setSendButtonState];
    
    CGFloat y_diff_search = NSHeight(_user_search_controller.view.frame) -
    NSHeight(self.search_view.frame);
    
    [self.search_view addSubview:_user_search_controller.view];
    
    [self.search_height_constraint setConstant:(y_diff_search +
                                                self.search_height_constraint.constant)];
    [self.search_view addConstraints:[NSLayoutConstraint
                                      constraintsWithVisualFormat:@"V:|[search_view]|"
                                      options:0
                                      metrics:nil
                                      views:@{@"search_view": _user_search_controller.view}]];
    
    self.file_count.attributedStringValue =
        [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%lu", _file_list.count]
                                        attributes:_file_count_attrs];
    self.send_button.toolTip = NSLocalizedString(@"Send", @"send");
    self.cancel_button.toolTip = NSLocalizedString(@"Cancel", @"cancel");
}

//- General Functions ------------------------------------------------------------------------------

- (void)setSendButtonState
{
    if ([self inputsGood])
        [self.send_button setEnabled:YES];
    else
        [self.send_button setEnabled:NO];
}

- (void)filesUpdated
{
    _file_list = [_delegate combinedSendViewWantsFileList:self];
    NSString* count_str;
    if (_file_list.count > 99)
        count_str = @"+";
    else
        count_str = [NSString stringWithFormat:@"%lu", _file_list.count];
    self.file_count.attributedStringValue =
        [[NSAttributedString alloc] initWithString:count_str attributes:_file_count_attrs];
    if (_expanded_view)
    {
        [self updateTable];
    }
    [self setSendButtonState];
}

- (void)setFocus:(InfinitCombinedSendViewFocus)focus
{
    [self.note_field.cell setPlaceholderString:NSLocalizedString(@"Optional note...",
                                                                 "Optional note...")];
    switch (focus)
    {
        case COMBINED_VIEW_USER_SEARCH_FOCUS:
            [self.view.window makeFirstResponder:_user_search_controller.search_field];
            [_user_search_controller cursorAtEndOfSearchBox];
            break;
        case COMBINED_VIEW_NOTE_FOCUS:
            [self.view.window makeFirstResponder:self.note_field];
            break;
        default:
            [self.view.window makeFirstResponder:_user_search_controller.search_field];
            [_user_search_controller cursorAtEndOfSearchBox];
            break;
    }
}

- (BOOL)inputsGood
{
    NSMutableArray* recipients =
        [NSMutableArray arrayWithArray:[_user_search_controller recipientList]];
    [_user_search_controller checkInputs];
    if (recipients.count == 0)
        return NO;
    if (_file_list.count == 0)
        return NO;
    
    _recipient_list = [NSArray arrayWithArray:recipients];
    
    for (id object in _recipient_list)
    {
        if ([object isKindOfClass:NSString.class] && ![IAFunctions stringIsValidEmail:object] &&
            ![object isKindOfClass:IAUser.class])
        {
            return NO;
        }
    }
    
    if (self.note_field.stringValue.length > _note_limit)
        _message = [self.note_field.stringValue substringWithRange:NSMakeRange(0, _note_limit)];
    else
        _message = self.note_field.stringValue;
    
    return YES;
}

//- Note Handling ----------------------------------------------------------------------------------

- (void)controlTextDidChange:(NSNotification*)aNotification
{
    NSControl* control = aNotification.object;
    if (control != self.note_field)
        return;
    
    if (self.note_field.stringValue.length > _note_limit)
    {
        self.note_field.stringValue = [self.note_field.stringValue
                                       substringWithRange:NSMakeRange(0, _note_limit)];
    }
    
    NSUInteger note_length = self.note_field.stringValue.length;
    
    NSString* characters_str;
    if (_note_limit - note_length == 1)
    {
        characters_str = NSLocalizedString(@"1 char left", @"1 char left");
    }
    else
    {
        characters_str = [NSString stringWithFormat:@"%lu %@", (_note_limit - note_length),
                          NSLocalizedString(@"chars left", @"chars left")];
    }
    
    self.characters_label.attributedStringValue = [[NSAttributedString alloc]
                                                   initWithString:characters_str
                                                   attributes:_characters_attrs];
}

- (BOOL)control:(NSControl*)control
       textView:(NSTextView*)textView
doCommandBySelector:(SEL)commandSelector
{
    if (control != self.note_field)
        return NO;
    
    if (commandSelector == @selector(insertTab:) || commandSelector == @selector(insertBacktab:))
    {
        [self.view.window makeFirstResponder:_user_search_controller.search_field];
        [_user_search_controller cursorAtEndOfSearchBox];
        return YES;
    }
    if (commandSelector == @selector(insertNewline:))
    {
        return YES;
    }
    return NO;
}

//- Table Functions --------------------------------------------------------------------------------

- (void)updateTable
{
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
     {
         context.duration = 0.15;
         [self.combined_height_constraint.animator setConstant:(145.0 + [self tableHeight])];
         [self.table_height_constraint.animator setConstant:[self tableHeight]];
     }
                        completionHandler:^
     {
         [self.table_view reloadData];
     }];
}

- (CGFloat)tableHeight
{
    CGFloat total_height = _file_list.count * _row_height;
    CGFloat max_height = _row_height * _max_rows_shown;
    if (total_height > max_height)
        return max_height;
    else
        return total_height;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView*)tableView
{
    return _file_list.count;
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
    NSString* file = [_file_list objectAtIndex:row];
    if (file.length == 0)
        return nil;
    InfinitSendFileListCellView* cell = [tableView makeViewWithIdentifier:@"file_cell"
                                                               owner:self];
    [cell setupCellWithFilePath:[_file_list objectAtIndex:row]];
    return cell;
}

- (NSTableRowView*)tableView:(NSTableView*)tableView
               rowViewForRow:(NSInteger)row
{
    InfinitSendFileListRowView* row_view = [tableView rowViewAtRow:row makeIfNecessary:YES];
    if (row_view == nil)
        row_view = [[InfinitSendFileListRowView alloc] initWithFrame:NSZeroRect];
    return row_view;
}

//- User Interaction With File Table ---------------------------------------------------------------

- (IBAction)removeFileClicked:(NSButton*)sender
{
    NSInteger row = [self.table_view rowForView:sender];
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
     {
         [self.table_view beginUpdates];
         [self.table_view removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:row]
                                withAnimation:NSTableViewAnimationSlideRight];
         [self.table_view endUpdates];
     }
                        completionHandler:^
     {
         [_delegate combinedSendView:self wantsRemoveFileAtIndex:row];
     }];
}

//- Button Handling --------------------------------------------------------------------------------

- (IBAction)addFilesClicked:(NSButton*)sender
{
    [_delegate combinedSendViewWantsOpenFileDialogBox:self];
}

- (IBAction)cancelSendClicked:(NSButton*)sender
{
    [_delegate combinedSendViewWantsCancel:self];
}

- (IBAction)sendButtonClicked:(NSButton*)sender
{
    if ([self inputsGood])
    {
        [_delegate combinedSendView:self
                     wantsSendFiles:_file_list
                            toUsers:_recipient_list
                        withMessage:_message];
    }
}

//- User Search View Protocol ----------------------------------------------------------------------

- (BOOL)searchViewWantsIfGotFile:(IAUserSearchViewController*)sender
{
    if ([[_delegate combinedSendViewWantsFileList:self] count] > 0)
        return YES;
    
    return NO;
}

- (void)searchView:(IAUserSearchViewController*)sender
   changedToHeight:(CGFloat)height
{
    CGFloat y_diff = height - NSHeight(self.search_view.frame);
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
     {
         context.duration = 0.15;
         [self.search_height_constraint.animator
          setConstant:(self.search_height_constraint.constant + y_diff)];
     }
                        completionHandler:^
     {
         // WORKAROUND: Autolayout doesn't adjust scrollview size until scroll on 10.7
         if ([IAFunctions osxVersion] == INFINIT_OS_X_VERSION_10_7)
             [_user_search_controller.table_view.enclosingScrollView setNeedsLayout:YES];
     }];
}

- (void)searchViewWantsLoseFocus:(IAUserSearchViewController*)sender
{
    [self.view.window makeFirstResponder:self.note_field];
}

- (void)searchViewHadMoreButtonClick:(IAUserSearchViewController*)sender
{
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
     {
         context.duration = 0.15;
         [self setupExpandedView];
         [self.combined_height_constraint.animator setConstant:([self tableHeight] + 145.0)];
         [self.table_height_constraint setConstant:[self tableHeight]];
     }
                        completionHandler:^
     {
         _expanded_view = YES;
     }];
}

- (void)searchView:(IAUserSearchViewController*)sender
 wantsAddFavourite:(IAUser*)user
{
    [_delegate combinedSendView:self
              wantsAddFavourite:user];
}

- (void)searchView:(IAUserSearchViewController*)sender
wantsRemoveFavourite:(IAUser*)user
{
    [_delegate combinedSendView:self
           wantsRemoveFavourite:user];
}

- (void)searchViewInputsChanged:(IAUserSearchViewController*)sender
{
    [self setSendButtonState];
}

- (void)searchViewGotEnterPress:(IAUserSearchViewController*)sender
{
    if ([self inputsGood])
    {
        [_delegate combinedSendView:self
                     wantsSendFiles:_file_list
                            toUsers:_recipient_list
                        withMessage:_message];
    }
}

@end
