//
//  IASearchResultsCellView.h
//  InfinitApplication
//
//  Created by Christopher Crone on 8/4/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface InfinitSelectedBoxView : NSView
@property (nonatomic, readwrite) BOOL selected;
@property (nonatomic, readwrite) BOOL hover;
@end

@protocol IASearchResultsCellProtocol;

@interface IASearchResultsCellView : NSTableCellView

@property (nonatomic, weak) IBOutlet NSImageView* result_avatar;
@property (nonatomic, weak) IBOutlet NSTextField* result_fullname;
@property (nonatomic, weak) IBOutlet NSButton* result_star;
@property (nonatomic, weak) IBOutlet InfinitSelectedBoxView* result_selected;
@property (nonatomic, readwrite) BOOL selected;
@property (nonatomic, readwrite) BOOL hover;

- (void)setDelegate:(id<IASearchResultsCellProtocol>)delegate;
- (void)setUserAvatar:(NSImage*)image;
- (void)setUserFavourite:(BOOL)favourite;
- (void)setUserFullname:(NSString*)fullname
             withDomain:(NSString*)domain;

@end

@protocol IASearchResultsCellProtocol <NSObject>

- (void)searchResultCell:(IASearchResultsCellView*)sender
                gotHover:(BOOL)hover;
- (void)searchResultCell:(IASearchResultsCellView*)sender
             gotSelected:(BOOL)selected;

- (void)searchResultCellWantsAddFavourite:(IASearchResultsCellView*)sender;
- (void)searchResultCellWantsRemoveFavourite:(IASearchResultsCellView*)sender;

@end
