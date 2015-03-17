//
//  IAFavouritesViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 8/13/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAViewController.h"

#import "IAFavouriteView.h"
#import "IAFavouritesView.h"
#import "InfinitLinkShortcutView.h"

@protocol IAFavouritesSendViewProtocol;

@interface IAFavouritesSendViewController : NSViewController <IAFavouritesViewProtocol,
                                                              NSWindowDelegate>

@property (nonatomic, weak) IBOutlet IAFavouritesView* favourites_view;
@property (nonatomic) BOOL open;

- (id)initWithDelegate:(id<IAFavouritesSendViewProtocol>)delegate;

- (void)setDelegate:(id<IAFavouritesSendViewProtocol>)delegate;

- (void)hideFavourites;
- (void)showFavourites;

- (void)resetTimeout;

@end


@protocol IAFavouritesSendViewProtocol <NSObject>

- (NSPoint)favouritesViewWantsMidpoint:(IAFavouritesSendViewController*)sender;

- (void)favouritesView:(IAFavouritesSendViewController*)sender
         gotDropOnUser:(InfinitUser*)user
             withFiles:(NSArray*)files;

- (void)favouritesView:(IAFavouritesSendViewController*)sender
  gotDropLinkWithFiles:(NSArray*)files;

- (void)favouritesViewWantsClose:(IAFavouritesSendViewController*)sender;

@end
