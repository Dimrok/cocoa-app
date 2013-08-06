//
//  IASearchResultsViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/4/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAUserSearchViewController.h"

#import "IAAvatarManager.h"
#import "IASearchResultsCellView.h"

@interface IAUserSearchViewController ()

@end

@interface IASearchBoxView : NSView
@end

@implementation IASearchBoxView

- (void)drawRect:(NSRect)dirtyRect
{
    NSBezierPath* path = [NSBezierPath bezierPathWithRect:self.bounds];
    [TH_RGBCOLOR(255.0, 255.0, 255.0) set];
    [path fill];
}

@end

@interface IASearchResultsTableRowView : NSTableRowView
@end

@implementation IASearchResultsTableRowView
@end

@implementation IAUserSearchViewController
{
    id<IAUserSearchViewProtocol> _delegate;
    
    NSMutableArray* _search_results;
    
    CGFloat _row_height;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithDelegate:(id<IAUserSearchViewProtocol>)delegate
{
    if (self = [super initWithNibName:self.className bundle:nil])
    {
        _delegate = delegate;
        _row_height = 40.0;
        self.table_view.autoresizingMask = NSViewHeightSizable;
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(avatarCallback:)
                                                   name:IA_AVATAR_MANAGER_AVATAR_FETCHED
                                                 object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (NSString*)description
{
    return @"[SearchResultsViewController]";
}

- (void)awakeFromNib
{
    self.view.autoresizingMask = NSViewHeightSizable | NSViewWidthSizable;
    self.search_field.focusRingType = NSFocusRingTypeNone;
    [self.clear_search setHidden:YES];
    [self.table_view setHidden:YES];
}

//- Avatar Callback --------------------------------------------------------------------------------

- (void)avatarCallback:(NSNotification*)notification
{
    IAUser* user = [notification.userInfo objectForKey:@"user"];
    if (![_search_results containsObject:user])
        return;
    
    [self.table_view reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:[_search_results
                                                                            indexOfObject:user]]
                               columnIndexes:[NSIndexSet indexSetWithIndex:0]];
}

//- Search Functions -------------------------------------------------------------------------------

- (void)cancelLastSearchOperation
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(doSearchNow)
                                               object:nil];
}

- (void)doDelayedSearch
{
    [self performSelector:@selector(doSearchNow)
               withObject:nil
               afterDelay:0.5];
}

- (void)doSearchNow
{
    [self cancelLastSearchOperation];
    NSString* search_string = self.search_field.stringValue;
    if ([IAFunctions stringIsValidEmail:search_string]) // Search using using email address
    {
        IALog(@"searching email address");
        NSMutableDictionary* data = [NSMutableDictionary dictionaryWithObject:search_string
                                                                       forKey:@"entered_email"];
        [[IAGapState instance] getUserIdfromEmail:search_string
                                  performSelector:@selector(searchUserEmailCallback:)
                                         onObject:self withData:data];
    }
    else // Normal search
    {
        [[IAGapState instance] searchUsers:search_string
                           performSelector:@selector(searchResultsCallback:)
                                  onObject:self];
    }
}

- (void)searchUserEmailCallback:(IAGapOperationResult*)result
{
    if (!result.success)
    {
        IALog(@"%@ WARNING: Searching for email address failed", self);
        return;
    }
    
    NSDictionary* data = result.data;
    NSString* user_id = (NSString*)[data objectForKey:@"user_id"];
    if (![user_id isEqualToString:@""])
    {
        IAUser* user = [IAUser userWithId:user_id];
        _search_results = [NSMutableArray arrayWithObject:user];
        IALog(@"%@", _search_results);
    }
    else
    {
        _search_results = nil;
    }
    [self reloadData];
}

- (void)searchResultsCallback:(IAGapOperationResult*)results
{
    if (!results.success)
    {
        IALog(@"%@ WARNING: Searching for users failed with error: %d", self, results.status);
        _search_results = nil;
        return;
    }
    _search_results = [NSMutableArray arrayWithArray:results.data];
    IALog(@"Seach results: %@", _search_results);
    [self reloadData];
}

//- Search Field -----------------------------------------------------------------------------------

- (void)controlTextDidChange:(NSNotification*)aNotification
{
    NSControl* control = aNotification.object;
    if (control == self.search_field)
    {
        if (self.search_field.stringValue.length == 0)
        {
            [self.clear_search setHidden:YES];
            [self.table_view setHidden:YES];
            [self cancelLastSearchOperation];
            _search_results = nil;
        }
        else
        {
            [self.clear_search setHidden:NO];
            [self cancelLastSearchOperation];
            [self doDelayedSearch];
        }
    }
}

- (IBAction)clearSearchField:(NSButton*)sender
{
    if (sender == self.clear_search)
    {
        self.search_field.stringValue = @"";
        [self.clear_search setHidden:YES];
        [self cancelLastSearchOperation];
    }
}

//- Table Functions --------------------------------------------------------------------------------

- (void)reloadData
{
    [self.table_view setHidden:NO];
    [self.table_view reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView*)tableView
{
    return _search_results.count;
}

- (CGFloat)tableView:(NSTableView*)tableView
         heightOfRow:(NSInteger)row
{
    return _row_height;
}

- (NSView*)tableView:(NSTableView*)tableView
  viewForTableColumn:(NSTableColumn*)tableColumn
                 row:(NSInteger)row
{
    IAUser* user = [_search_results objectAtIndex:row];
    if (user == nil || [user.user_id isEqualToString:@""])
        return nil;
    
    IASearchResultsCellView* cell = [tableView makeViewWithIdentifier:@"user_search_cell"
                                                                owner:self];
    [cell setUserFullname:user.fullname];
    [cell setUserFavourite:NO]; // XXX check if user is favourite
    NSImage* avatar = [IAFunctions makeRoundAvatar:[IAAvatarManager getAvatarForUser:user
                                                                     andLoadIfNeeded:YES]
                                          ofRadius:25
                                   withWhiteBorder:NO];
    [cell setUserAvatar:avatar];
    return cell;
}

- (NSTableRowView*)tableView:(NSTableView*)tableView
               rowViewForRow:(NSInteger)row
{
    if (_search_results == nil)
        return nil;
    IASearchResultsTableRowView* row_view = [tableView rowViewAtRow:row makeIfNecessary:YES];
    if (row_view == nil)
        row_view = [[IASearchResultsTableRowView alloc] initWithFrame:NSZeroRect];
    return row_view;
}

@end
