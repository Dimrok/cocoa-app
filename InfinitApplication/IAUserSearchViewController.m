//
//  IASearchResultsViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/4/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAUserSearchViewController.h"

@interface IAUserSearchViewController ()

@end

@interface IASearchBoxView : NSView
@end

@implementation IASearchBoxView

- (void)drawRect:(NSRect)dirtyRect
{
    NSBezierPath* path = [NSBezierPath bezierPathWithRect:self.bounds];
    [TH_RGBCOLOR(255.0, 255.0, 255.0) set];
    [path fill];
}

@end

@implementation IAUserSearchViewController
{
    id<IAUserSearchViewProtocol> _delegate;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithDelegate:(id<IAUserSearchViewProtocol>)delegate
{
    if (self = [super initWithNibName:self.className bundle:nil])
    {
        _delegate = delegate;
    }
    
    return self;
}


- (NSString*)description
{
    return @"[SearchResultsViewController]";
}

- (void)awakeFromNib
{
    self.view.autoresizingMask = NSViewHeightSizable | NSViewWidthSizable;
    self.search_field.focusRingType = NSFocusRingTypeNone;
}

//- General Functions ------------------------------------------------------------------------------

- (void)searchForString:(NSString*)str
{
    
}

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

//- Table Functions --------------------------------------------------------------------------------

- (NSInteger)numberOfRowsInTableView:(NSTableView*)tableView
{
    return 0;
}

- (id)tableView:(NSTableView*)tableView
objectValueForTableColumn:(NSTableColumn*)tableColumn
            row:(NSInteger)row
{
    return nil;
}


@end
