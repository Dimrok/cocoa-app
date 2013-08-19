//
//  IAFavouritesView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/14/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAFavouritesView.h"

@implementation IAFavouritesView
{
@private
    id<IAFavouritesViewProtocol> _delegate;
    NSArray* _drag_types;
    BOOL _mouse_in_favourite;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithFrame:(NSRect)frameRect
{
    if (self = [super initWithFrame:frameRect])
    {
        _drag_types = [NSArray arrayWithObjects:NSFilenamesPboardType, nil];
        _mouse_in_favourite = NO;
        [self registerForDraggedTypes:_drag_types];
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSBezierPath* bg = [NSBezierPath bezierPathWithRoundedRect:self.bounds
                                                       xRadius:15.0
                                                       yRadius:15.0];
    [IA_RGBA_COLOUR(127.5, 127.5, 127.5, 0.05) set];
    [bg fill];
}

- (void)setDelegate:(id<IAFavouritesViewProtocol>)delegate
{
    _delegate = delegate;
}

- (NSString*)description
{
    return @"[FavouritesView]";
}

//- Dragging Functions -----------------------------------------------------------------------------

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    NSPasteboard* paste_board = sender.draggingPasteboard;
    if ([paste_board availableTypeFromArray:_drag_types])
    {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        return NSDragOperationCopy;
    }
    return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
    NSPasteboard* paste_board = sender.draggingPasteboard;
    if (![paste_board availableTypeFromArray:_drag_types])
        return NO;
    
    NSArray* files = [paste_board propertyListForType:NSFilenamesPboardType];
    
    if (files.count > 0)
    {
        [_delegate favouritesView:self
                    gotDropOnUser:nil
                        withFiles:files];
    }
    
    return YES;
}

- (void)dragLost
{
    [_delegate favouritesViewHadDragExit:self];
}

- (void)draggingExited:(id<NSDraggingInfo>)sender
{
    if (!_mouse_in_favourite)
    {
        [self performSelector:@selector(dragLost) withObject:nil afterDelay:0.5];
    }
}

- (void)draggingEnded:(id<NSDraggingInfo>)sender
{
    [self dragLost];
}

//- Favourite View Protocol ------------------------------------------------------------------------

- (void)favouriteView:(IAFavouriteView*)sender
             gotFiles:(NSArray*)files
{
    [_delegate favouritesView:self gotDropOnUser:sender.user withFiles:files];
}

- (void)favouriteViewGotDragEnter:(IAFavouriteView*)sender
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    _mouse_in_favourite = YES;
}

- (void)favouriteViewGotDragExit:(IAFavouriteView*)sender
{
    [self performSelector:@selector(dragLost) withObject:nil afterDelay:0.5];
    _mouse_in_favourite = NO;
}

@end
