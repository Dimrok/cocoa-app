//
//  InfinitSendNoteViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 10/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//- Note Field -------------------------------------------------------------------------------------

@protocol InfinitSendNoteProtocol;

@interface InfinitSendNoteField : NSTextField
@end

@protocol InfinitSendNoteProtocol <NSTextFieldDelegate>
- (void)gotFocus:(InfinitSendNoteField*)sender;
- (void)changedHeightBy:(CGFloat)diff;
@end

//- Controller -------------------------------------------------------------------------------------

@protocol InfinitSendNoteViewProtocol;

@interface InfinitSendNoteViewController : NSViewController <InfinitSendNoteProtocol>

@property (nonatomic, strong) IBOutlet NSTextField* note_field;
@property (nonatomic, strong) IBOutlet NSTextField* characters_label;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* note_height;

- (id)initWithDelegate:(id<InfinitSendNoteViewProtocol>)delegate;

- (NSString*)note;

@end

@protocol InfinitSendNoteViewProtocol <NSObject>

- (void)noteViewWantsLoseFocus:(InfinitSendNoteViewController*)sender;

- (void)noteView:(InfinitSendNoteViewController*)sender
     wantsHeight:(CGFloat)height;

@end
