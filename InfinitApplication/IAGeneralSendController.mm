//
//  IAGeneralSendController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/2/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAGeneralSendController.h"

#import "InfinitSendViewController.h"

#import <Gap/InfinitLinkTransactionManager.h>
#import <Gap/InfinitPeerTransactionManager.h>
#import <Gap/InfinitUserManager.h>

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

  // Search Controller
  IAUserSearchViewController* _user_search_controller;

  NSMutableArray* _files;
  BOOL _send_view_open;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithDelegate:(id<IAGeneralSendControllerProtocol>)delegate
{
  if (self = [super init])
  {
    _delegate = delegate;
    _files = [NSMutableArray array];
    _send_view_open = NO;
  }
  return self;
}

- (void)dealloc
{
  [_user_search_controller setDelegate:nil];
  _user_search_controller = nil;
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
    [self performSelector:@selector(showFavourites) withObject:nil afterDelay:0.4f];
  }
}

- (void)cancelOpenFavourites
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)openFileDialogForView:(id)sender
{
  if (sender != _send_controller)
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
  _user_search_controller = [[IAUserSearchViewController alloc] init];
  _send_controller =
    [[InfinitSendViewController alloc] initWithDelegate:self
                                   withSearchController:_user_search_controller
                                                forLink:for_link];
  [_delegate sendController:self wantsActiveController:_send_controller];
}

- (void)openWithFiles:(NSArray*)files
              forUser:(InfinitUser*)user
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
    [_send_controller filesUpdated];
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
  return [[InfinitPeerTransactionManager sharedInstance] sendFiles:files
                                                      toRecipients:users
                                                       withMessage:message];
}

- (NSNumber*)sendView:(id)sender
      wantsCreateLink:(NSArray*)files
          withMessage:(NSString*)message
{
  [_delegate sendControllerWantsClose:self];
  return [[InfinitLinkTransactionManager sharedInstance] createLinkWithFiles:files 
                                                                 withMessage:message];
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

//- Favourites Send View Protocol ------------------------------------------------------------------

- (NSPoint)favouritesViewWantsMidpoint:(IAFavouritesSendViewController*)sender
{
  return [_delegate sendControllerWantsMidpoint:self];
}

- (void)favouritesView:(IAFavouritesSendViewController*)sender
         gotDropOnUser:(InfinitUser*)user
             withFiles:(NSArray*)files
{
  if (files.count > 0)
  {
    [[InfinitPeerTransactionManager sharedInstance] sendFiles:files
                                                 toRecipients:@[user]
                                                  withMessage:@""];
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
    [[InfinitLinkTransactionManager sharedInstance] createLinkWithFiles:files withMessage:@""];
  }
}

@end
