//
//  IAFavouritesView.h
//  InfinitApplication
//
//  Created by Christopher Crone on 8/14/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IAFavouriteView.h"
#import "InfinitLinkShortcutView.h"

@protocol IAFavouritesViewProtocol;

@interface IAFavouritesView : NSView <IAFavouriteViewProtocol,
                                      InfinitLinkShortcutViewProtocol>

- (id)initWithFrame:(NSRect)frameRect;

- (void)setDelegate:(id<IAFavouritesViewProtocol>)delegate;

- (void)resetTimeout;

@end


@protocol IAFavouritesViewProtocol <NSObject>

- (void)favouritesViewHadDragExit:(IAFavouritesView*)sender;
- (void)favouritesView:(IAFavouritesView*)sender
         gotDropOnUser:(IAUser*)user
             withFiles:(NSArray*)files;
- (void)linkViewGotDrop:(InfinitLinkShortcutView*)sender
              withFiles:(NSArray*)files;

@end