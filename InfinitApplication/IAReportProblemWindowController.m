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
    NSString* _message;
    
    NSUInteger _file_size_limit;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithDelegate:(id<IAReportProblemProtocol>)delegate
{
    if (self = [super initWithWindowNibName:self.className])
    {
        _delegate = delegate;
        _max_chars = 2000;
        _file_size_limit = 5 * 1024 * 1024;
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
    self.user_message.stringValue = @"";
    _file_path = nil;
    self.file_message.stringValue = NSLocalizedString(@"File must be less than 5 MB",
                                                      @"File must be less than 5 MB");
    [self.window center];
    [self.window makeKeyAndOrderFront:nil];
    [self.window makeFirstResponder:self.user_message];
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
        file_path = [[[file_dialog URLs] objectAtIndex:0] path];
    else
        return;
    
    NSDictionary* file_properties = [[NSFileManager defaultManager] attributesOfItemAtPath:file_path
                                                                                     error:NULL];
    if ([file_properties fileSize] < _file_size_limit)
    {
        _file_path = file_path;
        self.file_message.stringValue = [file_path lastPathComponent];
    }
    
}

- (IBAction)cancelClicked:(NSButton*)sender
{
    [_delegate reportProblemControllerWantsCancel:self];
}

- (IBAction)sendClicked:(NSButton*)sender
{
    _message = self.user_message.stringValue;
    if (_message.length < 3)
        _message = @"No message";
    if (_message.length > _max_chars)
        _message = [self.user_message.stringValue substringToIndex:_max_chars];
    if (_file_path == nil)
        _file_path = @"";
    [_delegate reportProblemController:self
                      wantsSendMessage:_message
                               andFile:_file_path];
}

@end
