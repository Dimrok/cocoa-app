//
//  InfinitSendNoteViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 10/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//- Header View ------------------------------------------------------------------------------------

@protocol InfinitSendNoteHeaderViewProtocol;

@interface InfinitSendNoteHeaderView : NSView
@property (nonatomic, strong) IBOutlet NSImageView* show_note;
@property (nonatomic, strong) IBOutlet NSImageView* note_icon;
@property (nonatomic, strong) IBOutlet NSTextField* message;
@property (nonatomic, readwrite) BOOL open;
@property (nonatomic, readwrite) BOOL link_mode;
- (void)setDelegate:(id<InfinitSendNoteHeaderViewProtocol>)delegate;
@end

//- View -------------------------------------------------------------------------------------------

@protocol InfinitSendNoteHeaderViewProtocol <NSObject>
- (void)noteHeaderGotClick:(InfinitSendNoteHeaderView*)sender;
@end


@interface InfinitSendNoteView : NSView
@property (nonatomic, readwrite) BOOL open;
@property (nonatomic) IBOutlet InfinitSendNoteHeaderView* header_view;
@property (nonatomic) IBOutlet NSTextField* note_field;

@end

//- Controller -------------------------------------------------------------------------------------

@protocol InfinitSendNoteViewProtocol;

@interface InfinitSendNoteViewController : NSViewController <NSTextViewDelegate,
                                                             InfinitSendNoteHeaderViewProtocol>

@property (nonatomic, strong) IBOutlet InfinitSendNoteHeaderView* header_view;
@property (nonatomic, strong) IBOutlet NSTextField* note_field;
@property (nonatomic, strong) IBOutlet NSTextField* characters_label;
@property (nonatomic, readwrite) BOOL open;
@property (nonatomic, readwrite) BOOL link_mode;
@property (nonatomic, readonly) CGFloat height;

- (id)initWithDelegate:(id<InfinitSendNoteViewProtocol>)delegate;

- (NSString*)note;

@end

@protocol InfinitSendNoteViewProtocol <NSObject>

- (void)noteViewWantsShow:(InfinitSendNoteViewController*)sender;
- (void)noteViewWantsHide:(InfinitSendNoteViewController*)sender;

- (void)noteViewWantsLoseFocus:(InfinitSendNoteViewController*)sender;

@end
