//
//  InfinitSearchResultCell.h
//  InfinitApplication
//
//  Created by Christopher Crone on 8/4/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "InfinitSearchRowModel.h"

@protocol InfinitSearchResultCellProtocol;

@interface InfinitSearchResultCell : NSTableCellView

@property (nonatomic, unsafe_unretained, readwrite) id<InfinitSearchResultCellProtocol> delegate;
@property (nonatomic, readwrite) BOOL hover;
@property (nonatomic, readwrite) InfinitSearchRowModel* model;

@end

@protocol InfinitSearchResultCellProtocol <NSObject>

- (void)searchResultCell:(InfinitSearchResultCell*)sender
                gotHover:(BOOL)hover;
- (void)searchResultCellGotSelected:(InfinitSearchResultCell*)sender;

@end
