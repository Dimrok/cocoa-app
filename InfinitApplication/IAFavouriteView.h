//
//  IAFavouriteView.h
//  InfinitApplication
//
//  Created by Christopher Crone on 8/13/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <Gap/InfinitUser.h>

@protocol IAFavouriteViewProtocol;

@interface IAFavouriteView : NSView <NSDraggingDestination>

@property (nonatomic, readonly) InfinitUser* user;

- (id)initWithFrame:(NSRect)frameRect
        andDelegate:(id<IAFavouriteViewProtocol>)delegate
            andUser:(InfinitUser*)user;

@end


@protocol IAFavouriteViewProtocol <NSObject>

- (void)favouriteView:(IAFavouriteView*)sender
             gotFiles:(NSArray*)files;

- (void)favouriteViewGotDragEnter:(IAFavouriteView*)sender;
- (void)favouriteViewGotDragExit:(IAFavouriteView*)sender;

@end