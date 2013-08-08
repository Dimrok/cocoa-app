//
//  IASimpleSendViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/2/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IASimpleSendViewController.h"

#import "IAHoverButtonCell.h"

@interface IASimpleSendViewController ()

@end

@interface IASimpleSendFooterView : IAFooterView
@end

@implementation IASimpleSendFooterView

- (void)drawRect:(NSRect)dirtyRect
{
    // Dark line
    NSRect dark_line_rect = NSMakeRect(self.bounds.origin.x,
                                       self.bounds.origin.y + self.bounds.size.height - 1.0,
                                       self.bounds.size.width,
                                       1.0);
    NSBezierPath* dark_path = [NSBezierPath bezierPathWithRect:dark_line_rect];
    [TH_RGBCOLOR(223.0, 223.0, 223.0) set];
    [dark_path fill];
    
    // White line
    NSRect white_line_rect = NSMakeRect(self.bounds.origin.x,
                                        self.bounds.origin.y + self.bounds.size.height - 2.0,
                                        self.bounds.size.width,
                                        1.0);
    NSBezierPath* white_path = [NSBezierPath bezierPathWithRect:white_line_rect];
    [TH_RGBCOLOR(255.0, 255.0, 255.0) set];
    [white_path fill];
    
    // Grey background with rounded corners
    NSRect grey_rect = NSMakeRect(self.bounds.origin.x,
                                  self.bounds.origin.y,
                                  self.bounds.size.width,
                                  self.bounds.size.height - 2.0);
    NSBezierPath* grey_path = [IAFunctions roundedBottomBezierWithRect:grey_rect cornerRadius:5.0];
    [TH_RGBCOLOR(242.0, 242.0, 242.0) set];
    [grey_path fill];
}

@end

@implementation IASimpleSendViewController
{
@private
    id<IASimpleSendViewProtocol> _delegate;
    
    IAUserSearchViewController* _user_search_controller;
    NSArray* _file_list;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithDelegate:(id<IASimpleSendViewProtocol>)delegate
   andSearchController:(IAUserSearchViewController*)search_controller
{
    if (self = [super initWithNibName:self.className bundle:nil])
    {
        _delegate = delegate;
        _user_search_controller = search_controller;
        _file_list = [_delegate simpleSendViewWantsFileList:self];
    }
    return self;
}

- (void)setButtonHoverImages
{
    [self.add_files_button.cell setHoverImage:[IAFunctions imageNamed:@"icon-files-hover"]];
    [self.add_person_button.cell setHoverImage:[IAFunctions imageNamed:@"icon-add-people-hover"]];
    [self.add_note_button.cell setHoverImage:[IAFunctions imageNamed:@"icon-add-note-hover"]];
    [self.cancel_button.cell setHoverImage:[IAFunctions imageNamed:@"icon-add-cancel-hover"]];
}

- (void)awakeFromNib
{
    [_user_search_controller setDelegate:self];
    [self setButtonHoverImages];
    
    [self updateAddFilesButton];
    
    [self.main_view addSubview:_user_search_controller.view];
    [self.main_view setFrameSize:_user_search_controller.search_box_view.frame.size];
    [_user_search_controller.view setFrameOrigin:NSZeroPoint];
    [self.main_view addConstraints:[NSLayoutConstraint
                                    constraintsWithVisualFormat:@"V:|[search_view]|"
                                    options:0
                                    metrics:nil
                                    views:@{@"search_view": _user_search_controller.view}]];
    [self resizeContainerView];
    [self.view.window makeFirstResponder:_user_search_controller.search_field];
    

    [self performSelector:@selector(setFocusToSearchField)
               withObject:nil
               afterDelay:0];
}

- (void)setFocusToSearchField
{
    [self.view.window makeFirstResponder:_user_search_controller.search_field];
}

- (NSString*)description
{
    return @"[SimpleSendView]";
}

- (BOOL)closeOnFocusLost
{
    return NO;
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

- (void)filesAdded
{
    _file_list = [_delegate simpleSendViewWantsFileList:self];
    [self updateAddFilesButton];
}

//- Button Handling --------------------------------------------------------------------------------

- (IBAction)addNoteClicked:(NSButton*)sender
{
    [_delegate simpleSendViewWantsAddNote:self];
}

- (IBAction)addPersonClicked:(NSButton*)sender
{
    [_delegate simpleSendViewWantsAddRecipient:self];
}

- (IBAction)cancelSendClicked:(NSButton*)sender
{
    [_delegate simpleSendViewWantsCancel:self];
}

- (IBAction)addFileClicked:(NSButton*)sender
{
    [_delegate simpleSendViewWantsAddFile:self];
}

//- User Search View Protocol ----------------------------------------------------------------------

- (void)searchView:(IAUserSearchViewController*)sender
       changedSize:(NSSize)size
  withActiveSearch:(BOOL)searching
{
    [self.main_view setFrameSize:size];
    [self resizeContainerView];
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
