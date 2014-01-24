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

@protocol IAFavouritesSendViewProtocol;

@interface IAFavouritesSendViewController : NSViewController <IAFavouritesViewProtocol,
                                                              NSWindowDelegate>

@property (nonatomic, strong) IBOutlet IAFavouritesView* favourites_view;

- (id)initWithDelegate:(id<IAFavouritesSendViewProtocol>)delegate;

- (void)hideFavourites;
- (void)showFavourites;

@end


@protocol IAFavouritesSendViewProtocol <NSObject>

- (NSArray*)favouritesViewWantsFavourites:(IAFavouritesSendViewController*)sender;

- (NSArray*)favouritesViewWantsSwaggers:(IAFavouritesSendViewController*)sender;

- (IAUser*)favouritesViewWantsInfinitUser:(IAFavouritesSendViewController*)sender;

- (NSPoint)favouritesViewWantsMidpoint:(IAFavouritesSendViewController*)sender;

- (void)favouritesView:(IAFavouritesSendViewController*)sender
         gotDropOnUser:(IAUser*)user
             withFiles:(NSArray*)files;

- (void)favouritesViewWantsClose:(IAFavouritesSendViewController*)sender;

@end
