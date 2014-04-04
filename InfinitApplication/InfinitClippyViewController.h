//
//  InfinitClippyViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 02/04/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "IAViewController.h"

typedef enum __InfinitClippyMode
{
  INFINIT_CLIPPY_TRANSFER_PENDING,
  INFINIT_CLIPPY_DRAG_AND_DROP,
  INFINIT_CLIPPY_HIGHER,
} InfinitClippyMode;

@class InfinitClippyView;

@protocol InfinitClippyProtocol;
@protocol InfinitClippyViewProtocol;

@interface InfinitClippyViewController : IAViewController <InfinitClippyViewProtocol>

@property (nonatomic, strong) IBOutlet NSButton* done_button;
@property (nonatomic, strong) IBOutlet NSImageView* clippy_image;
@property (nonatomic, strong) IBOutlet NSTextField* line_1;
@property (nonatomic, strong) IBOutlet NSTextField* line_2;
@property (nonatomic, strong) IBOutlet NSTextField* line_3;
@property (nonatomic, strong) IBOutlet InfinitClippyView* clippy_view;


@property (nonatomic, readonly) InfinitClippyMode mode;

- (id)initWithDelegate:(id<InfinitClippyProtocol>)delegate
               andMode:(InfinitClippyMode)mode;

@end

@protocol InfinitClippyProtocol <NSObject>

- (void)clippyViewGotDoneClicked:(InfinitClippyViewController*)sender;

@end
