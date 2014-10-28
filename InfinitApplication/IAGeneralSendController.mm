//
//  IAGeneralSendController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/2/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAGeneralSendController.h"

#import "InfinitFeatureManager.h"
#import "OldInfinitSendViewController.h"

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("OSX.GeneralSendController");

@implementation IAGeneralSendController
{
@private
  // Delegate
  __weak id<IAGeneralSendControllerProtocol> _delegate;
  
  // Send views
  IAFavouritesSendViewController* _favourites_send_controller;
  InfinitSendViewController* _send_controller;
  OldInfinitSendViewController* _old_send_controller;

  // Search Controller
  IAUserSearchViewController* _user_search_controller;
  // Old Search Controller
  OldIAUserSearchViewController* _old_user_search_controller;

  NSMutableArray* _files;
  BOOL _send_view_open;
  BOOL _new_send_view;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithDelegate:(id<IAGeneralSendControllerProtocol>)delegate
{
  if (self = [super init])
  {
    _delegate = delegate;
    _files = [NSMutableArray array];
    _send_view_open = NO;
    if ([[[[InfinitFeatureManager sharedInstance] features] valueForKey:@"send_view_20141027"] isEqualToString:@"a"])
      _new_send_view = YES;
    else
      _new_send_view = NO;
    ELLE_TRACE("%s: using %s send view", self.description.UTF8String, _new_send_view ? "new" : "old");
  }
  return self;
}

- (void)dealloc
{
  [_user_search_controller setDelegate:nil];
  _user_search_controller = nil;
  [_old_user_search_controller setDelegate:nil];
  _old_user_search_controller = nil;
  [_favourites_send_controller hideFavourites];
  [_favourites_send_controller setDelegate:nil];
  _favourites_send_controller = nil;
  _send_controller = nil;
}

//- General Functions ------------------------------------------------------------------------------

- (void)filesOverStatusBarIcon
{
  if (_favourites_send_controller != nil && _favourites_send_controller.open)
  {
    [_favourites_send_controller resetTimeout];
  }
  else
  {
    [self cancelOpenFavourites];
    [self showFavourites];
  }
}

- (void)cancelOpenFavourites
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)openFileDialogForView:(id)sender
{
  if (sender != _send_controller && sender != _old_send_controller)
    return;
  
  ELLE_TRACE("%s: open file diaglog for: %s", self.description.UTF8String,
             [sender description].UTF8String);
  
  NSOpenPanel* file_dialog = [NSOpenPanel openPanel];
  file_dialog.canChooseFiles = YES;
  file_dialog.canChooseDirectories = YES;
  file_dialog.allowsMultipleSelection = YES;
  
  if ([file_dialog runModal] == NSOKButton)
  {
    NSArray* dialog_files = [file_dialog URLs];
    for (NSURL* file_url in dialog_files)
    {
      if (![_files containsObject:[file_url path]])
        [_files addObject:[file_url path]];
    }
  }
  [sender filesUpdated];
}

//- Open Functions ---------------------------------------------------------------------------------

- (void)openWithNoFileForLink:(BOOL)for_link
{
  _send_view_open = YES;
  [_favourites_send_controller hideFavourites];
  if (_new_send_view)
  {
    _user_search_controller = [[IAUserSearchViewController alloc] init];
    _send_controller =
      [[InfinitSendViewController alloc] initWithDelegate:self
                                     withSearchController:_user_search_controller
                                                  forLink:for_link];
    [_delegate sendController:self wantsActiveController:_send_controller];
  }
  else
  {
    _old_user_search_controller = [[OldIAUserSearchViewController alloc] init];
    _old_send_controller =
      [[OldInfinitSendViewController alloc] initWithDelegate:self
                                        withSearchController:_old_user_search_controller
                                                     forLink:for_link];
    [_delegate sendController:self wantsActiveController:_old_send_controller];
  }
}

- (void)openWithFiles:(NSArray*)files
              forUser:(IAUser*)user
{
  if (user != nil)
  {
    ELLE_TRACE("%s: open send view for user: %s", self.description.UTF8String,
               user.fullname.UTF8String);
  }
  else
  {
    ELLE_TRACE("%s: open send view for no user", self.description.UTF8String);
  }
  _send_view_open = YES;
  [self cancelOpenFavourites];
  if (_favourites_send_controller.open)
    [_favourites_send_controller hideFavourites];
  for (NSString* file in files)
  {
    if (![_files containsObject:file])
      [_files addObject:file];
  }
  if (_send_controller == nil)
  {
    if (_new_send_view)
    {
      if (_user_search_controller == nil)
        _user_search_controller = [[IAUserSearchViewController alloc] init];
      _send_controller = [[InfinitSendViewController alloc] initWithDelegate:self
                                                        withSearchController:_user_search_controller
                                                                     forLink:NO];
      [_delegate sendController:self wantsActiveController:_send_controller];
      [_user_search_controller addUser:user];
    }
    else
    {
      if (_old_user_search_controller == nil)
        _old_user_search_controller = [[OldIAUserSearchViewController alloc] init];
      _old_send_controller =
        [[OldInfinitSendViewController alloc] initWithDelegate:self
                                          withSearchController:_old_user_search_controller
                                                       forLink:NO];
      [_delegate sendController:self wantsActiveController:_old_send_controller];
    }
  }
  else
  {
    if (_new_send_view)
      [_send_controller filesUpdated];
    else
      [_old_send_controller filesUpdated];
  }
}

