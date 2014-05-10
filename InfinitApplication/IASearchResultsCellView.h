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

@property (nonatomic, strong) IBOutlet NSImageView* result_avatar;
@property (nonatomic, strong) IBOutlet NSTextField* result_email;
@property (nonatomic, strong) IBOutlet NSTextField* result_fullname;
@property (nonatomic, strong) IBOutlet NSTextField* result_handle;
@property (nonatomic, strong) IBOutlet NSButton* result_star;
@property (nonatomic, strong) IBOutlet InfinitSelectedBoxView* result_selected;
@property (nonatomic, readwrite) BOOL selected;
@property (nonatomic, readwrite) BOOL hover;

- (void)setDelegate:(id<IASearchResultsCellProtocol>)delegate;
- (void)setUserAvatar:(NSImage*)image;
- (void)setUserEmail:(NSString*)email;
- (void)setUserHandle:(NSString*)handle;
- (void)setUserFavourite:(BOOL)favourite;
- (void)setUserFullname:(NSString*)fullname;

@end

@protocol IASearchResultsCellProtocol <NSObject>

- (void)searchResultCell:(IASearchResultsCellView*)sender
                gotHover:(BOOL)hover;
- (void)searchResultCell:(IASearchResultsCellView*)sender
             gotSelected:(BOOL)selected;

- (void)searchResultCellWantsAddFavourite:(IASearchResultsCellView*)sender;
- (void)searchResultCellWantsRemoveFavourite:(IASearchResultsCellView*)sender;

@end
