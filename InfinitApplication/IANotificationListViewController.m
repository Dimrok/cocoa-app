//
//  IANotificationListViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 7/31/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IANotificationListViewController.h"

#import <Gap/version.h>

@interface IANotificationListViewController ()

@end

@implementation IANotificationListViewController
{
@private
    id<IANotificationListViewProtocol> _delegate;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithDelegate:(id<IANotificationListViewProtocol>)delegate
{
    if (self = [super initWithNibName:[self className] bundle:nil])
    {
        _delegate = delegate;
    }
    return self;
}

- (void)awakeFromNib
{
    NSString* version_str = [NSString stringWithFormat:@"v%@",
                             [NSString stringWithUTF8String:INFINIT_VERSION]];
    _version_item.title = version_str;
    self.view.autoresizingMask = NSViewHeightSizable;
}

- (NSString*)description
{
    return @"[NotificationListViewController]";
}

//- Button Handling --------------------------------------------------------------------------------

- (IBAction)settingsButtonClicked:(NSButton*)sender
{
    NSPoint point = NSMakePoint(sender.frame.origin.x + sender.frame.size.width,
                                sender.frame.origin.y);
    NSPoint menu_origin = [sender.superview convertPoint:point toView:nil];
    NSEvent* event = [NSEvent mouseEventWithType:NSLeftMouseDown
                                        location:menu_origin
                                   modifierFlags:NSLeftMouseDownMask
                                       timestamp:0
                                    windowNumber:sender.window.windowNumber
                                         context:sender.window.graphicsContext
                                     eventNumber:0
                                      clickCount:1
                                        pressure:1];
    [NSMenu popUpContextMenu:_gear_menu withEvent:event forView:sender];
}

- (IBAction)transferButtonClicked:(NSButton*)sender
{
    [_delegate notificationListGotTransferClick:self];
}

//- Menu Handling ----------------------------------------------------------------------------------

- (IBAction)quitClicked:(NSMenuItem*)sender
{
    [_delegate notificationListWantsQuit:self];
}

@end
