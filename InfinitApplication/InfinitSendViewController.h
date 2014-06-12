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

//- View -------------------------------------------------------------------------------------------

@protocol InfinitSendDropViewProtocol;

@interface InfinitSendDropView : NSView <NSDraggingDestination>
@property (nonatomic, readwrite, weak) id<InfinitSendDropViewProtocol> delegate;
@end

@protocol InfinitSendDropViewProtocol <NSObject>
- (void)gotDroppedFiles:(NSArray*)files;
@end

//- Controller -------------------------------------------------------------------------------------

@protocol InfinitSendViewProtocol;

@interface InfinitSendViewController : IAViewController <IAUserSearchViewProtocol,
                                                         InfinitSendDropViewProtocol,
                                                         InfinitSendNoteViewProtocol,
                                                         InfinitSendFilesViewProtocol,
                                                         InfinitSendUserLinkProtocol>

@property (nonatomic, weak) IBOutlet InfinitSendUserLinkView* user_link_view;
@property (nonatomic, weak) IBOutlet InfinitSendDropView* drop_view;
@property (nonatomic, weak) IBOutlet NSView* search_view;
@property (nonatomic, weak) IBOutlet NSView* note_view;
@property (nonatomic, weak) IBOutlet NSView* files_view;
@property (nonatomic, weak) IBOutlet NSButton* send_button;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* search_constraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* note_constraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* files_constraint;

- (id)initWithDelegate:(id<InfinitSendViewProtocol>)delegate
  withSearchController:(IAUserSearchViewController*)search_controller
               forLink:(BOOL)for_link;

- (void)filesUpdated;

@end

@protocol InfinitSendViewProtocol <IAViewProtocol>

- (NSArray*)sendViewWantsFileList:(InfinitSendViewController*)sender;

- (void)sendViewWantsCancel:(InfinitSendViewController*)sender;

- (void)sendView:(InfinitSendViewController*)sender
wantsRemoveFileAtIndex:(NSInteger)index;

- (void)sendViewWantsOpenFileDialogBox:(InfinitSendViewController*)sender;

- (NSArray*)sendView:(InfinitSendViewController*)sender
      wantsSendFiles:(NSArray*)files
             toUsers:(NSArray*)users
         withMessage:(NSString*)message;

- (NSNumber*)sendView:(InfinitSendViewController*)sender
      wantsCreateLink:(NSArray*)files
          withMessage:(NSString*)message;

- (void)sendView:(InfinitSendViewController*)sender
wantsAddFavourite:(IAUser*)user;

- (void)sendView:(InfinitSendViewController*)sender
wantsRemoveFavourite:(IAUser*)user;

- (void)sendView:(InfinitSendViewController*)sender
 hadFilesDropped:(NSArray*)files;

- (NSArray*)sendViewWantsFriendsByLastInteraction:(InfinitSendViewController*)sender;

//- Onboarding -------------------------------------------------------------------------------------

- (void)sendView:(InfinitSendViewController*)sender
wantsSetOnboardingSendTransactionId:(NSNumber*)transaction_id;

@end
