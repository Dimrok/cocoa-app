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
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithDelegate:(id<IASimpleSendViewProtocol>)delegate
   andSearchController:(IAUserSearchViewController*)search_controller
{
    if (self = [super initWithNibName:self.className bundle:nil])
    {
        _delegate = delegate;
        _user_search_controller = search_controller;
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
    [self.main_view addSubview:_user_search_controller.view];
    [_user_search_controller.view setFrameSize:_user_search_controller.search_box_view.frame.size];
    [self.main_view setFrameSize:_user_search_controller.view.frame.size];
    [_user_search_controller.view setFrameOrigin:NSZeroPoint];
    [self resizeContainerView];
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

- (void)resizeContainerView
{
    CGFloat height = self.header_view.frame.size.height + self.main_view.frame.size.height +
        self.footer_view.frame.size.height;
    IALog(@"%(%f, %f)", self.main_view.frame.origin.x, self.main_view.frame.origin.y);
    [self.view setFrameSize:NSMakeSize(self.view.frame.size.width, height)];
    CGFloat y_diff = height - self.view.window.frame.size.height;
    NSRect window_rect = NSZeroRect;
    window_rect.origin = NSMakePoint(self.view.window.frame.origin.x,
                                     self.view.window.frame.origin.y - y_diff);
    window_rect.size = self.view.frame.size;
    [self.view.window setFrame:window_rect
                       display:YES];
    [self.view setFrameOrigin:NSZeroPoint];
    [self.view.window display];
    [self.view.window invalidateShadow];
}

//- Button Handling --------------------------------------------------------------------------------

- (IBAction)addNoteClicked:(NSButton*)sender
{
    if (sender == self.add_note_button)
    {
        [_delegate simpleSendViewWantsAddNote:self];
    }
}

//- User Search View Protocol ----------------------------------------------------------------------

- (void)searchView:(IAUserSearchViewController*)sender
       changedSize:(NSSize)size
{
    [self.main_view setFrameSize:size];
    [_user_search_controller.view setFrameOrigin:NSZeroPoint];
    [self resizeContainerView];
}

@end
