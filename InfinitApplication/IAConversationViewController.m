//
//  IAConversationViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/5/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAConversationViewController.h"

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
    [TH_RGBCOLOR(255.0, 255.0, 255.0) set];
    [white_bg fill];
    
    // Grey line
    NSBezierPath* grey_line = [NSBezierPath bezierPathWithRect:NSMakeRect(0.0,
                                                                          1.0,
                                                                          self.frame.size.width,
                                                                          1.0)];
    [TH_RGBCOLOR(223.0, 223.0, 223.0) set];
    [grey_line fill];
    
    // White line
    NSBezierPath* white_line = [NSBezierPath bezierPathWithRect:NSMakeRect(0.0,
                                                                           0.0,
                                                                           self.frame.size.width,
                                                                           1.0)];
    [TH_RGBCOLOR(255.0, 255.0, 255.0) set];
    [white_line fill];
}

@end

//- Conversation View Controller -------------------------------------------------------------------

@implementation IAConversationViewController
{
@private
    id<IAConversationViewProtocol> _delegate;
    
    IAUser* _user;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithDelegate:(id<IAConversationViewProtocol>)delegate
              andUser:(IAUser*)user
{
    if (self = [super initWithNibName:self.className bundle:nil])
    {
        _delegate = delegate;
        _user = user;
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(avatarReceivedCallback:)
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
    return @"[ConversationView]";
}

- (BOOL)closeOnFocusLost
{
    return YES;
}

- (void)awakeFromNib
{
    self.avatar_view.image = [IAFunctions makeRoundAvatar:[IAAvatarManager getAvatarForUser:_user
                                                                            andLoadIfNeeded:YES]
                                               ofDiameter:50.0
                                    withBorderOfThickness:2.0
                                                 inColour:TH_RGBCOLOR(255.0, 255.0, 255.0)
                                        andShadowOfRadius:2.0];
    NSDictionary* fullname_attrs = [IAFunctions
                                    textStyleWithFont:[NSFont boldSystemFontOfSize:12.0]
                                       paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                    colour:TH_RGBCOLOR(29.0, 29.0, 29.0)
                                    shadow:nil];
    NSAttributedString* name_str = [[NSAttributedString alloc] initWithString:_user.fullname
                                                                   attributes:fullname_attrs];
    self.user_fullname.attributedStringValue = name_str;
    NSDictionary* handle_attrs = [IAFunctions
                                  textStyleWithFont:[NSFont systemFontOfSize:11.0]
                                  paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                  colour:TH_RGBCOLOR(193.0, 193.0, 193.0)
                                  shadow:nil];
    NSAttributedString* handle_str = [[NSAttributedString alloc] initWithString:_user.handle
                                                                     attributes:handle_attrs];
    self.user_handle.attributedStringValue = handle_str;
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
                                         inColour:TH_RGBCOLOR(255.0, 255.0, 255.0)
                                andShadowOfRadius:2.0];
}

//- Table Functions --------------------------------------------------------------------------------

- (NSInteger)numberOfRowsInTableView:(NSTableView*)tableView
{
    return 0;
}

- (id)tableView:(NSTableView*)tableView
objectValueForTableColumn:(NSTableColumn*)tableColumn
            row:(NSInteger)row
{
    return nil;
}

@end
