//
//  IAFavouritesViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 8/13/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAViewController.h"

@protocol IAFavouritesSendViewProtocol;

@interface IAFavouritesSendViewController : NSViewController <NSWindowDelegate>

- (id)initWithDelegate:(id<IAFavouritesSendViewProtocol>)delegate;
- (void)showFavourites;

@end


@protocol IAFavouritesSendViewProtocol <NSObject>

- (NSArray*)favouritesViewWantsFavourites:(IAFavouritesSendViewController*)sender;

- (NSPoint)favouritesViewWantsMidpoint:(IAFavouritesSendViewController*)sender;

@end
