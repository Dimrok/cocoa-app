//
//  IAConversationViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/5/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAConversationViewController.h"

#import "IAConversationCellView.h"

#import "IAAvatarManager.h"

@interface IAConversationViewController ()

@end

//- Conversation Header View -----------------------------------------------------------------------

@interface IAConversationHeaderView : NSView
@end

@implementation IAConversationHeaderView

- (void)drawRect:(NSRect)dirtyRect
{
    // White background
    NSBezierPath* white_bg = [NSBezierPath bezierPathWithRect:
                                                        NSMakeRect(0.0,
                                                                   2.0,
                                                                   self.frame.size.width,
                                                                   self.frame.size.height - 2.0)];
    [IA_GREY_COLOUR(255.0) set];
    [white_bg fill];
    
    // Grey line
    NSBezierPath* grey_line = [NSBezierPath bezierPathWithRect:NSMakeRect(0.0,
                                                                          1.0,
                                                                          self.frame.size.width,
                                                                          1.0)];
    [IA_GREY_COLOUR(223.0) set];
    [grey_line fill];
    
    // White line
    NSBezierPath* white_line = [NSBezierPath bezierPathWithRect:NSMakeRect(0.0,
                                                                           0.0,
                                                                           self.frame.size.width,
                                                                           1.0)];
    [IA_GREY_COLOUR(255.0) set];
    [white_line fill];
}

@end

//- Conversation Row View --------------------------------------------------------------------------

@interface IAConversationRowView : NSTableRowView
@end

@implementation IAConversationRowView

@end

//- Conversation View Controller -------------------------------------------------------------------

@implementation IAConversationViewController
{
@private
    id<IAConversationViewProtocol> _delegate;
    
    IAUser* _user;
    NSArray* _transaction_list;
    CGFloat _max_table_height;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithDelegate:(id<IAConversationViewProtocol>)delegate
              andUser:(IAUser*)user
{
    if (self = [super initWithNibName:self.className bundle:nil])
    {
        _delegate = delegate;
        _user = user;
        _max_table_height = 290.0;
        _transaction_list = [_delegate conversationView:self
                       wantsReversedTransactionsForUser:_user];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(avatarReceivedCallback:)
                                                   name:IA_AVATAR_MANAGER_AVATAR_FETCHED
                                                 object:nil];
        IALog(@"%@ %@", self, _transaction_list);
    }
    return self;
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (BOOL)closeOnFocusLost
{
    return YES;
}

- (void)setupPersonView
{
    self.avatar_view.image = [IAFunctions makeRoundAvatar:[IAAvatarManager getAvatarForUser:_user
                                                                            andLoadIfNeeded:YES]
                                               ofDiameter:50.0
                                    withBorderOfThickness:3.0
                                                 inColour:IA_GREY_COLOUR(255.0)
                                        andShadowOfRadius:1.0];
    NSDictionary* name_attrs = [IAFunctions textStyleWithFont:[NSFont boldSystemFontOfSize:12.0]
                                               paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                                       colour:IA_GREY_COLOUR(29.0)
                                                       shadow:nil];
    NSAttributedString* name_str = [[NSAttributedString alloc] initWithString:_user.fullname
                                                                   attributes:name_attrs];
    self.user_fullname.attributedStringValue = name_str;
    NSDictionary* handle_attrs = [IAFunctions
                                  textStyleWithFont:[NSFont systemFontOfSize:11.0]
                                  paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                  colour:IA_GREY_COLOUR(193.0)
                                  shadow:nil];
    NSAttributedString* handle_str = [[NSAttributedString alloc] initWithString:_user.handle
                                                                     attributes:handle_attrs];
    self.user_handle.attributedStringValue = handle_str;
}

- (void)awakeFromNib
{
    [self setupPersonView];
}

- (void)loadView
{
    [super loadView];
    CGFloat y_diff = (self.person_view.frame.size.height + [self tableHeight]) -
    self.main_view.frame.size.height;
    [self.content_height_constraint.animator setConstant:(y_diff +
                                                          self.content_height_constraint.constant)];
    _transaction_list = nil; // XXX work around for crash on calling layout
    [self.view layoutSubtreeIfNeeded];
    [self userTransactionsUpdated];
}

//- Avatar Callback --------------------------------------------------------------------------------

- (void)avatarReceivedCallback:(NSNotification*)notification
{
    IAUser* user = [notification.userInfo objectForKey:@"user"];
    if (user == _user)
        self.avatar_view.image = [IAFunctions
                                  makeRoundAvatar:[IAAvatarManager getAvatarForUser:_user
                                                                    andLoadIfNeeded:YES]
                                       ofDiameter:50.0
                            withBorderOfThickness:2.0
                                         inColour:IA_GREY_COLOUR(255.0)
                                andShadowOfRadius:2.0];
}

//- General Functions ------------------------------------------------------------------------------

- (void)userTransactionsUpdated
{
    _transaction_list = [_delegate conversationView:self
                   wantsReversedTransactionsForUser:_user];
    [self updateTable];
}

//- Table Functions --------------------------------------------------------------------------------

- (void)updateTable
{
    [self.table_view reloadData];
    CGFloat y_diff = [self tableHeight] - self.content_height_constraint.constant;
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
     {
         context.duration = 0.25;
         [self.content_height_constraint.animator setConstant:(y_diff +
                                                        self.content_height_constraint.constant)];
     }
                        completionHandler:^
     {
         [self.view layoutSubtreeIfNeeded];
     }];
}

- (CGFloat)tableHeight
{
    CGFloat total_height = 0.0;
    for (NSInteger i = 0; i < _transaction_list.count; i++)
    {
        total_height += [self tableView:self.table_view heightOfRow:i];
    }
    if (total_height > _max_table_height)
        return _max_table_height;
    else
        return total_height;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView*)tableView
{
    return _transaction_list.count;
}

- (CGFloat)tableView:(NSTableView*)tableView
         heightOfRow:(NSInteger)row
{
    return 100.0;
//    NSTableRowView* row_view = [self.table_view rowViewAtRow:row makeIfNecessary:NO];
//    return row_view.bounds.size.height;
}

- (NSView*)tableView:(NSTableView*)tableView
  viewForTableColumn:(NSTableColumn*)tableColumn
                 row:(NSInteger)row
{
    IALog(@"viewfortablecolumn row");
    IATransaction* transaction = [_transaction_list objectAtIndex:row];
    IAConversationCellView* cell;
    if (transaction.from_me)
    {
        // XXX make left cell
        cell = [self.table_view makeViewWithIdentifier:@"conversation_cell_view_right"
                                                 owner:self];
    }
    else
    {
        cell = [self.table_view makeViewWithIdentifier:@"conversation_cell_view_right"
                                                 owner:self];
    }
    [cell setupCellWithTransaction:transaction];
    return cell;
}

- (NSTableRowView*)tableView:(NSTableView*)tableView
               rowViewForRow:(NSInteger)row
{
    IALog(@"rowviewforrow");
    IAConversationRowView* row_view = [self.table_view rowViewAtRow:row makeIfNecessary:YES];
    if (row_view == nil)
        row_view = [[IAConversationRowView alloc] initWithFrame:NSZeroRect];
    return row_view;
}

//- Button Handling --------------------------------------------------------------------------------

- (IBAction)backButtonClicked:(NSButton*)sender
{
    [_delegate conversationViewWantsBack:self];
}

- (IBAction)transferButtonClicked:(NSButton*)sender
{
    [_delegate conversationView:self wantsTransferForUser:_user];
}

@end
