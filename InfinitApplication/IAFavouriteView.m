//
//  IAFavouriteView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/13/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAFavouriteView.h"

#import "IAAvatarManager.h"

@implementation IAFavouriteView
{
@private
    id <IAFavouriteViewProtocol> _delegate;
    IAUser* _user;
    NSArray* _drag_types;
    BOOL _hovering;
}

@synthesize user = _user;

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithFrame:(NSRect)frameRect
        andDelegate:(id<IAFavouriteViewProtocol>)delegate
            andUser:(IAUser*)user
{
    if (self = [super initWithFrame:frameRect])
    {
        _delegate = delegate;
        _user = user;
        _hovering = NO;
        _drag_types = [NSArray arrayWithObjects:NSFilenamesPboardType, nil];
        [self registerForDraggedTypes:_drag_types];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(avatarReceived:)
                                                   name:IA_AVATAR_MANAGER_AVATAR_FETCHED
                                                 object:nil];
    }
    return self;
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

//- Avatar Fetched Callback ------------------------------------------------------------------------

- (void)avatarReceived:(NSNotification*)notification
{
    IAUser* user = [notification.userInfo objectForKey:@"user"];
    if ([user isEqualTo:_user])
        [self setNeedsDisplay:YES];
}

//- Drawing ----------------------------------------------------------------------------------------

- (void)drawRect:(NSRect)dirtyRect
{
    NSImage* avatar;
    if (_hovering)
    {
        avatar = [IAFunctions makeRoundAvatar:[IAAvatarManager getAvatarForUser:_user
                                                                andLoadIfNeeded:YES]
                                   ofDiameter:NSWidth(self.bounds)
                        withBorderOfThickness:2.0
                                     inColour:IA_GREY_COLOUR(255.0)
                            andShadowOfRadius:2.0];
    }
    else
    {
        avatar = [IAFunctions makeRoundAvatar:[IAAvatarManager getAvatarForUser:_user
                                                                andLoadIfNeeded:YES]
                                   ofDiameter:NSWidth(self.bounds)
                        withBorderOfThickness:2.0
                                     inColour:IA_GREY_COLOUR(208.0)
                            andShadowOfRadius:2.0];
    }
    [avatar drawInRect:self.bounds
              fromRect:NSZeroRect
             operation:NSCompositeSourceOver
              fraction:1.0];
}

//- Drag Operations --------------------------------------------------------------------------------

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    NSPasteboard* paste_board = sender.draggingPasteboard;
    if ([paste_board availableTypeFromArray:_drag_types])
    {
        [_delegate favouriteViewGotDragEnter:self];
        _hovering = YES;
        [self setNeedsDisplay:YES];
        return NSDragOperationCopy;
    }
    return NSDragOperationNone;
}

- (void)draggingExited:(id<NSDraggingInfo>)sender
{
    [_delegate favouriteViewGotDragExit:self];
    _hovering = NO;
    [self setNeedsDisplay:YES];
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
    NSPasteboard* paste_board = sender.draggingPasteboard;
    if (![paste_board availableTypeFromArray:_drag_types])
        return NO;
    
    NSArray* files = [paste_board propertyListForType:NSFilenamesPboardType];
    
    if (files.count > 0)
        [_delegate favouriteView:self gotFiles:files];
    
    return YES;
}

@end
