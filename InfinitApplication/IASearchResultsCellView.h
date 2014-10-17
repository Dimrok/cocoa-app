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

@property (nonatomic, weak) IBOutlet NSImageView* result_avatar;
@property (nonatomic, weak) IBOutlet NSTextField* result_fullname;
@property (nonatomic, readwrite) BOOL hover;

- (void)setDelegate:(id<IASearchResultsCellProtocol>)delegate;
- (void)setUserAvatar:(NSImage*)image;
- (void)setUserFullname:(NSString*)fullname
              withEmail:(NSString*)email;

@end

@protocol IASearchResultsCellProtocol <NSObject>

- (void)searchResultCell:(IASearchResultsCellView*)sender
                gotHover:(BOOL)hover;
- (void)searchResultCellGotSelected:(IASearchResultsCellView*)sender;

@end
