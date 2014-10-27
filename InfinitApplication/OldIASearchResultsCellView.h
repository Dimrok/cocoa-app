//
//  OldIASearchResultsCellView.h
//  InfinitApplication
//
//  Created by Christopher Crone on 8/4/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface OldInfinitSelectedBoxView : NSView
@property (nonatomic, readwrite) BOOL selected;
@property (nonatomic, readwrite) BOOL hover;
@end

@protocol OldIASearchResultsCellProtocol;

@interface OldIASearchResultsCellView : NSTableCellView

@property (nonatomic, weak) IBOutlet NSImageView* result_avatar;
@property (nonatomic, weak) IBOutlet NSTextField* result_fullname;
@property (nonatomic, weak) IBOutlet NSButton* result_star;
@property (nonatomic, weak) IBOutlet OldInfinitSelectedBoxView* result_selected;
@property (nonatomic, readwrite) BOOL selected;
@property (nonatomic, readwrite) BOOL hover;

- (void)setDelegate:(id<OldIASearchResultsCellProtocol>)delegate;
- (void)setUserAvatar:(NSImage*)image;
- (void)setUserFavourite:(BOOL)favourite;
- (void)setUserFullname:(NSString*)fullname
             withDomain:(NSString*)domain;

@end

@protocol OldIASearchResultsCellProtocol <NSObject>

- (void)searchResultCell:(OldIASearchResultsCellView*)sender
                gotHover:(BOOL)hover;
- (void)searchResultCell:(OldIASearchResultsCellView*)sender
             gotSelected:(BOOL)selected;

- (void)searchResultCellWantsAddFavourite:(OldIASearchResultsCellView*)sender;
- (void)searchResultCellWantsRemoveFavourite:(OldIASearchResultsCellView*)sender;

@end
