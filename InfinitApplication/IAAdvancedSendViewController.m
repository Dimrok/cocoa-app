//
//  IAAdvancedSendViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/4/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAAdvancedSendViewController.h"

@interface IAAdvancedSendViewController ()

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

@end

@implementation IAAdvancedSendViewController
{
    id<IAAdvancedSendViewProtocol> _delegate;
    
    IAUserSearchViewController* _user_search_controller;
    
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithDelegate:(id<IAAdvancedSendViewProtocol>)delegate
   andSearchController:(IAUserSearchViewController*)search_controller
{
    if (self = [super initWithNibName:self.className bundle:nil])
    {
        _delegate = delegate;
        _user_search_controller = search_controller;
    }
    return self;
}

- (NSString*)description
{
    return @"[AdvancedSendView]";
}

- (void)awakeFromNib
{
    [self.search_view addSubview:_user_search_controller.view];
    [_user_search_controller.view setFrameOrigin:NSMakePoint(0.0, 0.0)];
    [_user_search_controller.view setFrameSize:self.search_view.frame.size];
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
