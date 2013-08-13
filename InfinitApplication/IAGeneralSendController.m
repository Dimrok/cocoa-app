//
//  IAGeneralSendController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/2/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAGeneralSendController.h"

@implementation IAGeneralSendController
{
@private
    // Delegate
    id<IAGeneralSendControllerProtocol> _delegate;
    
    // Send views
    IAAdvancedSendViewController* _advanced_send_controller;
    IAFavouritesSendViewController* _favourites_send_controller;
    IASimpleSendViewController* _simple_send_controller;
    
    id _currently_open_controller;
    IAUserSearchViewController* _user_search_controller;
    NSMutableArray* _files;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithDelegate:(id<IAGeneralSendControllerProtocol>)delegate
{
    if (self = [super init])
    {
        _delegate = delegate;
        _files = [NSMutableArray array];
        _user_search_controller = [[IAUserSearchViewController alloc] init];
    }
    return self;
}

//- General Functions ------------------------------------------------------------------------------

- (void)filesOverStatusBarIcon
{
    [self performSelector:@selector(showFavourites)
               withObject:nil
               afterDelay:0.5];
}

- (void)cancelOpenFavourites
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

//- Open Functions ---------------------------------------------------------------------------------

- (void)openWithNoFile
{
    if (_simple_send_controller == nil)
        _simple_send_controller = [[IASimpleSendViewController alloc]
                                        initWithDelegate:self
                                     andSearchController:_user_search_controller];
    [_delegate sendController:self wantsActiveController:_simple_send_controller];
    _currently_open_controller = _simple_send_controller;
}

- (void)openWithFiles:(NSArray*)files
{
    [self cancelOpenFavourites];
    for (NSString* file in files)
    {
        if (![_files containsObject:file])
            [_files addObject:file];
    }
    if (_currently_open_controller == nil)
    {
        _simple_send_controller = [[IASimpleSendViewController alloc]
                                   initWithDelegate:self
                                   andSearchController:_user_search_controller];
        _currently_open_controller = _simple_send_controller;
    }
    else
        [_currently_open_controller filesUpdated];
    [_delegate sendController:self wantsActiveController:_simple_send_controller];
}

- (void)showFavourites
{
    if (_favourites_send_controller == nil)
        _favourites_send_controller = [[IAFavouritesSendViewController alloc] initWithDelegate:self];
    [_favourites_send_controller showFavourites];
}

//- View Switching ---------------------------------------------------------------------------------

- (void)openAdvancedViewWithFocus:(IAAdvancedSendViewFocus)focus
{
    if (_advanced_send_controller == nil)
        _advanced_send_controller = [[IAAdvancedSendViewController alloc]
                                        initWithDelegate:self
                                     andSearchController:_user_search_controller
                                     focusOn:focus];
    [_delegate sendController:self wantsActiveController:_advanced_send_controller];
    _currently_open_controller = _advanced_send_controller;
    _simple_send_controller = nil;
}

//- Simple Send View Protocol ----------------------------------------------------------------------

- (void)simpleSendViewWantsAddFile:(IASimpleSendViewController*)sender
{
    [self openAdvancedViewWithFocus:advanced_view_user_search_focus];
}

- (void)simpleSendViewWantsAddNote:(IASimpleSendViewController*)sender
{
    [self openAdvancedViewWithFocus:advanced_view_note_focus];
}

- (void)simpleSendViewWantsAddRecipient:(IASimpleSendViewController*)sender
{
    [self openAdvancedViewWithFocus:advanced_view_user_search_focus];
}

- (void)simpleSendViewWantsCancel:(IASimpleSendViewController*)sender
{
    _files = nil;
    [_delegate sendControllerWantsClose:self];
}

- (NSArray*)simpleSendViewWantsFileList:(IASimpleSendViewController*)sender
{
    return [NSArray arrayWithArray:_files];
}

//- Advanced Send View Protocol --------------------------------------------------------------------

- (void)advancedSendViewWantsCancel:(IAAdvancedSendViewController*)sender
{
    _files = nil;
    [_delegate sendControllerWantsClose:self];
}

- (NSArray*)advancedSendViewWantsFileList:(IAAdvancedSendViewController*)sender
{
    return [NSArray arrayWithArray:_files];
}

- (void)advancedSendView:(IAAdvancedSendViewController*)sender
  wantsRemoveFileAtIndex:(NSInteger)index
{
    [_files removeObjectAtIndex:index];
    [sender filesUpdated];
}

- (void)advancedSendViewWantsOpenFileDialogBox:(IAAdvancedSendViewController*)sender
{
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

//- Favourites Send View Protocol ------------------------------------------------------------------

- (NSArray*)favouritesViewWantsFavourites:(IAFavouritesSendViewController*)sender
{
    return nil;
}

- (NSPoint)favouritesViewWantsMidpoint:(IAFavouritesSendViewController*)sender
{
    return [_delegate sendControllerWantsMidpoint:self];
}

@end
