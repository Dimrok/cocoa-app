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
  // WORKAROUND: 10.7 doesn't allow weak references to certain classes (like NSViewController)
  __unsafe_unretained id<IAFavouritesViewProtocol> _delegate;
  BOOL _mouse_in_favourite;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithFrame:(NSRect)frameRect
{
  if (self = [super initWithFrame:frameRect])
  {
    _mouse_in_favourite = NO;
    [self performSelector:@selector(dragLost) withObject:nil afterDelay:3.0];
  }
  return self;
}

- (void)dealloc
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (BOOL)isOpaque
{
  return NO;
}

- (void)setDelegate:(id<IAFavouritesViewProtocol>)delegate
{
  _delegate = delegate;
}

//- Dragging Functions -----------------------------------------------------------------------------

- (void)dragLost
{
  if (_delegate)
    [_delegate favouritesViewHadDragExit:self];
}

- (void)resetTimeout
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  [self performSelector:@selector(dragLost) withObject:nil afterDelay:3.0];
}

//- Favourite View Protocol ------------------------------------------------------------------------

- (void)favouriteView:(IAFavouriteView*)sender
             gotFiles:(NSArray*)files
{
  [_delegate favouriteView:sender gotDropOnUser:sender.user withFiles:files];
}

- (void)favouriteViewGotDragEnter:(IAFavouriteView*)sender
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  _mouse_in_favourite = YES;
}

- (void)favouriteViewGotDragExit:(IAFavouriteView*)sender
{
  [self performSelector:@selector(dragLost) withObject:nil afterDelay:2.0];
  _mouse_in_favourite = NO;
}

//- Link View Protocol -----------------------------------------------------------------------------

- (void)linkView:(InfinitLinkShortcutView*)sender
        gotFiles:(NSArray*)files
{
  [_delegate linkViewGotDrop:sender withFiles:files];
}

- (void)linkViewGotDragEnter:(IAFavouriteView*)sender
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  _mouse_in_favourite = YES;
}

- (void)linkViewGotDragExit:(IAFavouriteView*)sender
{
  [self performSelector:@selector(dragLost) withObject:nil afterDelay:2.0];
  _mouse_in_favourite = NO;
}

@end
