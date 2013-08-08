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
    [_files addObjectsFromArray:files];
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

//- View Switching ---------------------------------------------------------------------------------

- (void)openAdvancedViewForNote
{
    if (_advanced_send_controller == nil)
        _advanced_send_controller = [[IAAdvancedSendViewController alloc]
                                        initWithDelegate:self
                                     andSearchController:_user_search_controller];
    [_delegate sendController:self wantsActiveController:_advanced_send_controller];
    _currently_open_controller = _advanced_send_controller;
    _simple_send_controller = nil;
}

//- Simple Send View Protocol ----------------------------------------------------------------------

- (void)simpleSendViewWantsAddFile:(IASimpleSendViewController*)sender
{
    
}

- (void)simpleSendViewWantsAddNote:(IASimpleSendViewController*)sender
{
    [self openAdvancedViewForNote];
}

- (void)simpleSendViewWantsAddRecipient:(IASimpleSendViewController*)sender
{
    
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

@end
