//
//  InfinitLinkViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 13/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "InfinitLinkCellView.h"

@protocol InfinitLinkViewProtocol;

@interface InfinitLinkViewController : NSViewController

@property (nonatomic, readwrite) BOOL changing;
@property (nonatomic, readonly) CGFloat height;
@property (nonatomic, readonly) NSUInteger links_running;

- (id)initWithDelegate:(id<InfinitLinkViewProtocol>)delegate;

- (void)updateModel;
- (void)scrollToTop;

- (void)linkAdded:(InfinitLinkTransaction*)link;
- (void)linkUpdated:(InfinitLinkTransaction*)link;

- (void)resizeComplete;

@end

@protocol InfinitLinkViewProtocol <NSObject>

- (void)copyLinkToPasteBoard:(InfinitLinkTransaction*)link;
- (void)linksViewResizeToHeight:(CGFloat)height;

@end
