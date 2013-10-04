//
//  IASimpleSendViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/2/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IASimpleSendViewController.h"

@interface IASimpleSendViewController ()

@end

//- Simple Send Main View --------------------------------------------------------------------------

@interface IASimpleSendMainView : IAMainView
@end

@implementation IASimpleSendMainView

- (BOOL)isOpaque
{
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSBezierPath* bg = [IAFunctions roundedTopBezierWithRect:self.bounds cornerRadius:6.0];
    [IA_GREY_COLOUR(255.0) set];
    [bg fill];
}

@end

//- Simple Send Footer View ------------------------------------------------------------------------

@interface IASimpleSendFooterView : IAFooterView
@end

@implementation IASimpleSendFooterView

- (void)drawRect:(NSRect)dirtyRect
{
    // Dark line
    NSRect dark_line_rect = NSMakeRect(self.bounds.origin.x,
                                       self.bounds.origin.y + NSHeight(self.bounds) - 1.0,
                                       NSWidth(self.bounds),
                                       1.0);
    NSBezierPath* dark_path = [NSBezierPath bezierPathWithRect:dark_line_rect];
    [IA_GREY_COLOUR(223.0) set];
    [dark_path fill];
    
    // White line
    NSRect white_line_rect = NSMakeRect(self.bounds.origin.x,
                                        self.bounds.origin.y + NSHeight(self.bounds) - 2.0,
                                        NSWidth(self.bounds),
                                        1.0);
    NSBezierPath* white_path = [NSBezierPath bezierPathWithRect:white_line_rect];
    [IA_GREY_COLOUR(255.0) set];
    [white_path fill];
    
    // Grey background with rounded corners
    NSRect grey_rect = NSMakeRect(self.bounds.origin.x,
                                  self.bounds.origin.y,
                                  NSWidth(self.bounds),
                                  NSHeight(self.bounds) - 2.0);
    NSBezierPath* grey_path = [IAFunctions roundedBottomBezierWithRect:grey_rect cornerRadius:5.0];
    [IA_GREY_COLOUR(242.0) set];
    [grey_path fill];
}

@end

//- Simple Send View Controller --------------------------------------------------------------------

@implementation IASimpleSendViewController
{
@private
    id<IASimpleSendViewProtocol> _delegate;
    
    IAUserSearchViewController* _user_search_controller;
    NSArray* _file_list;
    NSArray* _recipient_list;
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
#ifdef IA_CORE_ANIMATION_ENABLED
        [self.view setWantsLayer:YES];
        [self.view setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawOnSetNeedsDisplay];
#endif
    }
    return self;
}

- (void)setupHoverButtons
{
    NSDictionary* normal_attrs = [IAFunctions textStyleWithFont:[NSFont systemFontOfSize:11.0]
                                                 paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                                         colour:IA_GREY_COLOUR(179.0)
                                                         shadow:nil];
    NSDictionary* hover_attrs = [IAFunctions textStyleWithFont:[NSFont systemFontOfSize:11.0]
                                                paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                                        colour:IA_RGB_COLOUR(11.0, 117.0, 162)
                                                        shadow:nil];
    
    [self.add_files_button setHoverImage:[IAFunctions imageNamed:@"icon-files-hover"]];
    [self.add_files_button setNormalTextAttributes:normal_attrs];
    [self.add_files_button setHoverTextAttributes:hover_attrs];
    
    [self.add_note_button setHoverImage:[IAFunctions imageNamed:@"icon-add-note-hover"]];
    
    [self.cancel_button setHoverImage:[IAFunctions imageNamed:@"icon-add-cancel-hover"]];
}

- (void)loadView
{
    [super loadView];
    [_user_search_controller setDelegate:self];
    [self setupHoverButtons];
    
    [self updateAddFilesButton];
    
    [self.main_view addSubview:_user_search_controller.view];
    [self.main_view addConstraints:[NSLayoutConstraint
                                    constraintsWithVisualFormat:@"V:|[search_view]|"
                                    options:0
                                    metrics:nil
                                    views:@{@"search_view": _user_search_controller.view}]];
    
    self.content_height_constraint.constant = NSHeight(_user_search_controller.search_box_view.frame);
    
    [self performSelector:@selector(setFocusToSearchField)
               withObject:nil
               afterDelay:0.4];
    [self setSendButtonState];
}

- (void)setFocusToSearchField
{
    [self.view.window makeFirstResponder:_user_search_controller.search_field];
    [_user_search_controller cursorAtEndOfSearchBox];
}

- (BOOL)closeOnFocusLost
{
    return NO;
}

//- General Functions ------------------------------------------------------------------------------

- (void)setSendButtonState
{
    if ([self inputsGood])
        [_user_search_controller.send_button setEnabled:YES];
    else
        [_user_search_controller.send_button setEnabled:NO];
}

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
                                     colour:IA_RGB_COLOUR(189.0, 167.0, 170.0)
                                     shadow:nil];
    self.add_files_button.attributedTitle = [[NSAttributedString alloc]
                                             initWithString:files_str
                                             attributes:files_str_attrs];
}

- (void)filesUpdated
{
    _file_list = [_delegate simpleSendViewWantsFileList:self];
    [self updateAddFilesButton];
    [self setSendButtonState];
}

- (BOOL)inputsGood
{
    NSMutableArray* recipients = [NSMutableArray arrayWithArray:
                                  [_user_search_controller recipientList]];
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
    return YES;
}

//- Button Handling --------------------------------------------------------------------------------

- (IBAction)addNoteClicked:(NSButton*)sender
{
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
     {
         context.duration = 0.15;
         [_user_search_controller removeSendButton];
     }
                        completionHandler:^
     {
         [_delegate simpleSendViewWantsAddNote:self];
     }];
}

- (IBAction)cancelSendClicked:(NSButton*)sender
{
    [_delegate simpleSendViewWantsCancel:self];
}

- (IBAction)addFileClicked:(NSButton*)sender
{
    [_delegate simpleSendViewWantsOpenFileDialogBox:self];
}

//- User Search View Protocol ----------------------------------------------------------------------

- (BOOL)searchViewWantsIfGotFile:(IAUserSearchViewController*)sender
{
    if ([[_delegate simpleSendViewWantsFileList:self] count] > 0)
        return YES;
    
    return NO;
}

- (void)searchView:(IAUserSearchViewController*)sender
   changedToHeight:(CGFloat)height
{
    if (self.content_height_constraint.constant == height)
        return;
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
    {
        context.duration = 0.15;
        [self.content_height_constraint.animator setConstant:height];
    }
                        completionHandler:^
    {
    }];
}

- (void)searchViewWantsLoseFocus:(IAUserSearchViewController*)sender
{
    // Do nothing
}

- (void)searchViewHadSendButtonClick:(IAUserSearchViewController*)sender
{
    if ([self inputsGood])
    {
        [_delegate simpleSendView:self
                   wantsSendFiles:_file_list
                          toUsers:_recipient_list];
    }
}

- (void)searchView:(IAUserSearchViewController*)sender
 wantsAddFavourite:(IAUser*)user
{
    [_delegate simpleSendView:self
            wantsAddFavourite:user];
}

- (void)searchView:(IAUserSearchViewController*)sender
wantsRemoveFavourite:(IAUser*)user
{
    [_delegate simpleSendView:self
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
        [_delegate simpleSendView:self
                   wantsSendFiles:_file_list
                          toUsers:_recipient_list];
    }
}

@end
