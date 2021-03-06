//
//  InfinitSendViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 10/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "IAViewController.h"

#import "IAUserSearchViewController.h"
#import "InfinitSendNoteViewController.h"
#import "InfinitSendFilesViewController.h"

//- User Link View ---------------------------------------------------------------------------------

typedef enum _InfinitUserLinkMode
{
  INFINIT_USER_MODE,
  INFINIT_LINK_MODE,
} InfinitUserLinkMode;

@protocol InfinitSendUserLinkProtocol;

@interface InfinitSendUserLinkView : NSView
@property (nonatomic, weak) IBOutlet NSTextField* user_text;
@property (nonatomic, weak) IBOutlet NSTextField* link_text;
@property (nonatomic, readwrite) InfinitUserLinkMode mode;
@property (nonatomic, readwrite) CGFloat animate_mode;

- (void)setDelegate:(id<InfinitSendUserLinkProtocol>)delegate;
- (void)setupViewForMode:(InfinitUserLinkMode)mode;

@end

@protocol InfinitSendUserLinkProtocol <NSObject>
- (void)gotUserClick:(InfinitSendUserLinkView*)sender;
- (void)gotLinkClick:(InfinitSendUserLinkView*)sender;
@end

//- Infinit Send Button Cell -----------------------------------------------------------------------

@interface InfinitSendButtonCell : NSButtonCell
@property (nonatomic, readwrite) NSDictionary* disabled_attrs;
@end

//- Controller -------------------------------------------------------------------------------------

@protocol InfinitSendViewProtocol;

@interface InfinitSendViewController : IAViewController <IAUserSearchViewProtocol,
                                                         InfinitSendNoteViewProtocol,
                                                         InfinitSendFilesViewProtocol,
                                                         InfinitSendUserLinkProtocol>

@property (nonatomic, weak) IBOutlet InfinitSendUserLinkView* user_link_view;
@property (nonatomic, weak) IBOutlet NSView* search_view;
@property (nonatomic, weak) IBOutlet NSView* note_view;
@property (nonatomic, weak) IBOutlet NSView* files_view;
@property (nonatomic, weak) IBOutlet NSButton* send_button;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* button_width;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* search_constraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* search_note_contraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* note_constraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* files_constraint;

- (id)initWithDelegate:(id<InfinitSendViewProtocol>)delegate
  withSearchController:(IAUserSearchViewController*)search_controller
               forLink:(BOOL)for_link;

- (void)filesUpdated;

@end

@protocol InfinitSendViewProtocol <NSObject>

- (NSArray*)sendViewWantsFileList:(id)sender;

- (void)sendViewWantsCancel:(id)sender;
- (void)sendViewWantsClose:(id)sender;

- (void)sendView:(id)sender
wantsRemoveFileAtIndex:(NSInteger)index;

- (void)sendViewWantsOpenFileDialogBox:(id)sender;

- (NSArray*)sendView:(id)sender
      wantsSendFiles:(NSArray*)files
             toUsers:(NSArray*)users
         withMessage:(NSString*)message;

- (NSNumber*)sendView:(id)sender
      wantsCreateLink:(NSArray*)files
          withMessage:(NSString*)message;

- (void)sendView:(id)sender
 hadFilesDropped:(NSArray*)files;

@end
