//
//  IAFavouriteView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/13/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAFavouriteView.h"

#import <Gap/InfinitUserManager.h>

@implementation IAFavouriteView
{
@private
  __weak id <IAFavouriteViewProtocol> _delegate;
  InfinitUser* _user;
  NSArray* _drag_types;
  BOOL _hovering;
  NSImage* _avatar;
  NSImage* _current_image;
  NSAttributedString* _name;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithFrame:(NSRect)frameRect
        andDelegate:(id<IAFavouriteViewProtocol>)delegate
            andUser:(InfinitUser*)user
{
  if (self = [super initWithFrame:frameRect])
  {
    _delegate = delegate;
    _user = user;
    _hovering = NO;
    _drag_types = @[NSFilenamesPboardType];
    [self registerForDraggedTypes:_drag_types];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(avatarReceived:)
                                               name:INFINIT_USER_AVATAR_NOTIFICATION
                                             object:nil];
    _avatar = user.avatar;
    _current_image = [IAFunctions makeRoundAvatar:_avatar
                                       ofDiameter:self.avatar_diameter
                            withBorderOfThickness:3.0
                                         inColour:IA_RGBA_COLOUR(255, 255, 255, 0.8)
                                andShadowOfRadius:4.0];

    NSMutableParagraphStyle* para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    para.alignment = NSCenterTextAlignment;
    NSShadow* name_shadow = [IAFunctions shadowWithOffset:NSMakeSize(0.0, -1.0)
                                               blurRadius:2.0
                                                   colour:IA_GREY_COLOUR(0.0)];

    NSMutableDictionary* style = [NSMutableDictionary dictionaryWithDictionary:
                                  [IAFunctions textStyleWithFont:[NSFont boldSystemFontOfSize:13.0]
                                                  paragraphStyle:para
                                                          colour:IA_GREY_COLOUR(255.0)
                                                          shadow:name_shadow]];
    [style setValue:IA_GREY_COLOUR(0.0) forKey:NSStrokeColorAttributeName];
    [style setValue:@-0.25 forKey:NSStrokeWidthAttributeName];
    NSString* name_str = [[_user.fullname componentsSeparatedByString:@" "] objectAtIndex:0];
    if (name_str.length < 3)
      name_str = _user.fullname;
    _name = [[NSAttributedString alloc] initWithString:name_str attributes:style];
    if (_name.size.width > NSWidth(self.bounds))
    {
      [style setValue:[NSFont systemFontOfSize:11.0] forKey:NSFontAttributeName];
      _name = [[NSAttributedString alloc] initWithString:name_str attributes:style];
    }
  }
  return self;
}

- (void)dealloc
{
  [NSNotificationCenter.defaultCenter removeObserver:self];
}

//- Avatar Fetched Callback ------------------------------------------------------------------------

- (void)avatarReceived:(NSNotification*)notification
{
  NSNumber* id_ = notification.userInfo[kInfinitUserId];
  InfinitUser* user = [[InfinitUserManager sharedInstance] userWithId:id_];
  if ([user isEqualTo:_user])
    _avatar = user.avatar;
  [self setNeedsDisplay:YES];
}

//- Drawing ----------------------------------------------------------------------------------------

- (CGFloat)avatar_diameter
{
  return (self.frame.size.width - 15.0);
}

- (BOOL)isOpaque
{
  return NO;
}

- (void)drawRect:(NSRect)dirtyRect
{
  CGFloat avatar_w_diff = NSWidth(self.bounds) - self.avatar_diameter;
  NSRect avatar_rect = NSMakeRect(self.bounds.origin.x + (avatar_w_diff / 2.0),
                                  self.bounds.origin.y + NSHeight(self.bounds) - self.avatar_diameter,
                                  self.avatar_diameter,
                                  self.avatar_diameter);
  [_current_image drawInRect:avatar_rect
                    fromRect:NSZeroRect
                   operation:NSCompositeSourceOver
                    fraction:1.0];

  CGFloat name_w_diff = NSWidth(self.bounds) - _name.size.width;
  [_name drawAtPoint:NSMakePoint(self.bounds.origin.x + (name_w_diff / 2.0), self.bounds.origin.y)];
}

//- Drag Operations --------------------------------------------------------------------------------

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
  NSPasteboard* paste_board = sender.draggingPasteboard;
  if ([paste_board availableTypeFromArray:_drag_types])
  {
    [_delegate favouriteViewGotDragEnter:self];
    _hovering = YES;
    _current_image = [IAFunctions makeRoundAvatar:_avatar
                                       ofDiameter:self.avatar_diameter
                            withBorderOfThickness:3.0
                                         inColour:IA_GREY_COLOUR(255)
                                andShadowOfRadius:4.0];
    [self setNeedsDisplay:YES];
    return NSDragOperationCopy;
  }
  return NSDragOperationNone;
}

- (void)draggingExited:(id<NSDraggingInfo>)sender
{
  [_delegate favouriteViewGotDragExit:self];
  _hovering = NO;
  _current_image = [IAFunctions makeRoundAvatar:_avatar
                                     ofDiameter:self.avatar_diameter
                          withBorderOfThickness:3.0
                                       inColour:IA_RGBA_COLOUR(255, 255, 255, 0.8)
                              andShadowOfRadius:4.0];
  [self setNeedsDisplay:YES];
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
  NSPasteboard* paste_board = sender.draggingPasteboard;
  if (![paste_board availableTypeFromArray:_drag_types])
    return NO;

  NSArray* files = [paste_board propertyListForType:NSFilenamesPboardType];

  if (files.count > 0)
    [_delegate favouriteView:self gotFiles:files];

  return YES;
}

@end
