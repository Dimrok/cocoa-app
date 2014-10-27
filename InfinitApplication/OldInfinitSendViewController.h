//
//  OldInfinitSendViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 10/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "IAViewController.h"

#import "InfinitSendViewController.h"

#import "OldIAUserSearchViewController.h"
#import "OldInfinitSendNoteViewController.h"
#import "OldInfinitSendFilesViewController.h"

//- User Link View ---------------------------------------------------------------------------------

@protocol OldInfinitSendUserLinkProtocol;

@interface OldInfinitSendUserLinkView : NSView
@property (nonatomic, weak) IBOutlet NSTextField* user_text;
@property (nonatomic, weak) IBOutlet NSTextField* link_text;
@property (nonatomic, readwrite) InfinitUserLinkMode mode;
@property (nonatomic, readwrite) CGFloat animate_mode;

- (void)setDelegate:(id<OldInfinitSendUserLinkProtocol>)delegate;
- (void)setupViewForMode:(InfinitUserLinkMode)mode;

@end

@protocol OldInfinitSendUserLinkProtocol <NSObject>
- (void)gotUserClick:(OldInfinitSendUserLinkView*)sender;
- (void)gotLinkClick:(OldInfinitSendUserLinkView*)sender;
@end

//- View -------------------------------------------------------------------------------------------

@protocol OldInfinitSendDropViewProtocol;

@interface OldInfinitSendDropView : NSView <NSDraggingDestination>
@property (nonatomic, readwrite, assign) id<OldInfinitSendDropViewProtocol> delegate;
@end

@protocol OldInfinitSendDropViewProtocol <NSObject>
- (void)gotDroppedFiles:(NSArray*)files;
@end

//- Controller -------------------------------------------------------------------------------------

@interface OldInfinitSendViewController : IAViewController <OldIAUserSearchViewProtocol,
                                                            OldInfinitSendDropViewProtocol,
                                                            OldInfinitSendNoteViewProtocol,
                                                            OldInfinitSendFilesViewProtocol,
                                                            OldInfinitSendUserLinkProtocol>

@property (nonatomic, weak) IBOutlet OldInfinitSendUserLinkView* user_link_view;
@property (nonatomic, weak) IBOutlet OldInfinitSendDropView* drop_view;
@property (nonatomic, weak) IBOutlet NSView* search_view;
@property (nonatomic, weak) IBOutlet NSView* note_view;
@property (nonatomic, weak) IBOutlet NSView* files_view;
@property (nonatomic, weak) IBOutlet NSButton* send_button;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* search_constraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* note_constraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* files_constraint;

- (id)initWithDelegate:(id<InfinitSendViewProtocol>)delegate
  withSearchController:(OldIAUserSearchViewController*)search_controller
               forLink:(BOOL)for_link;

- (void)filesUpdated;

@end
