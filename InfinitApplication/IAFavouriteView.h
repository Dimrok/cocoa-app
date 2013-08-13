//
//  IAFavouriteView.h
//  InfinitApplication
//
//  Created by Christopher Crone on 8/13/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol IAFavouriteViewProtocol;

@interface IAFavouriteView : NSView

@property (nonatomic, readonly) IAUser* user;

- (id)initWithFrame:(NSRect)frameRect
        andDelegate:(id<IAFavouriteViewProtocol>)delegate
            andUser:(IAUser*)user;

@end


@protocol IAFavouriteViewProtocol <NSObject>

- (void)favouriteView:(IAFavouriteView*)sender
             gotFiles:(NSArray*)files;

@end