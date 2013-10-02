//
//  IAReportProblemWindowController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 10/2/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAReportProblemWindowController.h"

@interface IAReportProblemWindowController ()
@end

@implementation IAReportProblemWindowController
{
@private
    id<IAReportProblemProtocol> _delegate;
    
    NSUInteger _max_chars;
    NSString* _file_path;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithDelegate:(id<IAReportProblemProtocol>)delegate
{
    if (self = [super initWithWindowNibName:self.className])
    {
        _delegate = delegate;
        _max_chars = 2000;
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
}

//- Opening and Closing ----------------------------------------------------------------------------

- (void)show
{
    [self.window center];
    [self.window makeKeyAndOrderFront:nil];
}

- (void)close
{
    if (self.window == nil)
        return;
    
    [self.window close];
}

//- Text Field Handling ----------------------------------------------------------------------------

- (void)controlTextDidChange:(NSNotification*)obj
{
    if (self.user_message.stringValue.length > _max_chars)
        self.user_message.stringValue = [self.user_message.stringValue substringToIndex:_max_chars];
}

//- Button Handling --------------------------------------------------------------------------------

- (IBAction)addFileClicked:(NSButton*)sender
{
    NSOpenPanel* file_dialog = [NSOpenPanel openPanel];
    file_dialog.canChooseFiles = YES;
    file_dialog.canChooseDirectories = NO;
    file_dialog.allowsMultipleSelection = NO;
    
    NSString* file_path;
    
    if ([file_dialog runModal] == NSOKButton)
        file_path = [[file_dialog URLs] objectAtIndex:0];
    
}

- (IBAction)cancelClicked:(NSButton*)sender
{
    [_delegate reportProblemControllerWantsCancel:self];
}

- (IBAction)sendClicked:(NSButton*)sender
{
    
}

@end