- (void)showFavourites
{
  ELLE_TRACE("%s: show favourites", self.description.UTF8String);

  if (_favourites_send_controller == nil)
  {
    _favourites_send_controller = [[IAFavouritesSendViewController alloc] initWithDelegate:self];
  }
  else
  {
    [_favourites_send_controller hideFavourites];
  }
  [_favourites_send_controller showFavourites];
}

//- Send View Protocol -----------------------------------------------------------------------------

- (void)sendViewWantsCancel:(id)sender
{
  _files = nil;
  [_delegate sendControllerWantsBack:self];
}

- (void)sendViewWantsClose:(id)sender
{
  _files = nil;
  [_delegate sendControllerWantsClose:self];
}

- (NSArray*)sendViewWantsFileList:(id)sender
{
  return [NSArray arrayWithArray:_files];
}

- (void)sendView:(id)sender
  wantsRemoveFileAtIndex:(NSInteger)index
{
  [_files removeObjectAtIndex:index];
  if ([sender isKindOfClass:OldInfinitSendViewController.class])
    [sender filesUpdated];
}

- (void)sendViewWantsOpenFileDialogBox:(id)sender
{
  [self openFileDialogForView:sender];
}

- (NSArray*)sendView:(id)sender
      wantsSendFiles:(NSArray*)files
             toUsers:(NSArray*)users
         withMessage:(NSString*)message
{
  [_delegate sendControllerWantsClose:self];
  return [_delegate sendController:self
                    wantsSendFiles:files
                           toUsers:users
                       withMessage:message];
}

- (NSNumber*)sendView:(id)sender
      wantsCreateLink:(NSArray*)files
          withMessage:(NSString*)message
{
  [_delegate sendControllerWantsClose:self];
  return [_delegate sendController:self
                   wantsCreateLink:files
                       withMessage:message];
}

- (void)sendView:(id)sender
wantsSetOnboardingSendTransactionId:(NSNumber*)transaction_id
{
  [_delegate sendController:self wantsSetOnboardingSendTransactionId:transaction_id];
}

- (void)sendView:(id)sender
 hadFilesDropped:(NSArray*)files
{
  for (NSString* file in files)
  {
    NSURL* file_url = [NSURL fileURLWithPath:file];
    if (![_files containsObject:[file_url path]])
      [_files addObject:[file_url path]];
  }
  [sender filesUpdated];
}

//- Old Send View Only -----------------------------------------------------------------------------

- (NSArray*)sendViewWantsFriendsByLastInteraction:(id)sender
{
  return [_delegate sendControllerWantsFriendsByLastInteraction:self];
}

- (void)sendView:(id)sender
wantsAddFavourite:(IAUser*)user
{
  [_delegate sendController:self wantsAddFavourite:user];
}

- (void)sendView:(id)sender
wantsRemoveFavourite:(IAUser*)user
{
  [_delegate sendController:self wantsRemoveFavourite:user];
}

//- Favourites Send View Protocol ------------------------------------------------------------------

- (NSArray*)favouritesViewWantsFavourites:(IAFavouritesSendViewController*)sender
{
  return [_delegate sendControllerWantsFavourites:self];
}

- (NSArray*)favouritesViewWantsSwaggers:(IAFavouritesSendViewController*)sender
{
  return [_delegate sendControllerWantsSwaggers:self];
}

- (NSPoint)favouritesViewWantsMidpoint:(IAFavouritesSendViewController*)sender
{
  return [_delegate sendControllerWantsMidpoint:self];
}

- (void)favouritesView:(IAFavouritesSendViewController*)sender
         gotDropOnUser:(IAUser*)user
             withFiles:(NSArray*)files
{
  if (files.count > 0)
  {
    NSArray* res =
      [_delegate sendController:self wantsSendFiles:files toUsers:@[user] withMessage:@""];
    [_delegate sendController:self wantsSetOnboardingSendTransactionId:res[0]];
    [_delegate sendControllerGotDropOnFavourite:self];
  }
}

- (void)favouritesViewWantsClose:(IAFavouritesSendViewController*)sender
{
  [_favourites_send_controller hideFavourites];
}

- (void)favouritesView:(IAFavouritesSendViewController*)sender
  gotDropLinkWithFiles:(NSArray*)files
{
  [_favourites_send_controller hideFavourites];
  if (files.count > 0)
  {
    [_delegate sendController:self wantsCreateLink:files withMessage:@""];
  }
}

//- Onboarding Protocol ----------------------------------------------------------------------------

- (InfinitOnboardingState)onboardingState:(IAViewController*)sender
{
  return [_delegate onboardingState:sender];
}

- (BOOL)onboardingSend:(IAViewController*)sender
{
  return [_delegate onboardingSend:sender];
}

- (void)setOnboardingState:(InfinitOnboardingState)state
{
  [_delegate setOnboardingState:state];
}

- (IATransaction*)receiveOnboardingTransaction:(IAViewController*)sender
{
  return [_delegate receiveOnboardingTransaction:sender];
}

- (IATransaction*)sendOnboardingTransaction:(IAViewController*)sender
{
  return [_delegate sendOnboardingTransaction:sender];
}

@end
