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

- (NSSize)intrinsicContentSize
{
    return self.bounds.size;
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
    NSInteger _max_rows_shown;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)init
{
    if (self = [super initWithNibName:self.className bundle:nil])
    {
        _row_height = 42.0;
        _max_rows_shown = 5;
        _delegate = nil;
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(avatarCallback:)
                                                   name:IA_AVATAR_MANAGER_AVATAR_FETCHED
                                                 object:nil];
    }
    
    return self;
}

- (void)setDelegate:(id<IAUserSearchViewProtocol>)delegate
{
    _delegate = delegate;
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
    [self.clear_search setHidden:YES];
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
    }
    else
    {
        _search_results = nil;
    }
    [self updateResultsTable];
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
    [self updateResultsTable];
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
            [self clearResults];
            [self cancelLastSearchOperation];
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
        [self clearResults];
    }
}

//- Table Functions --------------------------------------------------------------------------------

- (void)clearResults
{
    [self.view setFrameSize:self.search_box_view.frame.size];
    [_delegate searchView:self changedSize:self.view.frame.size];
    _search_results = nil;
    [self.table_view reloadData];
}

- (void)updateResultsTable
{
    [self.results_view setHidden:NO];
    NSSize new_size = NSMakeSize(self.view.frame.size.width,
                                 [self tableHeight] + self.search_box_view.frame.size.height);
    [_delegate searchView:self
              changedSize:new_size];
    [self.table_view reloadData];
}

- (CGFloat)tableHeight
{
    CGFloat total_height = _search_results.count * _row_height;
    CGFloat max_height = _row_height * _max_rows_shown;
    if (total_height > max_height)
        return max_height;
    else
        return total_height;
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
    IASearchResultsTableRowView* row_view = [tableView rowViewAtRow:row makeIfNecessary:YES];
    if (row_view == nil)
        row_view = [[IASearchResultsTableRowView alloc] initWithFrame:NSZeroRect];
    return row_view;
}

@end
