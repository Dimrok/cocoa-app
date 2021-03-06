//
//  InfinitLinkCellView.h
//  InfinitApplication
//
//  Created by Christopher Crone on 13/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <Gap/InfinitLinkTransaction.h>

#import "IAHoverButton.h"
#import "InfinitLinkProgressIndicator.h"
#import "InfinitLinkClickCountView.h"
#import "InfinitLinkFileIconView.h"

@protocol InfinitLinkCellProtocol;

@interface InfinitLinkBlurView : NSView
@end

@interface InfinitLinkCellView : NSTableCellView

@property (nonatomic, weak) IBOutlet IAHoverButton* delete_link;

@property (nonatomic) NSUInteger delete_clicks;

@property (nonatomic, readwrite) CGFloat progress;

- (void)setupCellWithLink:(InfinitLinkTransaction*)link
              andDelegate:(id<InfinitLinkCellProtocol>)delegate
         withOnlineStatus:(BOOL)status;

- (void)hideControls;

- (void)checkMouseInside;

@end

@protocol InfinitLinkCellProtocol <NSObject>

- (void)linkCell:(InfinitLinkCellView*)sender
gotCopyToClipboardForLink:(InfinitLinkTransaction*)link;

- (void)linkCell:(InfinitLinkCellView*)sender
gotCancelForLink:(InfinitLinkTransaction*)link;

- (void)linkCell:(InfinitLinkCellView*)sender
gotDeleteForLink:(InfinitLinkTransaction*)link;

- (void)linkCellLostMouseHover:(InfinitLinkCellView*)sender;

- (BOOL)userScrolling:(InfinitLinkCellView*)sender;

@end
