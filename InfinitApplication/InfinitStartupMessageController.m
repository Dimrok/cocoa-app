//
//  InfinitStartupMessageController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 15/11/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "InfinitStartupMessageController.h"

@interface InfinitStartupMessageController ()
@end

@implementation InfinitStartupMessageController
{
@private
    id<InfinitStartupMessageControllerProtocol> _delegate;
    
    NSString* _message;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithDelegate:(id<InfinitStartupMessageControllerProtocol>)delegate
{
    if (self = [super initWithWindowNibName:self.className])
    {
        _delegate = delegate;
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    [self.window setLevel:NSFloatingWindowLevel];
    [self.web_view.mainFrame loadHTMLString:_message baseURL:nil];
}

//- General Functions ------------------------------------------------------------------------------

- (BOOL)metaStatusGood
{
    NSString* meta = [[[NSProcessInfo processInfo] environment] objectForKey:@"INFINIT_META_HOST"];
    if (meta == nil)
    {
        IALog(@"%@ ERROR: unable to get meta URL from environment", self);
        return NO;
    }
    
    NSString* meta_status_str = [NSString stringWithFormat:@"http://%@/status", meta];
    NSURL* meta_status_url = [NSURL URLWithString:meta_status_str];
    
    NSData* json_data = [NSData dataWithContentsOfURL:meta_status_url];
    
    if (json_data == nil)
    {
        IALog(@"%@ ERROR: problem fetching meta status", self);
        return NO;
    }
    
    NSDictionary* json_dict = [NSJSONSerialization JSONObjectWithData:json_data
                                                              options:NSJSONReadingMutableContainers
                                                                error:nil];
    NSNumber* status = [json_dict objectForKey:@"status"];

    if (status.boolValue == YES)
    {
        return YES;
    }
    else
    {
        _message = [json_dict objectForKey:@"message"];
        return NO;
    }
}

- (void)showStartupMessage
{
    [self.window makeKeyAndOrderFront:nil];
}

//- User Interactions ------------------------------------------------------------------------------

- (IBAction)quitButtonClicked:(NSButton*)sender
{
    [_delegate startupMessageControllerWantsQuit:self];
}

@end
