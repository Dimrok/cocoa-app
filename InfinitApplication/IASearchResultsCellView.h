//
//  IASearchResultsCellView.h
//  InfinitApplication
//
//  Created by Christopher Crone on 8/4/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol IASearchResultsCellProtocol;

@interface IASearchResultsCellView : NSTableCellView

@property (nonatomic, strong) IBOutlet NSImageView* result_avatar;
@property (nonatomic, strong) IBOutlet NSTextField* result_email;
@property (nonatomic, strong) IBOutlet NSTextField* result_fullname;
@property (nonatomic, strong) IBOutlet NSTextField* result_handle;
@property (nonatomic, strong) IBOutlet NSButton* result_star;

- (void)setDelegate:(id<IASearchResultsCellProtocol>)delegate;
- (void)setUserAvatar:(NSImage*)image;
- (void)setUserEmail:(NSString*)email;
- (void)setUserHandle:(NSString*)handle;
- (void)setUserFavourite:(BOOL)favourite;
- (void)setUserFullname:(NSString*)fullname;

@end

@protocol IASearchResultsCellProtocol <NSObject>

- (void)searchResultCellWantsAddFavourite:(IASearchResultsCellView*)sender;

- (void)searchResultCellWantsRemoveFavourite:(IASearchResultsCellView*)sender;

@end
