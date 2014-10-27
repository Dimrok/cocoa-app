//
//  OldInfinitSendNoteViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 10/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//- Note Field -------------------------------------------------------------------------------------

@protocol OldInfinitSendNoteProtocol;

@interface OldInfinitSendNoteField : NSTextField
@end

@protocol OldInfinitSendNoteProtocol <NSTextFieldDelegate>
- (void)gotFocus:(OldInfinitSendNoteField*)sender;
- (void)changedHeightBy:(CGFloat)diff;
@end

//- Controller -------------------------------------------------------------------------------------

@protocol OldInfinitSendNoteViewProtocol;

@interface OldInfinitSendNoteViewController : NSViewController <OldInfinitSendNoteProtocol>

@property (nonatomic, weak) IBOutlet NSTextField* note_field;
@property (nonatomic, weak) IBOutlet NSTextField* characters_label;
@property (nonatomic, readwrite) BOOL link_mode;

- (id)initWithDelegate:(id<OldInfinitSendNoteViewProtocol>)delegate;

- (NSString*)note;

@end

@protocol OldInfinitSendNoteViewProtocol <NSObject>

- (void)noteViewWantsLoseFocus:(OldInfinitSendNoteViewController*)sender;

- (void)noteView:(OldInfinitSendNoteViewController*)sender
     wantsHeight:(CGFloat)height;

- (void)noteView:(OldInfinitSendNoteViewController*)sender
 gotFilesDropped:(NSArray*)files;

@end
