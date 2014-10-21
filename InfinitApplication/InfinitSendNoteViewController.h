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
@end

//- Controller -------------------------------------------------------------------------------------

@protocol InfinitSendNoteViewProtocol;

@interface InfinitSendNoteViewController : NSViewController <InfinitSendNoteProtocol>

@property (nonatomic, weak) IBOutlet NSTextField* note_field;
@property (nonatomic, weak) IBOutlet NSTextField* characters_label;

- (id)initWithDelegate:(id<InfinitSendNoteViewProtocol>)delegate;

- (NSString*)note;

@end

@protocol InfinitSendNoteViewProtocol <NSObject>

- (void)noteViewWantsLoseFocus:(InfinitSendNoteViewController*)sender;
- (void)noteViewGotFocus:(InfinitSendNoteViewController*)sender;

- (void)noteView:(InfinitSendNoteViewController*)sender
 gotFilesDropped:(NSArray*)files;

@end
