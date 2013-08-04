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

@interface IASimpleSendSearchView : NSView
@end

@implementation IASimpleSendSearchView

- (void)drawRect:(NSRect)dirtyRect
{
    NSBezierPath* path = [NSBezierPath bezierPathWithRect:self.bounds];
    [TH_RGBCOLOR(255.0, 255.0, 255.0) set];
    [path fill];
}

@end

@interface IASimpleSendFooterView : NSView
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
    
    IASearchResultsViewController* _search_results_controller;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithDelegate:(id<IASimpleSendViewProtocol>)delegate
{
    if (self = [super initWithNibName:[self className] bundle:nil])
    {
        _delegate = delegate;
        _search_results_controller = [[IASearchResultsViewController alloc] initWithDelegate:self];
    }
    return self;
}

- (void)awakeFromNib
{
    [self.search_field setFocusRingType:NSFocusRingTypeNone];
    [self.search_field setDelegate:self];
    [self.clear_search setHidden:YES];
    self.search_results = _search_results_controller.view;
}

- (NSString*)description
{
    return @"[SimpleSendView]";
}

//- General Functions ------------------------------------------------------------------------------



//- Search Field -----------------------------------------------------------------------------------

- (void)controlTextDidChange:(NSNotification*)aNotification
{
    NSControl* control = aNotification.object;
    if (control == self.search_field)
    {
        if (self.search_field.stringValue.length == 0)
            [self.clear_search setHidden:YES];
        else
            [self.clear_search setHidden:NO];
    }
}

- (IBAction)clearSearchField:(NSButton*)sender
{
    if (sender == self.clear_search)
    {
        self.search_field.stringValue = @"";
        [self.clear_search setHidden:YES];
    }
}

@end
