//
//  InfinitServerTestController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 15/11/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "InfinitServerTestController.h"

@interface InfinitServerTestController ()
@end

@implementation InfinitServerTestController
{
@private
    id<InfinitServerTestControllerProtocol> _delegate;
    
    NSString* _message;
    NSString* _tropho_poke;
    
    InfinitServerStatus _tropho_status;
    NSInputStream* _tropho_input;
    NSOutputStream* _tropho_output;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithDelegate:(id<InfinitServerTestControllerProtocol>)delegate
{
    if (self = [super initWithWindowNibName:self.className])
    {
        _delegate = delegate;
        _message = @"";
        _tropho_poke = @"ouch";
        _tropho_status = INFINIT_SERVER_STATUS_UNKOWN;
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    [self.window setLevel:NSFloatingWindowLevel];
    [self.web_view.mainFrame loadHTMLString:_message baseURL:nil];
}

//- Meta Test --------------------------------------------------------------------------------------

- (InfinitServerStatus)metaStatus
{
    NSString* meta = [[[NSProcessInfo processInfo] environment] objectForKey:@"INFINIT_META_HOST"];
    NSString* port = [[[NSProcessInfo processInfo] environment] objectForKey:@"INFINIT_META_PORT"];
    if (meta == nil || port == nil)
    {
        IALog(@"%@ ERROR: unable to get meta URL from environment", self);
        return INFINIT_SERVER_UNREACHABLE;
    }
    
    NSString* meta_status_str = [NSString stringWithFormat:@"http://%@:%@/status", meta, port];
    NSURL* meta_status_url = [NSURL URLWithString:meta_status_str];
    
    NSData* json_data = [NSData dataWithContentsOfURL:meta_status_url];
    
    if (json_data == nil)
    {
        IALog(@"%@ ERROR: problem fetching meta status", self);
        return INFINIT_SERVER_UNREACHABLE;
    }
    
    NSError* err;
    NSDictionary* json_dict = [NSJSONSerialization JSONObjectWithData:json_data
                                                              options:NSJSONReadingMutableContainers
                                                                error:&err];
    if (err.code != noErr)
    {
        IALog(@"%@ ERROR: unable to deserialise data", self);
        return INFINIT_SERVER_UNREACHABLE;
    }
    
    NSNumber* status = [json_dict objectForKey:@"status"];

    if (status.boolValue == YES)
    {
        return INFINIT_SERVER_UP;
    }
    else
    {
        _message = [json_dict objectForKey:@"message"];
        return INFINIT_SERVER_DOWN_WITH_MESSAGE;
    }
}

//- Trophonius Test --------------------------------------------------------------------------------

- (void)fetchTrophoniusStatus
{
    [self performSelector:@selector(timeoutTrophoTest) withObject:nil afterDelay:10.0];
    
    NSString* tropho_url = [[[NSProcessInfo processInfo] environment] objectForKey:@"INFINIT_TROPHONIUS_HOST"];
    NSString* port = [[[NSProcessInfo processInfo] environment] objectForKey:@"INFINIT_TROPHONIUS_PORT"];
    if (tropho_url == nil || port == nil)
    {
        IALog(@"%@ ERROR: unable to get tropho URL from environment", self);
        [_delegate serverTestControllerHasTrophoniusStatus:self status:INFINIT_SERVER_UNREACHABLE];
        return;
    }
    
    CFReadStreamRef read_stream_ref;
    CFWriteStreamRef write_stream_ref;
    
    CFStreamCreatePairWithSocketToHost(NULL,
                                       (__bridge CFStringRef)tropho_url,
                                       port.intValue,
                                       &read_stream_ref,
                                       &write_stream_ref);
    
    CFWriteStreamSetProperty(write_stream_ref, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
    CFReadStreamSetProperty(read_stream_ref, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
    
    _tropho_input = (__bridge NSInputStream*)read_stream_ref;
    _tropho_output = (__bridge NSOutputStream*)write_stream_ref;
    
    [_tropho_input setDelegate:self];
    [_tropho_output setDelegate:self];
    
    [_tropho_input scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_tropho_output scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    [_tropho_input open];
    [_tropho_output open];
    
    NSString* msg = [NSString stringWithFormat:@"{\"poke\": \"%@\"}\n", _tropho_poke];
    NSData* poke_data = [msg dataUsingEncoding:NSASCIIStringEncoding];
    
    [_tropho_output write:poke_data.bytes maxLength:poke_data.length];
}

- (void)timeoutTrophoTest
{
    IALog(@"%@ WARNING: tropho test timed out", self);
    [self closeTrophoSocket];
    [_delegate serverTestControllerHasTrophoniusStatus:self status:INFINIT_SERVER_UNREACHABLE];
}

- (void)closeTrophoSocket
{
    // Don't try closing more than once
    if (_tropho_input.streamStatus == NSStreamStatusClosed ||
        _tropho_output.streamStatus == NSStreamStatusClosed)
    {
        return;
    }
    
    IALog(@"%@ Closing Trophonius socket", self);

    [_tropho_input removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_tropho_output removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    [_tropho_input setDelegate:nil];
    [_tropho_output setDelegate:nil];
    
    [_tropho_input close];
    [_tropho_output close];
    CFReadStreamClose((__bridge CFReadStreamRef)_tropho_input);
    CFWriteStreamClose((__bridge CFWriteStreamRef)_tropho_output);
    _tropho_input = nil;
    _tropho_output = nil;
}

- (void)checkTrophoniusMessage
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(timeoutTrophoTest)
                                               object:nil];
    uint8_t buffer[1024];
    NSInteger len;
    
    while ([_tropho_input hasBytesAvailable])
    {
        len = [_tropho_input read:buffer maxLength:sizeof(buffer)];
        if (len > 0)
        {
            NSString* response = [[NSString alloc] initWithBytes:buffer
                                                          length:len
                                                        encoding:NSASCIIStringEncoding];

            if ([response rangeOfString:_tropho_poke].location != NSNotFound)
            {
                [self closeTrophoSocket];
                IALog(@"%@ Trophonius responded correctly", self);
                [_delegate serverTestControllerHasTrophoniusStatus:self status:INFINIT_SERVER_UP];
            }
            else
            {
                [self closeTrophoSocket];
                IALog(@"%@ Trophonius responded with incorrect response: %@", self, response);
                [_delegate serverTestControllerHasTrophoniusStatus:self status:INFINIT_SERVER_STATUS_UNKOWN];
            }
        }
    }

}

- (void)stream:(NSStream*)aStream
   handleEvent:(NSStreamEvent)eventCode
{
    switch (eventCode)
    {
        case NSStreamEventHasBytesAvailable:
            if (aStream == _tropho_input)
                [self checkTrophoniusMessage];
            break;
            
        case NSStreamEventErrorOccurred:
            if (aStream == _tropho_input)
                IALog(@"%@ ERROR: error in trophonius input stream", self);
            else if (aStream == _tropho_output)
                IALog(@"%@ ERROR: error in trophonius output stream", self);
            [self closeTrophoSocket];
            [_delegate serverTestControllerHasTrophoniusStatus:self status:INFINIT_SERVER_UNREACHABLE];
            break;
            
        default:
            // Do nothing;
            break;
    }
}

//- General Functions ------------------------------------------------------------------------------

- (void)showMetaMessage
{
    _message = NSLocalizedString(@"<p>Unable to connect to Infinit Login servers</p> <p>Please contact <a href=\"mailto:support@infinit.io?Subject=Login Server Connection Problem\">support@infinit.io</a></p>", nil);
    [self.window makeKeyAndOrderFront:nil];
}

- (void)showTrophoniusMessage
{
    _message = NSLocalizedString(@"<p>Unable to connect to Infinit notification servers</p> <p>Please contact <a href=\"mailto:support@infinit.io?Subject=Notification Server Problem\">support@infinit.io</a></p>", nil);
    [self.window makeKeyAndOrderFront:nil];
}

//- User Interactions ------------------------------------------------------------------------------

- (IBAction)quitButtonClicked:(NSButton*)sender
{
    [_delegate serverTestControllerWantsQuit:self];
}

@end
