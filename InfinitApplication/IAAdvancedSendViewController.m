//
//  IAAdvancedSendViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/4/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAAdvancedSendViewController.h"

#import "IAHoverButtonCell.h"
#import "IASendFileListCellView.h"


@interface IAAdvancedSendViewController ()

@end

@interface IAAdvancedSendSearchView : NSView
@end

@implementation IAAdvancedSendSearchView

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

@interface IAAdvancedSendViewMainView : NSView
@end

@implementation IAAdvancedSendViewMainView

- (void)drawRect:(NSRect)dirtyRect
{
    NSBezierPath* path = [NSBezierPath bezierPathWithRect:self.bounds];
    [TH_RGBCOLOR(246.0, 246.0, 246.0) set];
    [path fill];
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

@interface IASendFileListRowView : NSTableRowView
@end

@implementation IASendFileListRowView

@end

//- Advanced Send View Controller ------------------------------------------------------------------

@implementation IAAdvancedSendViewController
{
    id<IAAdvancedSendViewProtocol> _delegate;
    
    IAUserSearchViewController* _user_search_controller;
    NSArray* _file_list;
    CGFloat _row_height;
    NSInteger _max_rows_shown;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithDelegate:(id<IAAdvancedSendViewProtocol>)delegate
   andSearchController:(IAUserSearchViewController*)search_controller
{
    if (self = [super initWithNibName:self.className bundle:nil])
    {
        _delegate = delegate;
        _user_search_controller = search_controller;
        _file_list = [_delegate advancedSendViewWantsFileList:self];
        _row_height = 40.0;
        _max_rows_shown = 5;
    }
    return self;
}

- (NSString*)description
{
    return @"[AdvancedSendView]";
}

- (BOOL)closeOnFocusLost
{
    return NO;
}

- (void)setButtonHoverImages
{
    [self.add_files_button.cell setHoverImage:[IAFunctions imageNamed:@"icon-files-hover"]];
    [self.cancel_button.cell setHoverImage:[IAFunctions imageNamed:@"icon-add-cancel-hover"]];
}

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

- (void)awakeFromNib
{
    [self setButtonHoverImages];
    [self initialiseSendButton];
    [_user_search_controller setDelegate:self];
    [self setButtonHoverImages];
    
    [self.search_view addSubview:_user_search_controller.view];
    [self.search_view setFrameSize:_user_search_controller.view.frame.size];
    [_user_search_controller.view setFrameOrigin:NSZeroPoint];
    [self.search_view addConstraints:[NSLayoutConstraint
                                    constraintsWithVisualFormat:@"V:|[search_view]|"
                                    options:0
                                    metrics:nil
                                    views:@{@"search_view": _user_search_controller.view}]];
}

- (void)loadView
{
    [super loadView];
    [self updateAddFilesButton];
    [self.files_view setFrameSize:NSMakeSize(self.files_view.frame.size.width,
                                             [self tableHeight])];
}

//- General Functions ------------------------------------------------------------------------------

- (void)updateAddFilesButton
{
    NSMutableString* files_str = [[NSMutableString alloc] initWithFormat:@"%ld ", _file_list.count];
    if (_file_list.count == 1)
        [files_str appendString:NSLocalizedString(@"file", @"file")];
    else
        [files_str appendString:NSLocalizedString(@"files", @"files")];
    NSDictionary* files_str_attrs = [IAFunctions
                                     textStyleWithFont:[NSFont systemFontOfSize:11.0]
                                     paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                     colour:TH_RGBCOLOR(189.0, 167.0, 170.0)
                                     shadow:nil];
    self.add_files_button.attributedTitle = [[NSAttributedString alloc]
                                             initWithString:files_str
                                             attributes:files_str_attrs];
}

- (void)filesUpdated
{
    _file_list = [_delegate advancedSendViewWantsFileList:self];
    [self updateTable];
    [self updateAddFilesButton];
}

//- Note Handling ----------------------------------------------------------------------------------

- (void)controlTextDidChange:(NSNotification*)aNotification
{
    NSControl* control = aNotification.object;
    if (control == self.note_field)
    {
        if (self.note_field.stringValue.length == 0)
            [self.characters_label setHidden:NO];
        else
            [self.characters_label setHidden:YES];
    }
}

//- Table Functions --------------------------------------------------------------------------------

- (void)updateTable
{
    CGFloat y_diff = [self tableHeight] - self.files_view.frame.size.height;
    [self.main_view setFrameSize:NSMakeSize(self.main_view.frame.size.width,
                                            self.main_view.frame.size.height + y_diff)];
    [self.files_view setFrameSize:NSMakeSize(self.files_view.frame.size.width,
                                             [self tableHeight])];
    [self resizeContainerView];
    [self.table_view reloadData];
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
    IASendFileListCellView* cell = [tableView makeViewWithIdentifier:@"file_cell"
                                                               owner:self];
    [cell setupCellWithFilePath:[_file_list objectAtIndex:row]];
    return cell;
}

- (NSTableRowView*)tableView:(NSTableView*)tableView
               rowViewForRow:(NSInteger)row
{
    IASendFileListRowView* row_view = [tableView rowViewAtRow:row makeIfNecessary:YES];
    if (row_view == nil)
        row_view = [[IASendFileListRowView alloc] initWithFrame:NSZeroRect];
    return row_view;
}

//- User Interaction With File Table ---------------------------------------------------------------

- (IBAction)removeFileClicked:(NSButton*)sender
{
    NSInteger row = [self.table_view rowForView:sender];
    [self.table_view beginUpdates];
    [self.table_view removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:row]
                           withAnimation:NSTableViewAnimationSlideLeft];
    [self.table_view endUpdates];
    [_delegate advancedSendView:self wantsRemoveFileAtIndex:row];
}

//- Button Handling --------------------------------------------------------------------------------

- (IBAction)cancelSendClicked:(NSButton*)sender
{
    [_delegate advancedSendViewWantsCancel:self];
}

//- User Search View Protocol ----------------------------------------------------------------------

- (void)searchView:(IAUserSearchViewController*)sender
       changedSize:(NSSize)size
  withActiveSearch:(BOOL)searching
{
    CGFloat y_diff = size.height - self.search_view.frame.size.height;
    NSSize new_main_size = NSMakeSize(self.main_view.frame.size.width,
                                       self.main_view.frame.size.height + y_diff);
    [self.main_view setFrameSize:new_main_size];
    [self resizeContainerView];
    [self.search_view setFrameSize:size];
    [self.advanced_view setFrameOrigin:NSZeroPoint];
    if (searching)
    {
        // XXX change footer_view
    }
}

- (void)searchView:(IAUserSearchViewController*)sender
         choseUser:(IAUser*)user
{
    
}

@end
